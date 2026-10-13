import bcrypt from 'bcryptjs';
import { User, IUserDocument, UserRole } from '../models/user.model';
import { AppError } from '../middlewares/error.middleware';

export interface ICreateUserInput {
  name: string;
  email: string;
  password: string;
  role: UserRole;
}

export interface IPublicUser {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  createdAt: Date;
}

// Mirrors the schema's email rule so bad input is a 400, not a Mongoose 500.
const EMAIL_REGEX = /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/;

export class UserService {
  /**
   * Validates input, hashes the password and stores a new user.
   * Shared by public signup (always NORMAL) and admin user creation.
   */
  public static async createUser(input: ICreateUserInput): Promise<IUserDocument> {
    const name = typeof input.name === 'string' ? input.name.trim() : '';
    const email = typeof input.email === 'string' ? input.email.trim().toLowerCase() : '';
    const { password, role } = input;

    // 1. Validation
    if (!name || !email || !password) {
      throw new AppError('Name, email, and password are required', 400, 'VALIDATION_ERROR');
    }

    if (name.length < 2 || name.length > 50) {
      throw new AppError('Name must be between 2 and 50 characters', 400, 'VALIDATION_ERROR');
    }

    if (!EMAIL_REGEX.test(email)) {
      throw new AppError('Please provide a valid email address', 400, 'VALIDATION_ERROR');
    }

    if (typeof password !== 'string' || password.length < 6) {
      throw new AppError('Password must be at least 6 characters long', 400, 'WEAK_PASSWORD');
    }

    if (!Object.values(UserRole).includes(role)) {
      throw new AppError(`Role must be one of: ${Object.values(UserRole).join(', ')}`, 400, 'INVALID_ROLE');
    }

    // 2. Check if email already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      throw new AppError('Email is already registered', 409, 'EMAIL_ALREADY_EXISTS');
    }

    // 3. Hash the plain-text password (salt rounds = 10)
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // 4. Save the user; a concurrent insert of the same email hits the unique index
    try {
      return await User.create({ name, email, passwordHash, role });
    } catch (error: any) {
      if (error?.code === 11000) {
        throw new AppError('Email is already registered', 409, 'EMAIL_ALREADY_EXISTS');
      }
      throw error;
    }
  }

  /**
   * All users, newest first, without password hashes.
   */
  public static async listUsers(): Promise<IPublicUser[]> {
    const users = await User.find().select('-passwordHash').sort({ createdAt: -1 });
    return users.map((user) => UserService.toPublic(user));
  }

  public static toPublic(user: IUserDocument): IPublicUser {
    return {
      id: user._id.toString(),
      name: user.name,
      email: user.email,
      role: user.role,
      createdAt: user.createdAt,
    };
  }
}
