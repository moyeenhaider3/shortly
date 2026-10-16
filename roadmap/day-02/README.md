# 📘 Day 2: Request Lifecycle, Validation & Error Handling

> **Focus**: Mastering the NestJS execution pipeline, enforcing input integrity with declarative DTOs (`class-validator`), transforming responses, and building safe, predictable error filters.

---

## 🎯 Topics & Learning Outcomes

### Topics / Coverage
- **The NestJS 6-Stage Request Lifecycle**:
  `Incoming Request` ➔ **Middleware** ➔ **Guards** ➔ **Interceptors (Pre-controller)** ➔ **Pipes** ➔ **Route Handler** ➔ **Interceptors (Post-controller)** ➔ **Exception Filters** ➔ `Outgoing Response`.
- **Architectural Discipline**: Keeping controllers thin (I/O, status codes, delegation) and moving all business rules to injectable services.
- **Data Transfer Objects (DTOs)**: Enforcing input contracts using `class-validator` and `class-transformer`.
- **Security through Whitelisting**: `whitelist: true`, `forbidNonWhitelisted: true`, and stripping malicious/unexpected fields before execution.
- **Exception Filters**: Custom `@Catch(HttpException)` and all-exceptions filters to guarantee standardized, secure error payloads.
- **RxJS Interceptors**: Logging execution time, transforming response formats, and enforcing request timeouts.
- **Testing Introduction**: Writing unit tests for services using `@nestjs/testing` and mocking dependencies.

### Learning Outcomes
- ✅ Route cross-cutting concerns (auth, validation, logging, formatting) to the correct lifecycle phase.
- ✅ Reject malformed payloads declaratively before they touch controller or service code.
- ✅ Return uniform, client-safe error envelopes without leaking database or framework internals.

---

## 🔍 What We Have Covered So Far

In our current Shortly codebase:

1. **Thin Controllers & Layered Services**:
   - Controllers like [`backend/src/controllers/url.controller.ts`](../../backend/src/controllers/url.controller.ts) unpack `req.body`, `req.user`, and `req.params`, and forward work directly to [`backend/src/service/url.service.ts`](../../backend/src/service/url.service.ts).
2. **Centralized Operational Error Class**:
   - Implemented `AppError` in [`backend/src/middlewares/error.middleware.ts`](../../backend/src/middlewares/error.middleware.ts) capturing HTTP status codes and machine-readable error codes (`NOT_FOUND`, `BAD_REQUEST`, `UNAUTHORIZED`).
3. **Global Express Error Middleware**:
   - Single fallback in [`backend/src/middlewares/error.middleware.ts`](../../backend/src/middlewares/error.middleware.ts) that differentiates expected `AppError`s from internal 500 bugs, sanitizing production error messages.
4. **Manual Validation Utility**:
   - Custom string and regex validators in [`backend/src/utils/validators.ts`](../../backend/src/utils/validators.ts) checking URL protocols (`http:`/`https:`), slug format, and a 17-word reserved list (`api`, `admin`, `health`, etc.).

---

## 🛠️ How It Was Covered (Implementation Deep Dive)

