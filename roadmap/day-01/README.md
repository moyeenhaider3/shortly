# 📘 Day 1: Node.js Fundamentals & NestJS Architecture

> **Focus**: Understanding the Node.js runtime mechanics (Event Loop & libuv), setting up robust TypeScript environments, and mastering the foundation of NestJS: Modules, Providers, Dependency Injection, and Validated Configuration.

---

## 🎯 Topics & Learning Outcomes

### Topics / Coverage
- **Node.js Internals**: Event loop phases, libuv thread pool, microtasks (`process.nextTick`, resolved Promises) vs. macrotasks (`setTimeout`, `setImmediate`, I/O).
- **Event Loop Blocking**: Synchronous CPU work, heavy JSON parsing, regex catastrophe, and why blocking degrades throughput under concurrency.
- **NestJS Building Blocks**: Modules (`@Module`), Providers (`@Injectable`), Dependency Injection (DI), and Inversion of Control (IoC).
- **Provider Scopes**: `DEFAULT` (Singleton), `REQUEST` (Per-request instance), and `TRANSIENT` (New instance per consumer), and their performance implications.
- **Modular Design**: Feature modules (`AuthModule`, `UrlModule`), Shared modules, and Core/Global modules.
- **Validated Configuration**: `@nestjs/config`, Joi / Zod validation schemas, and failing fast on invalid environment variables.
- **TypeScript & Tooling**: Strict mode (`tsconfig.json`), ESLint, Prettier, and sensible abstraction boundaries (DRY vs. duplication).

### Learning Outcomes
- ✅ Explain what blocks the event loop and why it matters under load.
- ✅ Split an enterprise application into feature modules with clear encapsulation and boundaries.
- ✅ Configure fail-fast environment validation preventing the server from booting with corrupt configurations.

---

## 🔍 What We Have Covered So Far

In our current Shortly project codebase ([`backend/`](../../backend/)):

1. **Strict TypeScript Baseline**:
   - Configured [`backend/tsconfig.json`](../../backend/tsconfig.json) with strict mode: `"strict": true`, `"noImplicitAny": true`, and target modern ES features (`"target": "ES2022"`).
2. **Crash Guards for Process Stability**:
   - In [`backend/src/server.ts`](../../backend/src/server.ts), we implemented lifecycle event handlers to guard against runtime process failure:
     - `process.on('unhandledRejection')`: Catches unhandled asynchronous Promise errors, logs them, and triggers a graceful shutdown.
     - `process.on('uncaughtException')`: Catches synchronous unhandled exceptions and exits immediately to avoid running in an indeterminate state.
3. **Layered Separation of Concerns**:
   - Code is already organized logically into:
     - Routes: [`backend/src/routes/`](../../backend/src/routes/)
     - Controllers: [`backend/src/controllers/`](../../backend/src/controllers/)
     - Business Services: [`backend/src/service/`](../../backend/src/service/)
     - Data Models: [`backend/src/models/`](../../backend/src/models/)
     - Middlewares: [`backend/src/middlewares/`](../../backend/src/middlewares/)
4. **Basic Environment Variable Reading**:
   - Defined in [`backend/src/config/env.ts`](../../backend/src/config/env.ts) using `dotenv`.

---

## 🛠️ How It Was Covered (Implementation Deep Dive)

