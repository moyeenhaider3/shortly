import { Request, Response, NextFunction } from 'express';
import { UserService } from '../service/user.service';

export class UserController {
  /**
   * GET /api/users
   * Admin only: list every user (password hashes excluded)
   */
  public static async listUsers(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const users = await UserService.listUsers();

      res.status(200).json({
        success: true,
        data: users,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/users
   * Admin only: create a NORMAL or ADMIN user.
   * Unlike signup, no session cookie is set, so the admin stays logged in as themselves.
   */
  public static async createUser(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { name, email, password, role } = req.body ?? {};
      const user = await UserService.createUser({ name, email, password, role });

      res.status(201).json({
        success: true,
        message: 'User created successfully',
        data: UserService.toPublic(user),
      });
    } catch (error) {
      next(error);
    }
  }
}
