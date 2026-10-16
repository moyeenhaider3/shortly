# 📘 Day 4: REST API Design & Documentation

> **Focus**: Production RESTful API design, OpenAPI/Swagger as a live contract, backward-compatible API versioning, robust cursor-based pagination, and write idempotency.

---

## 🎯 Topics & Learning Outcomes

### Topics / Coverage
- **RESTful Resource Architecture**: Resource naming, HTTP verbs (GET, POST, PUT, PATCH, DELETE), status codes (200, 201, 204, 302, 400, 401, 403, 404, 409, 429), and HATEOAS overview.
- **Pagination Mechanics**:
  - *Offset vs Limit*: Easy to implement, but suffers from $O(N)$ query degradation at high offsets and "page drift" when items are inserted/deleted.
  - *Cursor-Based Pagination*: $O(1)$ performance, stable across mutations, ideal for infinite-scroll mobile & web dashboards.
- **Filtering, Sorting & Sparse Fieldsets**: Parsing query parameters (`?status=active&sort=-createdAt&fields=shortCode,clickCount`).
- **Idempotency Keys**: Protecting against duplicate payments or link creations from network retries using `Idempotency-Key` headers and Redis caching.
- **API Versioning Strategies**: URI path (`/api/v1/`), Header-based (`Accept-Version: v1`), or Query parameter versioning in NestJS.
- **OpenAPI / Swagger Generation**: Generating interactive API contracts (`@nestjs/swagger`) from code annotations and DTOs.

### Learning Outcomes
- ✅ Build scalable endpoints that the Flutter frontend and external consumers can safely evolve against.
- ✅ Publish an interactive, auto-generated OpenAPI / Swagger UI.
- ✅ Implement cursor-based pagination handling large datasets without performance degradation.

---

## 🔍 What We Have Covered So Far

In our current Shortly codebase:

1. **Standard RESTful Verbs & HTTP Status Codes**:
   - Implemented across routes in [`backend/src/routes/`](../../backend/src/routes/):
     - `POST /api/auth/register` ➔ 201 Created
     - `POST /api/auth/login` ➔ 200 OK
     - `POST /api/urls` ➔ 201 Created
     - `GET /api/urls` ➔ 200 OK
     - `PATCH /api/urls/:id` ➔ 200 OK
     - `DELETE /api/urls/:id` ➔ 200 OK
     - `GET /:shortCode` ➔ 302 Found (Redirect)
2. **Consistent Response Envelope**:
   - JSON responses follow predictable structures (`{ success: true, data: ... }` or `{ success: false, message, code }`).
3. **Flutter Client Integration**:
   - Endpoints are consumed directly by our Flutter frontend (`ApiClient` with Dio) as documented in [`frontend/README.md`](../../frontend/README.md).

---

## 🛠️ How It Was Covered (Implementation Deep Dive)

