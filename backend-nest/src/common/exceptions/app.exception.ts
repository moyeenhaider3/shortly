import { HttpException } from '@nestjs/common';

/**
 * Expected ("operational") error with a client-safe message and a machine-readable code.
 * inherits getStatus() and message
 * Counterpart of `AppError` in backend/src/middlewares/error.middleware.ts.
 */
export class AppException extends HttpException {
  constructor(
    message: string,
    status: number,
    // Separate from `message`: clients branch on `code`; the Flutter app displays `message`.
    public readonly code: string = 'INTERNAL_ERROR',
  ) {
    super(message, status);
  }
}
