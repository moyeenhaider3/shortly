import { Injectable, Logger, NestMiddleware } from '@nestjs/common';
import type { NextFunction, Request, Response } from 'express';

/** Counterpart of `requestLogger` in backend/src/middlewares/logger.middleware.ts. */
@Injectable()
export class LoggerMiddleware implements NestMiddleware {
  private readonly logger = new Logger('HTTP');

  use(req: Request, _res: Response, next: NextFunction): void {
    this.logger.log(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl}`);
    next(); // without this the request hangs: nothing after the middleware runs
  }
}
