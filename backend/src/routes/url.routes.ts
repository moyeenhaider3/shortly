import { Router } from 'express';
import { UrlController } from '../controllers/url.controller';
import { authenticate } from '../middlewares/auth.middleware';

const urlRouter: Router = Router();


// 1. Public Route: Anyone can check if an alias is free
urlRouter.get('/check/:alias', UrlController.checkAlias);

// All URL endpoints require authentication
urlRouter.use(authenticate);

urlRouter.post('/', UrlController.createUrl);
urlRouter.get('/', UrlController.getUserUrls);
urlRouter.get('/:id', UrlController.getUrlById);
urlRouter.get('/:id/analytics', UrlController.getUrlAnalytics); 
urlRouter.patch('/:id', UrlController.updateUrl);
urlRouter.delete('/:id', UrlController.deleteUrl);

export default urlRouter;