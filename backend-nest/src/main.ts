// backend-nest/src/main.ts
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { ConfigService } from '@nestjs/config';
import { json, urlencoded } from 'express';
import type { NextFunction, Request, Response } from 'express';
import { AppModule } from './app.module';
import { AppException } from './common/exceptions/app.exception';
import { ValidationPipe } from '@nestjs/common';
import { validationExceptionFactory } from './common/pipes/validation-exception.factory';

/**
 * Application entry point.
 * Port 5001 keeps this app beside the Express backend (5000).
 */
async function bootstrap() {
  // bodyParser: false turns off Nest's built-in parser, which hides the parser's error details
  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    bodyParser: false,
  });
  const config = app.get(ConfigService);

  // Behind a PaaS proxy: trust the first hop so req.protocol reflects what the browser used.
  app.set('trust proxy', 1);

  // Same options as backend/src/app.ts: any origin, Bearer header auth (see Express comment).
  app.enableCors({
    origin: '*',
    credentials: true,
    methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  });

  // Same parsers as backend/src/app.ts
  app.use(json());
  app.use(urlencoded({ extended: true }));

  // Express error middleware (4 args). Runs only for errors from the parsers above.
  // Same client-safe rule as Express's errorHandler: expose === true and a string `type`.
  app.use(
    (
      err: { type?: unknown; expose?: unknown; status?: number; message: string },
      _req: Request,
      _res: Response,
      next: NextFunction,
    ) => {
      if (typeof err.type === 'string' && err.expose === true) {
        return next(new AppException(err.message, err.status ?? 400, err.type));
      }
      next(err);
    },
  );
  
  // Validate every typed @Body()/@Param()/@Query() against its DTO class.
  app.useGlobalPipes(
    new ValidationPipe({
      transform: true, // build real DTO instances so @Transform runs
      whitelist: true, // strip properties the DTO doesn't declare (e.g. isAdmin)
      exceptionFactory: validationExceptionFactory, // Express-shaped errors instead of Nest's
    }),
  );
app.enableShutdownHooks(); // listen for SIGINT/SIGTERM so onModuleDestroy runs
  await app.listen(config.get<number>('PORT', 5001));
}
void bootstrap();
