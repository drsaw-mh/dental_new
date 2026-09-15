import { createServer } from 'node:http';
import { store } from './data/store.js';
import { buildBooking, createBooking } from './lib/booking.js';
import { config } from './lib/config.js';
import { buildDashboard } from './lib/dashboard.js';
import {
  applyCommonHeaders,
  isCorsPreflightAllowed,
  readJson,
  sendError,
  sendJson,
  sendNoContent,
} from './lib/http.js';
import {
  createResource,
  deleteResource,
  authorizeDelete,
  getPatientRecord,
  listResource,
  listPatientRecords,
  prepareCreateBody,
  prepareUpdateBody,
  resources,
  updateResource,
} from './lib/resources.js';

export function createApp() {
  return createServer(async (req, res) => {
    try {
      applyCommonHeaders(req, res);

      if (req.method === 'OPTIONS') {
        if (!isCorsPreflightAllowed(req)) {
          sendError(res, 403, 'Origin is not allowed.');
          return;
        }

        sendNoContent(res);
        return;
      }

      const url = new URL(req.url ?? '/', 'http://localhost');
      const pathParts = url.pathname.split('/').filter(Boolean);

      if (url.pathname === '/health') {
        sendJson(res, 200, {
          status: 'ok',
          service: 'dental-app-backend',
          environment: config.env,
        });
        return;
      }

      if (url.pathname === '/' && req.method === 'GET') {
        sendJson(res, 200, {
          service: 'dental-app-backend',
          message: 'DentalOps API is running.',
          routes: [
            '/health',
            '/api/profile',
            '/api/dashboard',
            '/api/booking',
            '/api/projects',
            '/api/projectHistory',
            '/api/users',
            '/api/patients',
            '/api/doctors',
            '/api/appointments',
            '/api/invoices',
            '/api/payments',
            '/api/pharmacy',
            '/api/pharmacyDispenses',
            '/api/pharmacyPayments',
            '/api/followUps',
            '/api/patient-records',
            '/api/procedures',
          ],
        });
        return;
      }

      if (url.pathname === '/api/dashboard' && req.method === 'GET') {
        sendJson(res, 200, { data: buildDashboard() });
        return;
      }

      if (url.pathname === '/api/profile' && req.method === 'GET') {
        sendJson(res, 200, { data: store.profile });
        return;
      }

      if (url.pathname === '/api/profile' && req.method === 'PATCH') {
        const body = await readJson(req);
        store.profile = { ...store.profile, ...body };
        sendJson(res, 200, { data: store.profile });
        return;
      }

      if (url.pathname === '/api/booking' && req.method === 'GET') {
        sendJson(res, 200, { data: buildBooking() });
        return;
      }

      if (url.pathname === '/api/booking' && req.method === 'POST') {
        const body = await readJson(req);
        const result = createBooking(body);

        if (result.errors) {
          sendError(res, 422, 'Validation failed.', result.errors);
          return;
        }

        sendJson(res, 201, { data: result.appointment });
        return;
      }

      if (url.pathname === '/api/patient-records' && req.method === 'GET') {
        sendJson(res, 200, { data: listPatientRecords(url.searchParams) });
        return;
      }

      if (pathParts[0] !== 'api') {
        sendError(res, 404, 'Route not found.');
        return;
      }

      const resourceName = pathParts[1];

      if (resourceName === 'patient-records' && pathParts[2]) {
        if (req.method !== 'GET') {
          sendError(res, 405, 'Method not allowed.');
          return;
        }

        const record = getPatientRecord(pathParts[2]);
        if (!record) {
          sendError(res, 404, 'Patient record not found.');
          return;
        }

        sendJson(res, 200, { data: record });
        return;
      }

      const resource = resources[resourceName];

      if (!resource) {
        sendError(res, 404, 'API resource not found.');
        return;
      }

      const id = pathParts[2];

      if (!id && req.method === 'GET') {
        sendJson(res, 200, { data: listResource(resource, url.searchParams) });
        return;
      }

      if (!id && req.method === 'POST') {
        const body = await readJson(req);
        const prepared = prepareCreateBody(resourceName, body);

        if (prepared.forbidden) {
          sendError(res, 403, prepared.forbidden);
          return;
        }

        if (prepared.errors) {
          sendError(res, 422, 'Validation failed.', prepared.errors);
          return;
        }

        const result = createResource(resource, prepared.body);

        if (result.errors) {
          sendError(res, 422, 'Validation failed.', result.errors);
          return;
        }

        sendJson(res, 201, { data: result.item });
        return;
      }

      if (id && req.method === 'PATCH') {
        const body = await readJson(req);
        const prepared = prepareUpdateBody(resourceName, body);

        if (prepared.forbidden) {
          sendError(res, 403, prepared.forbidden);
          return;
        }

        if (prepared.errors) {
          sendError(res, 422, 'Validation failed.', prepared.errors);
          return;
        }

        const result = updateResource(resource, id, prepared.body);

        if (result.notFound) {
          sendError(res, 404, 'Item not found.');
          return;
        }

        sendJson(res, 200, { data: result.item });
        return;
      }

      if (id && req.method === 'DELETE') {
        const authorized = authorizeDelete(resourceName, url.searchParams);

        if (authorized.forbidden) {
          sendError(res, 403, authorized.forbidden);
          return;
        }

        if (!deleteResource(resource, id)) {
          sendError(res, 404, 'Item not found.');
          return;
        }

        sendNoContent(res);
        return;
      }

      sendError(res, 405, 'Method not allowed.');
    } catch (error) {
      sendError(
        res,
        error.statusCode ?? 500,
        error.statusCode ? error.message : 'Unexpected server error.',
      );
    }
  });
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const server = createApp();

  server.listen(config.apiPort, config.apiHost, () => {
    console.log(
      `DentalOps API running on http://${config.apiHost}:${config.apiPort}`,
    );
  });

  function shutdown(signal) {
    console.log(`${signal} received. Shutting down DentalOps API.`);
    server.close(() => process.exit(0));
  }

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}
