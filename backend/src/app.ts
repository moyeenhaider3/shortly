import express, { Application, Request, Response } from 'express';
import cors from 'cors'; // <--- 1. Import cors
import cookieParser from 'cookie-parser';
import { requestLogger } from './middlewares/logger.middleware';
import { notFoundHandler, errorHandler } from './middlewares/error.middleware';
import authRouter from './routes/auth.routes';
import urlRouter from './routes/url.routes';
import redirectRouter from './routes/redirect.routes';
import userRouter from './routes/user.routes';

const app: Application = express();

// Render (and most PaaS) terminate HTTPS at a proxy and forward to us over
// HTTP. Trusting the first hop lets req.protocol reflect what the browser
// actually used, so generated short links come back as https:// in production.
app.set('trust proxy', 1);

// 2. Configure CORS Middleware (Must be before any routes!)
app.use(
  cors({
    // Any origin: any localhost port in development, GitHub Pages in production.
    // Note: the spec forbids pairing "*" with credentialed requests, so browsers
    // drop the auth cookie. The Flutter client uses the Bearer header instead.
    // Swap in an explicit origin list if the cookie ever needs to work in-browser.
    origin: "*",
    credentials: true, // Allows Flutter to send cookies and authorization headers
    methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

// 3. Core Parsers
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

// 4. Request Logging Middleware
app.use(requestLogger);

// 5. Base Health Check Route
app.get('/health', (req: Request, res: Response): void => {
  res.status(200).json({
    success: true,
    message: 'Server is healthy and running',
    timestamp: new Date().toISOString(),
  });
});

// 6. API Routes
app.use('/api/auth', authRouter);
app.use('/api/urls', urlRouter);
app.use('/api/users', userRouter);

// 7. Public Redirect Route (Must be mounted AFTER /api routes)
app.use('/', redirectRouter);

// 8. Catch-all for undefined routes (404)
app.use(notFoundHandler);

// 9. Global Error Handler
app.use(errorHandler);

export default app;