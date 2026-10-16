import { Controller, Get } from '@nestjs/common';

/**
 * Liveness endpoint. Mirrors Express's `app.get('/health', ...)` in backend/src/app.ts.
 */
@Controller('health')
export class HealthController {
  @Get()
  check() {
    return {
      success: true,
      message: 'Server is healthy and running',
      timestamp: new Date().toISOString(),
    };
  }
}
