import { Transform } from 'class-transformer';
import { IsIn, IsNotEmpty, IsString, Length, Matches, MinLength } from 'class-validator';

// Same regex as EMAIL_REGEX in backend/src/service/user.service.ts (not @IsEmail: they differ).
const EMAIL_REGEX = /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/;

const REQUIRED = 'Name, email, and password are required';
// `context` rides along with each rule so the exception factory can read Express's code + order.
const required = { message: REQUIRED, context: { code: 'VALIDATION_ERROR', rank: 1 } };

export class CreateUserDto {
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString(required)
  @IsNotEmpty(required)
  @Length(2, 50, {
    message: 'Name must be between 2 and 50 characters',
    context: { code: 'VALIDATION_ERROR', rank: 2 },
  })
  name!: string;

  @Transform(({ value }) => (typeof value === 'string' ? value.trim().toLowerCase() : value))
  @IsString(required)
  @IsNotEmpty(required)
  @Matches(EMAIL_REGEX, {
    message: 'Please provide a valid email address',
    context: { code: 'VALIDATION_ERROR', rank: 3 },
  })
  email!: string;

  // No @Transform: passwords are never trimmed.
  @IsNotEmpty(required)
  @IsString({
    message: 'Password must be at least 6 characters long',
    context: { code: 'WEAK_PASSWORD', rank: 4 },
  })
  @MinLength(6, {
    message: 'Password must be at least 6 characters long',
    context: { code: 'WEAK_PASSWORD', rank: 4 },
  })
  password!: string;

  @IsIn(['ADMIN', 'NORMAL'], {
    message: 'Role must be one of: ADMIN, NORMAL',
    context: { code: 'INVALID_ROLE', rank: 5 },
  })
  role!: 'ADMIN' | 'NORMAL';
}
