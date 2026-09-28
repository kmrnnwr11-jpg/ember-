import { AuthError } from './auth.js';
import { FsError } from './fs.js';
import { PathError } from './paths.js';

export function errorPayload(e: unknown): { code: string; message: string } {
  if (e instanceof AuthError) return { code: 'unauthorized', message: e.message };
  if (e instanceof FsError || e instanceof PathError) return { code: e.code, message: e.message };
  const code = (e as { code?: unknown })?.code;
  if (typeof code === 'string' && ['bad_request', 'unsupported', 'not_found', 'too_many_terminals', 'login_expired'].includes(code)) {
    return { code, message: (e as Error).message };
  }
  return { code: 'internal', message: 'internal error' };
}

export function httpStatus(code: string): number {
  switch (code) {
    case 'unauthorized':
      return 401;
    case 'not_found':
      return 404;
    case 'exists':
    case 'conflict':
    case 'not_ready':
      return 409;
    case 'too_large':
      return 413;
    case 'forbidden':
      return 403;
    case 'rate_limited':
      return 429;
    case 'internal':
      return 500;
    default:
      return 400;
  }
}