### 1. Endpoint Mounting & Routing
In [`backend/src/app.ts`](../../backend/src/app.ts#L50-L55):
```typescript
app.use('/api/auth', authRouter);
app.use('/api/urls', urlRouter);
app.use('/api/users', userRouter);
app.use('/', redirectRouter); // Public redirect mounted after API
```

### 2. Unpaginated List Query Vulnerability
In [`backend/src/service/url.service.ts`](../../backend/src/service/url.service.ts#L48-L55):
```typescript
export const getUserUrls = async (userId: string): Promise<IUrlDocument[]> => {
  return await Url.find({ createdBy: userId })
    .sort({ createdAt: -1 })
    .select('-visits'); // Omits heavy subdocuments
};
```
*Design Analysis*: While omitting `-visits` is a good performance optimization, notice that **no pagination exists**. If a user creates 10,000 links, fetching `GET /api/urls` loads 10,000 records into Node.js memory, serializing a massive JSON payload that blocks the event loop and overwhelms the mobile client!

---

## 🚧 What Is Remaining (NestJS Architecture Target)

### 1. Cursor-Based Pagination Implementation
Implement cursor-based queries using an encoded cursor (e.g. `base64(createdAt_id)`) to query records with `WHERE (createdAt, id) < (cursorCreatedAt, cursorId) LIMIT 20`.

```json
{
  "success": true,
  "data": [...],
  "pagination": {
    "hasMore": true,
    "nextCursor": "ZXlKa1pXSnBZ..."
  }
}
```

### 2. OpenAPI / Swagger Documentation
Auto-generate a complete Swagger interface using `@ApiTags()`, `@ApiOperation()`, `@ApiResponse()`, and `@ApiProperty()`.

### 3. API Versioning
Enable URI versioning in NestJS `main.ts`:
```typescript
app.enableVersioning({
  type: VersioningType.URI,
  defaultVersion: '1',
  prefix: 'api/v',
});
// Resolves to: /api/v1/urls
```

### 4. Idempotency Key Middleware / Interceptor
For `POST /api/urls`, allow clients to pass `Idempotency-Key: uuid`. Store the key in Redis with a 5-minute TTL. If duplicate requests arrive, return the cached response immediately without creating another URL.

---

## 📋 Actionable Implementation Guide

### Step 1: Install Swagger Dependencies
```bash
npm install @nestjs/swagger swagger-ui-express
```

### Step 2: Configure Swagger in `src/main.ts`
```typescript
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

const swaggerConfig = new DocumentBuilder()
  .setTitle('Shortly API')
  .setDescription('High-performance URL shortener, analytics engine, and redirect server')
  .setVersion('1.0')
  .addBearerAuth()
  .build();

const document = SwaggerModule.createDocument(app, swaggerConfig);
SwaggerModule.setup('api/docs', app, document);
```

### Step 3: Implement Cursor Pagination DTO
Create `src/common/dto/cursor-pagination.dto.ts`:
```typescript
import { IsOptional, IsInt, Min, Max, IsString } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class CursorPaginationDto {
  @ApiPropertyOptional({ description: 'Pagination cursor for next page', example: 'eyJpZCI6IjEyMyJ9' })
  @IsOptional()
  @IsString()
  cursor?: string;

  @ApiPropertyOptional({ default: 20, minimum: 1, maximum: 100 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit: number = 20;
}
```

### Step 4: Annotate Controllers with OpenAPI Decorators
Create `src/url/url.controller.ts`:
```typescript
import { Controller, Get, Post, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { CreateUrlDto } from './dto/create-url.dto';
import { CursorPaginationDto } from '../common/dto/cursor-pagination.dto';
import { UrlService } from './url.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('URLs')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller({ path: 'urls', version: '1' })
export class UrlController {
  constructor(private readonly urlService: UrlService) {}

  @Post()
  @ApiOperation({ summary: 'Create a short URL or custom alias' })
  @ApiResponse({ status: 201, description: 'URL successfully created' })
  @ApiResponse({ status: 409, description: 'Custom alias already in use' })
  async create(@Body() dto: CreateUrlDto, @CurrentUser('id') userId: string) {
    return this.urlService.createUrl(dto, userId);
  }

  @Get()
  @ApiOperation({ summary: 'List URLs for current user with cursor pagination' })
  async findAll(@Query() pagination: CursorPaginationDto, @CurrentUser('id') userId: string) {
    return this.urlService.getUserUrls(userId, pagination);
  }
}
```

---

## 🧪 Self-Assessment & Verification Checklist

- [ ] Can you open `http://localhost:5000/api/docs` and execute API calls directly from the Swagger UI?
- [ ] Why is cursor pagination faster than `OFFSET 50000 LIMIT 20` in SQL databases?
- [ ] If a network request times out and the client retries with an `Idempotency-Key`, does it return the existing entity instead of creating a duplicate?
- [ ] When you increment an API version to `v2`, do existing `v1` clients continue working without errors?
