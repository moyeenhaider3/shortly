import { ConfigModule } from '@nestjs/config';
import { envValidationSchema } from './config/env.validation';
import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { PrismaModule } from './prisma/prisma.module';

import { HealthModule } from './health/health.module';
import { DemoModule } from './demo/demo.module';

import { APP_FILTER } from '@nestjs/core';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';
import { LoggerMiddleware } from './common/middleware/logger.middleware';


@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true, // ConfigService injectable everywhere, no re-importing per module
      validationSchema: envValidationSchema,
      validationOptions: {libraryOptions:{ abortEarly: true }}, // stop at the first error
    }),
    HealthModule,
    DemoModule,
    PrismaModule
  ],
  providers: [{ provide: APP_FILTER, useClass: AllExceptionsFilter }],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(LoggerMiddleware).forRoutes('*path'); // all paths, including unknown ones
  }
}