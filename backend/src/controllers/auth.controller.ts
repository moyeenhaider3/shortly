import { Request, Response, NextFunction, CookieOptions } from 'express';
import { env } from '../config/env';
import { AuthService } from '../service/auth.service';

// Options for the HTTP-only cookie
const cookieOptions: CookieOptions = {
  httpOnly: true, // Prevents client-side JavaScript from reading the cookie
  secure: env.nodeEnv === 'production', // Only sent over HTTPS in production
  sameSite: 'lax', // CSRF mitigation
  maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days in milliseconds
};

export class AuthController {
  /**
   * Handle user signup
   * POST /api/auth/signup
   */
  public static async signup(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await AuthService.signup(req.body);

      // Set JWT in HTTP-only cookie
      res.cookie('token', result.token, cookieOptions);

      res.status(201).json({
        success: true,
        message: 'User registered successfully',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Handle user login
   * POST /api/auth/login
   */
  public static async login(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await AuthService.login(req.body);

      // Set JWT in HTTP-only cookie
      res.cookie('token', result.token, cookieOptions);

      res.status(200).json({
        success: true,
        message: 'Logged in successfully',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Handle user logout
   * POST /api/auth/logout
   */
  public static async logout(req: Request, res: Response): Promise<void> {
    // Clear the cookie by setting an expired token
    res.clearCookie('token', cookieOptions);

    res.status(200).json({
      success: true,
      message: 'Logged out successfully',
    });
  }

  /**
   * Get current authenticated user
   * GET /api/auth/me
   */
  public static async getMe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      // req.user was populated by authenticate middleware
      const user = await AuthService.getUserById(req.user!._id.toString());

      res.status(200).json({
        success: true,
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }
}