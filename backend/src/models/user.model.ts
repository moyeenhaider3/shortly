import { Schema, model, Document, Types } from 'mongoose';


export enum UserRole {
  ADMIN = 'ADMIN',
  NORMAL = 'NORMAL'
}

/**
 * 1. TypeScript Interface:
 * Represents the shape of a User document in TypeScript code.
 */
export interface IUser {
  _id: Types.ObjectId;
  name: string;
  email: string;
  passwordHash: string;
  createdAt: Date;
  updatedAt: Date;
  role: UserRole
}

/**
 * 2. Document Interface:
 * Combines our IUser interface with Mongoose's Document methods (like .save()).
 */
export interface IUserDocument extends IUser, Document {
  _id: Types.ObjectId;
}

/**
 * 3. Mongoose Schema:
 * Defines the database rules, constraints, and runtime validation.
 */
const userSchema = new Schema<IUserDocument>(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
      minlength: [2, 'Name must be at least 2 characters'],
      maxlength: [50, 'Name cannot exceed 50 characters'],
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true, // Creates a unique index in MongoDB
      lowercase: true, // Automatically converts email to lowercase before saving
      trim: true,
      match: [
        /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/,
        'Please provide a valid email address',
      ],
    },
    passwordHash: {
      type: String,
      required: [true, 'Password hash is required'],
    },
    role: {
      id: Types.ObjectId,
      type: String,
      enum: Object.values(UserRole),
      default: UserRole.NORMAL
    }
  },
  {
    timestamps: true, // Automatically adds createdAt and updatedAt fields
    versionKey: false, // Disables the internal '__v' field created by Mongoose
  }
);

/**
 * 4. Model Creation:
 * Mongoose compiles this schema into a Model named 'User',
 * which maps to the 'users' collection in MongoDB.
 */
export const User = model<IUserDocument>('User', userSchema);