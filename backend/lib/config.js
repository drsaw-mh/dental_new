const defaultAllowedOrigins = [
  'http://127.0.0.1:3000',
  'http://localhost:3000',
  'http://127.0.0.1:8080',
  'http://localhost:8080',
  'http://127.0.0.1:5173',
  'http://localhost:5173',
];

function parseList(value, fallback) {
  if (!value) {
    return fallback;
  }

  return value
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
}

function parsePositiveInteger(value, fallback) {
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed > 0 ? parsed : fallback;
}

export const config = {
  env: process.env.NODE_ENV ?? 'development',
  apiHost: process.env.API_HOST ?? '127.0.0.1',
  apiPort: parsePositiveInteger(process.env.PORT, 4000),
  webHost: process.env.WEB_HOST ?? '127.0.0.1',
  webPort: parsePositiveInteger(process.env.WEB_PORT, 8080),
  allowedOrigins: parseList(process.env.ALLOWED_ORIGINS, defaultAllowedOrigins),
  requestBodyLimitBytes: parsePositiveInteger(
    process.env.REQUEST_BODY_LIMIT_BYTES,
    1_048_576,
  ),
};

export function isOriginAllowed(origin) {
  return Boolean(origin && config.allowedOrigins.includes(origin));
}
