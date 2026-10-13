import { Router } from 'express';
import { RedirectController } from '../controllers/redirect.controller';

const redirectRouter: Router = Router();

// Public route: handles GET /:shortCode
redirectRouter.get('/:shortCode', RedirectController.handleRedirect);

export default redirectRouter;