### 1. Manual Validation Inside Services / Controllers
In [`backend/src/utils/validators.ts`](../../backend/src/utils/validators.ts#L25-L51):
```typescript
export const isValidUrl = (urlString: string): boolean => {
  try {
    const parsedUrl = new URL(urlString);
    return parsedUrl.protocol === 'http:' || parsedUrl.protocol === 'https:';
  } catch {
    return false;
  }
};

export const isValidAliasFormat = (alias: string): boolean => {
  const aliasRegex = /^[a-zA-Z0-9]+(-[a-zA-Z0-9]+)*$/;
  return alias.length >= 3 && alias.length <= 30 && aliasRegex.test(alias);
};
```
*Current Pattern*: These functions are called imperatively inside `url.service.ts`. If an alias is invalid, code manually throws `new AppError('Invalid alias format', 400, 'INVALID_ALIAS')`.

### 2. Express 4-Argument Error Handler
In [`backend/src/middlewares/error.middleware.ts`](../../backend/src/middlewares/error.middleware.ts#L40-L64):
```typescript
export const errorHandler: ErrorRequestHandler = (err: any, req: Request, res: Response, next: NextFunction): void => {
  const isClientSafe = err instanceof AppError || (err.expose === true && typeof err.type === 'string');
  const statusCode = isClientSafe ? err.statusCode || 500 : 500;
  const code = isClientSafe ? err.code || 'BAD_REQUEST' : 'INTERNAL_SERVER_ERROR';
  const message = isClientSafe ? err.message : 'Something went wrong on the server';

  res.status(statusCode).json({
    success: false,
    message,
    code,
  });
};
```

---

## 🚧 What Is Remaining (NestJS Architecture Target)

```mermaid
flowchart LR
    Req([Client Request]) --> Mid[Middleware]
    Mid --> Guard[Guards]
    Guard --> PreInt[Interceptors - Pre]
    PreInt --> Pipe[ValidationPipe - DTO]
    Pipe --> Handler[Route Handler / Controller]
    Handler --> PostInt[Interceptors - Post]
    PostInt --> Filter[Exception Filters]
    Filter --> Res([Client Response])
```

### 1. Declarative Validation with DTOs & `ValidationPipe`
- Replace imperative `if (!isValidUrl(url))` checks with DTO classes decorated with `@IsUrl()`, `@Length()`, `@IsOptional()`.
- Enable global validation:
  ```typescript
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,              // Strips unexpected fields
    forbidNonWhitelisted: true,   // Rejects requests with unexpected fields (400)
    transform: true,              // Auto-converts payloads to DTO instances
  }));
  ```

### 2. NestJS Custom Constraint Decorator
- Migrate the reserved words check into a reusable `@IsNotReserved()` class-validator decorator.

### 3. NestJS `@Catch()` Exception Filter
- Build a global `AllExceptionsFilter` implementing `ExceptionFilter` to format all errors into our standard Shortly response structure:
  ```json
  {
    "success": false,
    "message": "...",
    "code": "..."
  }
  ```

### 4. Interceptors for Response Wrapping & Timeouts
- **TransformInterceptor**: Automatically wrap successful controller returns in `{ success: true, data: result, timestamp: ... }`.
- **TimeoutInterceptor**: Use RxJS `timeout(5000)` to cancel slow requests and return `408 Request Timeout`.

---

## 📋 Actionable Implementation Guide

### Step 1: Install Validation & Transformation Libraries
```bash
npm install class-validator class-transformer
npm install -D @nestjs/testing jest @types/jest ts-jest
```

### Step 2: Define CreateUrlDto
Create `src/url/dto/create-url.dto.ts`:
```typescript
import { IsNotEmpty, IsUrl, IsOptional, Length, Matches } from 'class-validator';

export class CreateUrlDto {
  @IsNotEmpty({ message: 'Original URL is required' })
  @IsUrl({ protocols: ['http', 'https'], require_protocol: true }, { message: 'Must be a valid HTTP/HTTPS URL' })
  originalUrl: string;

  @IsOptional()
  @Length(3, 30, { message: 'Custom alias must be between 3 and 30 characters' })
  @Matches(/^[a-zA-Z0-9]+(-[a-zA-Z0-9]+)*$/, {
    message: 'Alias can only contain letters, numbers, and hyphens (cannot start or end with hyphen)',
  })
  customAlias?: string;
}
```

### Step 3: Implement Global HttpExceptionFilter
Create `src/common/filters/http-exception.filter.ts`:
```typescript
import { ExceptionFilter, Catch, ArgumentsHost, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { Request, Response } from 'express';

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger('ExceptionFilter');

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message = 'Something went wrong on the server';
    let code = 'INTERNAL_SERVER_ERROR';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const res = exception.getResponse();
      message = typeof res === 'string' ? res : (res as any).message || exception.message;
      code = (res as any).code || 'BAD_REQUEST';
    } else {
      this.logger.error(`Unhandled error at ${request.method} ${request.url}:`, exception);
    }

    response.status(status).json({
      success: false,
      message,
      code,
      timestamp: new Date().toISOString(),
    });
  }
}
```

### Step 4: Write Unit Test for UrlService
Create `src/url/url.service.spec.ts`:
```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { UrlService } from './url.service';
import { getModelToken } from '@nestjs/mongoose';

describe('UrlService', () => {
  let service: UrlService;

  const mockUrlModel = {
    create: jest.fn(),
    findOne: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UrlService,
        {
          provide: getModelToken('Url'),
          useValue: mockUrlModel,
        },
      ],
    }).compile();

    service = module.get<UrlService>(UrlService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
```

---

## 🧪 Self-Assessment & Verification Checklist

- [ ] What order does NestJS execute: Guards, Middleware, Pipes, or Interceptors?
- [ ] What happens when a client sends an extra field (`{ "role": "ADMIN" }`) if `whitelist: true` and `forbidNonWhitelisted: true` are enabled?
- [ ] Does your global exception filter handle both standard `HttpException`s and unexpected runtime `Error`s safely?
- [ ] Can you run `npm run test` and pass basic unit tests with mocked providers?
