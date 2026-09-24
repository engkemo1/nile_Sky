/**
 * One place to resolve the secrets the API signs tokens with.
 *
 * The old code inlined `process.env.JWT_SECRET || 'super-secret-key-…'` in two
 * files. That fallback is committed to a public repository, so if the env var
 * were ever missing in production the API would happily accept tokens anyone
 * could forge. In production a missing secret is now a startup failure, which
 * is the only safe way for it to fail.
 */

import { createHash } from 'crypto';

const DEV_FALLBACK = 'dev-only-insecure-secret-do-not-use-in-production';

function isProduction(): boolean {
  return process.env.NODE_ENV === 'production';
}

/**
 * A signing key derived from the database credentials, used when no JWT_SECRET
 * has been set.
 *
 * The point of a signing key is that an attacker cannot guess it. A literal
 * written in this repository fails that immediately — the repository is
 * public. DATABASE_URL is not: it is already set in the deployment because
 * nothing works without it, it is the same across cold starts and across every
 * serverless instance, and it is never committed. Hashing it with a fixed
 * label gives a stable key per deployment and per purpose, with nothing to
 * configure.
 *
 * Two consequences worth knowing. Rotating the database password rotates this
 * key too, so everyone signs in again — a nuisance, not a failure. And anyone
 * holding DATABASE_URL can derive this key; they already own the database, so
 * nothing new is exposed. Setting JWT_SECRET explicitly avoids both and always
 * takes precedence.
 */
function derivedSecret(label: string): string | null {
  const seed =
    process.env.DATABASE_URL ||
    (process.env.DB_PASSWORD && process.env.DB_HOST
      ? `${process.env.DB_HOST}:${process.env.DB_DATABASE}:${process.env.DB_PASSWORD}`
      : null);
  if (!seed) return null;
  return createHash('sha256').update(`nilesky:jwt:${label}:${seed}`).digest('hex');
}

export function jwtSecret(): string {
  const secret = process.env.JWT_SECRET;
  if (secret && secret.length >= 16) return secret;

  const derived = derivedSecret('access');
  if (derived) return derived;

  if (isProduction()) {
    throw new Error(
      'No JWT_SECRET and no DATABASE_URL, so there is nothing to sign tokens ' +
        'with. Set one of them before starting the API.',
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

  // A different label, so this is a genuinely different key from the access
  // one rather than the same value with a suffix.
  const derived = derivedSecret('refresh');
  if (derived) return derived;

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
