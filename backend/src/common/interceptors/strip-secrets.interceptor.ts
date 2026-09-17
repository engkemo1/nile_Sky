import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

/**
 * Removes credential fields from every outgoing response, no matter how deeply
 * nested (e.g. booking -> user -> passwordHash). Belt-and-braces: individual
 * services should also avoid selecting them, but this guarantees they never
 * leave the API.
 */
const SECRET_KEYS = new Set([
  'passwordHash',
  'password_hash',
  'refreshTokenHash',
  'refresh_token_hash',
  'password',
]);

function strip(value: any, seen = new WeakSet()): any {
  if (value === null || typeof value !== 'object') return value;
  if (value instanceof Date) return value;
  if (seen.has(value)) return value;
  seen.add(value);

  if (Array.isArray(value)) {
    return value.map((item) => strip(item, seen));
  }

  const out: Record<string, any> = {};
  for (const [key, val] of Object.entries(value)) {
    if (SECRET_KEYS.has(key)) continue;
    out[key] = strip(val, seen);
  }
  return out;
}

@Injectable()
export class StripSecretsInterceptor implements NestInterceptor {
  intercept(_context: ExecutionContext, next: CallHandler): Observable<any> {
    return next.handle().pipe(map((data) => strip(data)));
  }
}
