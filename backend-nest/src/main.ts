// backend-nest/src/main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ConfigService } from '@nestjs/config';


/**
 * Application entry point.
 * Port 5001 keeps this app beside the Express backend (5000).
 * TODO(01-03): read the port from validated ConfigService instead.
 */
async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const config=app.get(ConfigService)
  await app.listen(config.get<number>('PORT', 5001));
}
void bootstrap();
