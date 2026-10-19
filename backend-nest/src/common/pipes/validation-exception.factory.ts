import type { ValidationError } from 'class-validator';
import { AppException } from '../exceptions/app.exception';

type RuleContext = { code: string; rank: number };
type Failure = { message: string; code: string; rank: number };

/** Collects every failed rule, including nested ones, with its code/rank context. */
function collect(errors: ValidationError[], out: Failure[] = []): Failure[] {
  for (const error of errors) {
    for (const [rule, message] of Object.entries(error.constraints ?? {})) {
      const ctx = error.contexts?.[rule] as RuleContext | undefined;
      out.push({ message, code: ctx?.code ?? 'VALIDATION_ERROR', rank: ctx?.rank ?? 99 });
    }
    if (error.children?.length) collect(error.children, out);
  }
  return out;
}

/**
 * Express reports only the FIRST failing check, in a fixed order. We reproduce that
 * by picking the failed rule with the lowest rank. Never include the rejected value in the message.
 */
export function validationExceptionFactory(errors: ValidationError[]): AppException {
  const failures = collect(errors).sort((a, b) => a.rank - b.rank);
  const first = failures[0];
  return new AppException(
    first?.message ?? 'Name, email, and password are required',
    400,
    first?.code ?? 'VALIDATION_ERROR',
  );
}
