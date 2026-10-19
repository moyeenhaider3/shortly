import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  Logger,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { AppException } from '../exceptions/app.exception';

/**
 * Single place where every error becomes a response.
 * Counterpart of `errorHandler` in backend/src/middlewares/error.middleware.ts.
 */
@Catch() // no argument = catch everything, not only HttpException. @Catch(HttpException) would catch only that type
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {

    // Reach the underlying Express req/res (Nest can also run on other transports)
    const ctx = host.switchToHttp();
    const request = ctx.getRequest<Request>();
    const response = ctx.getResponse<Response>();

    let status = 500;
    let code = 'INTERNAL_SERVER_ERROR';
    let message = 'Something went wrong on the server';

   // body-parser errors (malformed JSON, too large) carry a string `type` and expose === true.
// Same client-safe rule as Express's errorHandler. Detected by properties, never by message text.
const bp = exception as { type?: unknown; expose?: unknown; status?: number; statusCode?: number; message?: string };
const isBodyParserError = typeof bp?.type === 'string' && bp.expose === true;

if (exception instanceof AppException) {
  status = exception.getStatus();
  code = exception.code;
  message = exception.message;
} else if (isBodyParserError) {
  status = bp.status ?? bp.statusCode ?? 400;
  code = bp.type as string;
  message = bp.message ?? message;
} else if (exception instanceof HttpException && exception.getStatus() === 404) {
  // Unmatched route: Nest raises NotFoundException; Express's notFoundHandler message
  status = 404;
  code = 'NOT_FOUND';
  message = `Cannot find ${request.method} ${request.originalUrl} on this server`;
} else if (exception instanceof HttpException && exception.getStatus() < 500) {
  // other 4xx HttpExceptions (02-03 handles validation)
  status = exception.getStatus();
  code = 'BAD_REQUEST';
  const res = exception.getResponse();
  message =
    typeof res === 'string'
      ? res
      : ((res as { message?: string | string[] }).message?.toString() ?? exception.message);
}


    if (status >= 500) {
      // 3. Unexpected: log the stack server-side only; the body stays generic
      this.logger.error(
        `${request.method} ${request.originalUrl}`,
        exception instanceof Error ? exception.stack : String(exception),
      );
    }

    response.status(status).json({ success: false, message, code });
  }
}
