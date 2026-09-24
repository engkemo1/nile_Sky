/**
 * One place to resolve the secrets the API signs tokens with.
 *
 * The old code inlined `process.env.JWT_SECRET || 'super-secret-key-…'` in two
 * files. That fallback is committed to a public repository, so if the env var
 * were ever missing in production the API would happily accept tokens anyone
 * could forge. In production a missing secret is now a startup failure, which
 * is the only safe way for it to fail.
 */

const DEV_FALLBACK = 'dev-only-insecure-secret-do-not-use-in-production';

function isProduction(): boolean {
  return process.env.NODE_ENV === 'production';
}

export function jwtSecret(): string {
  const secret = process.env.JWT_SECRET;
  if (secret && secret.length >= 16) return secret;
  if (isProduction()) {
    throw new Error(
      'JWT_SECRET is missing or too short. Set it (32+ random characters) in ' +
        'the deployment environment before starting the API.',
    );
  }
  return DEV_FALLBACK;
}

/**
 * Refresh tokens are signed with a different key from access tokens, so a
 * stolen refresh token cannot simply be presented as a 7-day access token.
 */
export function jwtRefreshSecret(): string {
  const secret = process.env.JWT_REFRESH_SECRET;
  if (secret && secret.length >= 16) return secret;
  if (isProduction() && !process.env.JWT_SECRET) {
    throw new Error('JWT_REFRESH_SECRET or JWT_SECRET must be set in production.');
  }
  return `${jwtSecret()}::refresh`;
}

export function accessTokenTtl(): string {
  return process.env.JWT_EXPIRES_IN || '1h';
}

export function refreshTokenTtl(): string {
  return process.env.JWT_REFRESH_EXPIRES_IN || '30d';
}

/** Comma-separated allowlist, or `*` when the deployment has not set one. */
export function corsOrigin(): string | string[] {
  const raw = process.env.CORS_ORIGINS?.trim();
  if (!raw) return '*';
  return raw.split(',').map((o) => o.trim()).filter(Boolean);
}

/** Swagger is useful in development and is noise (and a map) in production. */
export function swaggerEnabled(): boolean {
  if (process.env.ENABLE_SWAGGER === 'true') return true;
  if (process.env.ENABLE_SWAGGER === 'false') return false;
  return !isProduction();
}
