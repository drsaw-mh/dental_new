import { config, isOriginAllowed } from './config.js';

const securityHeaders = {
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'Referrer-Policy': 'no-referrer',
  'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
};

export function applyCommonHeaders(req, res) {
  for (const [key, value] of Object.entries(securityHeaders)) {
    res.setHeader(key, value);
  }

  const origin = req.headers.origin;
  if (isOriginAllowed(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
  }

  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PATCH,DELETE,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

export function isCorsPreflightAllowed(req) {
  const origin = req.headers.origin;
  return !origin || isOriginAllowed(origin);
}

export function sendJson(res, statusCode, payload) {
  const body = JSON.stringify(payload);

  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

export function sendNoContent(res) {
  res.writeHead(204);
  res.end();
}

export function sendError(res, statusCode, message, details = undefined) {
  sendJson(res, statusCode, {
    error: {
      message,
      details,
    },
  });
}

export async function readJson(req) {
  const chunks = [];
  let size = 0;

  for await (const chunk of req) {
    size += chunk.length;
    if (size > config.requestBodyLimitBytes) {
      const error = new Error('Request body is too large.');
      error.statusCode = 413;
      throw error;
    }

    chunks.push(chunk);
  }

  const rawBody = Buffer.concat(chunks).toString('utf8').trim();
  if (!rawBody) {
    return {};
  }

  try {
    return JSON.parse(rawBody);
  } catch {
    const error = new Error('Request body must be valid JSON.');
    error.statusCode = 400;
    throw error;
  }
}
