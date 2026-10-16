import { ConfigModule } from '@nestjs/config';
import { envValidationSchema } from './config/env.validation';
import { Module } from '@nestjs/common';

import { HealthModule } from './health/health.module';
import { HealthController } from './health/health.controller';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true, // ConfigService injectable everywhere, no re-importing per module
      validationSchema: envValidationSchema,
      validationOptions: {libraryOptions:{ abortEarly: true }}, // stop at the first error
    }),
    HealthModule,
  ],
})
export class AppModule {}
