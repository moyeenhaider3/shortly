import { Router } from 'express';
import { UserController } from '../controllers/user.controller';
import { authenticate } from '../middlewares/auth.middleware';
import { restrictTo } from '../middlewares/role.middleware';
import { UserRole } from '../models/user.model';

const userRouter: Router = Router();

// User management is admin-only
userRouter.use(authenticate, restrictTo(UserRole.ADMIN));

userRouter.get('/', UserController.listUsers);
userRouter.post('/', UserController.createUser);

export default userRouter;
