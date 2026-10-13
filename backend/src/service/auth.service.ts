import bcrypt from 'bcryptjs';
import { User, UserRole } from '../models/user.model';
import { AppError } from '../middlewares/error.middleware';
import { signToken } from '../utils/jwt';
import { UserService } from './user.service';

export interface ISignupInput {
  name: string;
  email: string;
  password: string;
  role?: UserRole;
}

export interface ILoginInput {
  email: string;
  password: string;
}

export interface IAuthResponse {
  user: {
    id: string;
    name: string;
    email: string;
    role: UserRole; // <--- Included in response
  };
  token: string;
}

export class AuthService {
  /**
   * Register a new user
   */
  public static async signup(input: ISignupInput): Promise<IAuthResponse> {
    const { name, email, password } = input;

    // Public signup always creates a NORMAL user; any `role` in the body is ignored.
    // Admins create other admins through POST /api/users.
    const newUser = await UserService.createUser({ name, email, password, role: UserRole.NORMAL });

    // Generate JWT token
    const token = signToken({ userId: newUser._id.toString() });

    return {
      user: {
        id: newUser._id.toString(),
        name: newUser.name,
        email: newUser.email,
        role: newUser.role
      },
      token,
    };
  }

  /**
   * Log in an existing user
   */
  public static async login(input: ILoginInput): Promise<IAuthResponse> {
    const { email, password } = input;

    if (!email || !password) {
      throw new AppError('Email and password are required', 400, 'VALIDATION_ERROR');
    }

    // 1. Find user by email
    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      // Avoid revealing whether the email or password was wrong for security
      throw new AppError('Invalid email or password', 401, 'INVALID_CREDENTIALS');
    }

    // 2. Compare incoming password with stored hash
    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      throw new AppError('Invalid email or password', 401, 'INVALID_CREDENTIALS');
    }

    // 3. Generate JWT token
    const token = signToken({ userId: user._id.toString() });

    return {
      user: {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        role: user.role,
      },
      token,
    };
  }

  /**
   * Get user profile by ID
   */
  public static async getUserById(userId: string) {
    const user = await User.findById(userId).select('-passwordHash');
    if (!user) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }
    return user;
  }
}