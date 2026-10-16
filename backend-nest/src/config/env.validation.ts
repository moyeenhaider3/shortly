// backend-nest/src/config/env.validation.ts
import * as Joi from 'joi';

/**
 * Schema for every environment variable the app reads.
 * Validated once at boot: if anything is invalid the process exits
 * before listening on a port (fail fast). Replaces Express's env.ts fallbacks.
 */
export const envValidationSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid('development', 'production', 'test')
    .default('development'),
  PORT: Joi.number().port().default(5001),
  DATABASE_URL: Joi.string().uri().required(),
  // No default on purpose: a missing or weak secret must stop the app.
  JWT_SECRET: Joi.string().min(32).required(),
  JWT_EXPIRES_IN: Joi.string().default('7d'),
});
