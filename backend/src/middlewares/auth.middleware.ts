import { Request, Response, NextFunction } from 'express';
import { verifyToken } from '../utils/jwt';
import { User } from '../models/user.model';
import { AppError } from './error.middleware';

/**
 * Middleware that protects routes requiring an authenticated user.
 */
export const authenticate = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    let token: string | undefined;

    // 1. Check HTTP-only cookie
    if (req.cookies && req.cookies.token) {
      token = req.cookies.token;
    }
    // 2. Fallback: Check 'Authorization: Bearer <token>' header
    else if (req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      throw new AppError('You are not logged in. Please log in to gain access.', 401, 'UNAUTHORIZED');
    }

    // 3. Verify JWT
    let payload;
    try {
      payload = verifyToken(token);
    } catch (jwtError) {
      throw new AppError('Invalid or expired authentication token', 401, 'INVALID_TOKEN');
    }

    // 4. Ensure user still exists in the database
    const currentUser = await User.findById(payload.userId);
    if (!currentUser) {
      throw new AppError('The user belonging to this token no longer exists', 401, 'USER_DELETED');
    }

    // 5. Attach the user object to the request for subsequent handlers
    req.user = currentUser;

    next();
  } catch (error) {
    next(error); // Forward the error to our global errorHandler
  }
};