### 1. Process Protection & Non-blocking Startup
In [`backend/src/server.ts`](../../backend/src/server.ts#L15-L35):
```typescript
// Protect against unhandled Promise rejections
process.on('unhandledRejection', (reason: unknown): void => {
  console.error('💥 UNHANDLED REJECTION! Shutting down server gracefully...');
  console.error(reason);
  server.close((): void => {
    process.exit(1);
  });
});

// Protect against uncaught synchronous exceptions
process.on('uncaughtException', (error: Error): void => {
  console.error('💥 UNCAUGHT EXCEPTION! Shutting down immediately...');
  console.error(error);
  process.exit(1);
});

// Database connection does not block the HTTP port from binding
void connectDatabase().catch((error: unknown): void => {
  console.error('❌ MongoDB Connection Error:', error);
});
```

### 2. Manual Environment Variable Fallbacks
In [`backend/src/config/env.ts`](../../backend/src/config/env.ts#L13-L19):
```typescript
export const env: EnvConfig = {
  port: Number(process.env.PORT) || 5000,
  nodeEnv: process.env.NODE_ENV || 'development',
  mongoUri: process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/url_shortener_db',
  jwtSecret: process.env.JWT_SECRET || 'fallback_secret_for_dev_only',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
};
```
*Design Analysis*: While this is functional for simple scripts, notice the security and reliability flaw: **It uses a default fallback for `JWT_SECRET`**. If deployed without setting `JWT_SECRET`, the app boots silently with an insecure secret instead of **failing fast** at startup!

---

## 🚧 What Is Remaining (NestJS Architecture Target)

### 1. Failing Fast with Validated `ConfigModule`
Instead of silent fallbacks, NestJS applications should validate configuration at startup using Joi or Zod schemas:
- Reject invalid numbers, missing secrets, or malformed database URIs before the application listens on a port.

### 2. NestJS Inversion of Control (IoC) & Dependency Injection
- In Express, our controllers manually import singleton services: `import { authService } from '../service/auth.service'`.
- In NestJS, dependencies are declared in constructors and provided by the NestJS IoC container, allowing easy swapping, mocking, and lifecycle control.

### 3. Modular Boundaries
- Split the monolithic Express app into clean feature modules:
  - `AuthModule`: Encapsulates authentication, token generation, user validation.
  - `UrlModule`: Encapsulates URL creation, custom alias validation, analytics recording.
  - `UserModule`: Encapsulates user management and role assignment.
  - `RedirectModule`: High-performance public redirection handling.
  - `CoreModule`: Global database connections, config, and logging.

### 4. Code Quality & Linting
- Setup `eslint` and `prettier` configurations to enforce consistent code standards and strict typing across the team.

---

## 📋 Actionable Implementation Guide

### Step 1: Install NestJS Core Dependencies
```bash
npm install @nestjs/common @nestjs/core @nestjs/platform-express reflect-metadata rxjs
npm install @nestjs/config joi
npm install -D @types/node typescript ts-node
```

### Step 2: Implement Fail-Fast Configuration Schema with Joi
Create `src/config/env.validation.ts`:
```typescript
import * as Joi from 'joi';

export const envValidationSchema = Joi.object({
  NODE_ENV: Joi.string().valid('development', 'production', 'test').default('development'),
  PORT: Joi.number().port().default(5000),
  MONGODB_URI: Joi.string().uri().required(),
  JWT_SECRET: Joi.string().min(32).required(), // Enforce minimum length, no fallback!
  JWT_EXPIRES_IN: Joi.string().default('7d'),
});
```

### Step 3: Register `ConfigModule` in `AppModule`
Create `src/app.module.ts`:
```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { envValidationSchema } from './config/env.validation';
import { AuthModule } from './auth/auth.module';
import { UrlModule } from './url/url.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validationSchema: envValidationSchema,
      validationOptions: {
        abortEarly: true, // Stop at the first error and fail fast
      },
    }),
    AuthModule,
    UrlModule,
  ],
})
export class AppModule {}
```

### Step 4: Bootstrapping with NestFactory
Create `src/main.ts`:
```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ConfigService } from '@nestjs/config';
import { Logger } from '@nestjs/common';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);
  
  const configService = app.get(ConfigService);
  const port = configService.get<number>('PORT', 5000);
  
  await app.listen(port);
  logger.log(`🚀 NestJS Application running on port ${port}`);
}

bootstrap().catch((err) => {
  console.error('Fatal startup error:', err);
  process.exit(1);
});
```

---

## 🧪 Self-Assessment & Verification Checklist

- [ ] Can you explain the difference between a microtask and a macrotask in the Node.js event loop?
- [ ] What happens if you run `crypto.pbkdf2Sync()` or a synchronous CPU loop inside an Express/NestJS route?
- [ ] If you start the app without setting `JWT_SECRET`, does it immediately throw a validation error and abort boot?
- [ ] Are all services decorated with `@Injectable()` and imported through module `providers` rather than manually instantiated?
