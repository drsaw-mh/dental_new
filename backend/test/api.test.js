import { after, before, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { createApp } from '../server.js';

let server;
let baseUrl;

describe('DentalOps API', () => {
  before(async () => {
    server = createApp();
    await listen(server);
    const { port } = server.address();
    baseUrl = `http://127.0.0.1:${port}`;
  });

  after(async () => {
    await new Promise((resolve, reject) => {
      server.close((error) => (error ? reject(error) : resolve()));
    });
  });

  it('returns health status', async () => {
    const response = await fetch(`${baseUrl}/health`);
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.equal(body.status, 'ok');
    assert.equal(response.headers.get('x-content-type-options'), 'nosniff');
  });

  it('allows configured local web origins only', async () => {
    const allowedResponse = await fetch(`${baseUrl}/health`, {
      headers: { Origin: 'http://127.0.0.1:8080' },
    });

    assert.equal(allowedResponse.status, 200);
    assert.equal(
      allowedResponse.headers.get('access-control-allow-origin'),
      'http://127.0.0.1:8080',
    );

    const blockedResponse = await fetch(`${baseUrl}/api/dashboard`, {
      method: 'OPTIONS',
      headers: { Origin: 'https://unknown.example' },
    });
    const blockedBody = await blockedResponse.json();

    assert.equal(blockedResponse.status, 403);
    assert.equal(blockedBody.error.message, 'Origin is not allowed.');
  });

  it('rejects request bodies over the configured limit', async () => {
    const response = await fetch(`${baseUrl}/api/invoices`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ payload: 'x'.repeat(1_048_600) }),
    });
    const body = await response.json();

    assert.equal(response.status, 413);
    assert.equal(body.error.message, 'Request body is too large.');
  });

  it('returns API information at the root route', async () => {
    const response = await fetch(`${baseUrl}/`);
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.equal(body.service, 'dental-app-backend');
    assert.ok(body.routes.includes('/api/projects'));
    assert.ok(body.routes.includes('/api/patients'));
  });

  it('returns dashboard metrics', async () => {
    const response = await fetch(`${baseUrl}/api/dashboard`);
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.equal(typeof body.data.metrics.todayAppointments, 'number');
    assert.ok(Array.isArray(body.data.schedule));
  });

  it('returns and updates profile', async () => {
    const response = await fetch(`${baseUrl}/api/profile`);
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.equal(body.data.name, 'Owner Account');
    assert.equal(body.data.role, 'Owner');

    const updateResponse = await fetch(`${baseUrl}/api/profile`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ language: 'Myanmar' }),
    });
    const updateBody = await updateResponse.json();

    assert.equal(updateResponse.status, 200);
    assert.equal(updateBody.data.language, 'Myanmar');
  });

  it('returns booking metrics, slots, and appointment queue', async () => {
    const response = await fetch(`${baseUrl}/api/booking`);
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.equal(typeof body.data.metrics.openSlots, 'number');
    assert.ok(Array.isArray(body.data.slots));
    assert.ok(Array.isArray(body.data.queue));
  });

  it('returns linked patient records', async () => {
    const listResponse = await fetch(`${baseUrl}/api/patient-records?q=Ben`);
    const listBody = await listResponse.json();

    assert.equal(listResponse.status, 200);
    assert.equal(listBody.data.length, 1);
    assert.equal(listBody.data[0].patient.name, 'Ben Tan');
    assert.equal(listBody.data[0].procedures[0].name, 'Root Canal');
    assert.equal(listBody.data[0].followUps[0].reason, 'Pain score check after root canal review');

    const detailResponse = await fetch(`${baseUrl}/api/patient-records/pat_001`);
    const detailBody = await detailResponse.json();

    assert.equal(detailResponse.status, 200);
    assert.equal(detailBody.data.patient.phone, '+60 12-550 7712');
    assert.ok(detailBody.data.appointments.length >= 1);
    assert.ok(detailBody.data.pharmacyPayments.length >= 1);
    assert.ok(detailBody.data.clinicalNotes.length >= 1);
  });

  it('keeps patients separate from login users', async () => {
    const usersResponse = await fetch(`${baseUrl}/api/users?q=Ben`);
    const usersBody = await usersResponse.json();

    assert.equal(usersResponse.status, 200);
    assert.equal(usersBody.data.length, 0);

    const patientsResponse = await fetch(`${baseUrl}/api/patients?q=Ben`);
    const patientsBody = await patientsResponse.json();

    assert.equal(patientsResponse.status, 200);
    assert.equal(patientsBody.data.length, 1);
    assert.equal(patientsBody.data[0].name, 'Ben Tan');
    assert.equal(patientsBody.data[0].role, 'Patient');
  });

  it('creates an appointment through booking', async () => {
    const response = await fetch(`${baseUrl}/api/booking`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        patient: 'Lina Ong',
        time: '15:30',
        procedure: 'Consultation',
        doctor: 'Dr. Marcus Lee',
        slotId: 'slot_002',
      }),
    });
    const body = await response.json();

    assert.equal(response.status, 201);
    assert.equal(body.data.patient, 'Lina Ong');
    assert.equal(body.data.status, 'Scheduled');
  });

  it('creates a project', async () => {
    const response = await fetch(`${baseUrl}/api/projects`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        projectId: 'PRJ-20260715-010',
        name: 'Inventory barcode rollout',
        owner: 'Operations',
        deadline: 'Jul 15',
        clinicalNote: 'Barcode labels checked chairside',
        followUpReason: 'Check label scan rate',
        followUpDue: 'Tomorrow',
        followUpChannel: 'WhatsApp',
        followUpPriority: 'Medium',
        progress: 0,
        color: '#0B7285',
      }),
    });
    const body = await response.json();

    assert.equal(response.status, 201);
    assert.equal(body.data.projectId, 'PRJ-20260715-010');
    assert.equal(body.data.name, 'Inventory barcode rollout');
    assert.equal(body.data.owner, 'Operations');
    assert.equal(body.data.clinicalNote, 'Barcode labels checked chairside');
    assert.equal(body.data.followUpReason, 'Check label scan rate');
    assert.equal(body.data.followUpDue, 'Tomorrow');
    assert.equal(body.data.followUpChannel, 'WhatsApp');
    assert.equal(body.data.followUpPriority, 'Medium');
  });

  it('allows users to create User role only', async () => {
    const userResponse = await fetch(`${baseUrl}/api/users`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Maya User',
        role: 'User',
        status: 'Active',
        age: '29',
        phone: '+60 12-700 1111',
        address: '12 Jalan Klinik',
        createdByRole: 'User',
      }),
    });
    const userBody = await userResponse.json();

    assert.equal(userResponse.status, 201);
    assert.equal(userBody.data.name, 'Maya User');
    assert.equal(userBody.data.role, 'User');
    assert.equal(userBody.data.age, '29');
    assert.equal(userBody.data.phone, '+60 12-700 1111');
    assert.equal(userBody.data.address, '12 Jalan Klinik');
    assert.equal(userBody.data.createdByRole, undefined);

    const blockedResponse = await fetch(`${baseUrl}/api/users`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Blocked Admin',
        role: 'Admin',
        status: 'Pending',
        age: '34',
        phone: '+60 12-800 2222',
        address: 'Admin Office',
        createdByRole: 'User',
      }),
    });
    const blockedBody = await blockedResponse.json();

    assert.equal(blockedResponse.status, 403);
    assert.equal(
      blockedBody.error.message,
      'Admin or Owner required for this role.',
    );
  });

  it('allows admin and owner to create elevated roles', async () => {
    const adminResponse = await fetch(`${baseUrl}/api/users`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Clinic Admin',
        role: 'Admin',
        status: 'Operations',
        age: '36',
        phone: '+60 12-900 3333',
        address: 'Owner Office',
        createdByRole: 'Owner',
      }),
    });
    const adminBody = await adminResponse.json();

    assert.equal(adminResponse.status, 201);
    assert.equal(adminBody.data.name, 'Clinic Admin');
    assert.equal(adminBody.data.role, 'Admin');
    assert.equal(adminBody.data.age, '36');
    assert.equal(adminBody.data.phone, '+60 12-900 3333');
    assert.equal(adminBody.data.address, 'Owner Office');
  });

  it('creates and updates a follow-up', async () => {
    const createResponse = await fetch(`${baseUrl}/api/followUps`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        patient: 'Nora Aziz',
        reason: 'Crown fitting confirmation',
        due: 'Monday',
        channel: 'Phone call',
        priority: 'Medium',
      }),
    });
    const createBody = await createResponse.json();

    assert.equal(createResponse.status, 201);
    assert.equal(createBody.data.patient, 'Nora Aziz');

    const updateResponse = await fetch(`${baseUrl}/api/followUps/${createBody.data.id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ completed: true }),
    });
    const updateBody = await updateResponse.json();

    assert.equal(updateResponse.status, 200);
    assert.equal(updateBody.data.completed, true);
  });

  it('creates an invoice with a payment method', async () => {
    const response = await fetch(`${baseUrl}/api/invoices`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        patient: 'Nora Aziz',
        number: 'INV-1052',
        method: 'Cash',
        status: 'Ready to pay',
        amount: 950,
      }),
    });
    const body = await response.json();

    assert.equal(response.status, 201);
    assert.equal(body.data.patient, 'Nora Aziz');
    assert.equal(body.data.number, 'INV-1052');
    assert.equal(body.data.method, 'Cash');
    assert.equal(body.data.amount, 950);
  });

  it('saves project history invoices', async () => {
    const response = await fetch(`${baseUrl}/api/projectHistory`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        patient: 'Nora Aziz',
        number: 'INV-1053',
        method: 'Cash',
        status: 'Ready to pay',
        amount: 'RM 950',
        procedure: 'Root canal consult',
        doctor: 'Dr. Lee',
        dentition: 'Adult',
        tooth: 'Tooth 11',
      }),
    });
    const body = await response.json();

    assert.equal(response.status, 201);
    assert.equal(body.data.patient, 'Nora Aziz');
    assert.equal(body.data.number, 'INV-1053');

    const listResponse = await fetch(`${baseUrl}/api/projectHistory`);
    const listBody = await listResponse.json();

    assert.equal(listResponse.status, 200);
    assert.ok(
      listBody.data.some((invoice) => invoice.number === 'INV-1053'),
    );

    const deleteResponse = await fetch(
      `${baseUrl}/api/projectHistory/${body.data.id}`,
      { method: 'DELETE' },
    );

    assert.equal(deleteResponse.status, 204);
  });

  it('records a payment', async () => {
    const response = await fetch(`${baseUrl}/api/payments`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        patient: 'Nora Aziz',
        invoiceNumber: 'INV-1052',
        method: 'Card',
        amount: 950,
        paidDate: 'Today',
        reference: 'PAY-2041',
        note: 'Paid by card',
      }),
    });
    const body = await response.json();

    assert.equal(response.status, 201);
    assert.equal(body.data.patient, 'Nora Aziz');
    assert.equal(body.data.invoiceNumber, 'INV-1052');
    assert.equal(body.data.method, 'Card');
    assert.equal(body.data.reference, 'PAY-2041');
  });

  it('lists and creates pharmacy inventory', async () => {
    const listResponse = await fetch(`${baseUrl}/api/pharmacy`);
    const listBody = await listResponse.json();

    assert.equal(listResponse.status, 200);
    assert.ok(Array.isArray(listBody.data));
    assert.ok(
      listBody.data.some((item) => item.name === 'Amoxicillin 500mg'),
    );

    const createResponse = await fetch(`${baseUrl}/api/pharmacy`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Articaine cartridge',
        category: 'Local anesthetic',
        stock: 40,
        unit: 'cartridges',
        batch: 'ART-44K',
        expiry: 'Feb 2028',
        status: 'In stock',
      }),
    });
    const createBody = await createResponse.json();

    assert.equal(createResponse.status, 201);
    assert.equal(createBody.data.name, 'Articaine cartridge');
    assert.equal(createBody.data.batch, 'ART-44K');
  });

  it('lists and creates pharmacy cashier payments', async () => {
    const listResponse = await fetch(`${baseUrl}/api/pharmacyPayments`);
    const listBody = await listResponse.json();

    assert.equal(listResponse.status, 200);
    assert.ok(Array.isArray(listBody.data));
    assert.ok(listBody.data.some((item) => item.invoiceNumber === 'RX-2048'));

    const createResponse = await fetch(`${baseUrl}/api/pharmacyPayments`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        patient: 'Mei Chen',
        invoiceNumber: 'RX-2051',
        method: 'Online',
        status: 'Paid',
        amount: 140,
      }),
    });
    const createBody = await createResponse.json();

    assert.equal(createResponse.status, 201);
    assert.equal(createBody.data.patient, 'Mei Chen');
    assert.equal(createBody.data.invoiceNumber, 'RX-2051');
  });

  it('allows owner and admin to manage procedures only', async () => {
    const blockedResponse = await fetch(`${baseUrl}/api/procedures`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Blocked procedure',
        price: 'RM 100',
        estimate: '20 min',
        actorRole: 'User',
      }),
    });
    const blockedBody = await blockedResponse.json();

    assert.equal(blockedResponse.status, 403);
    assert.equal(
      blockedBody.error.message,
      'Owner or Admin required for procedure management.',
    );

    const createResponse = await fetch(`${baseUrl}/api/procedures`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Crown fitting',
        price: 'RM 950',
        estimate: '50 min',
        category: 'Restorative',
        subcategory: 'Crown',
        actorRole: 'Owner',
      }),
    });
    const createBody = await createResponse.json();

    assert.equal(createResponse.status, 201);
    assert.equal(createBody.data.name, 'Crown fitting');
    assert.equal(createBody.data.actorRole, undefined);

    const updateResponse = await fetch(
      `${baseUrl}/api/procedures/${createBody.data.id}`,
      {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          price: 'RM 1,050',
          actorRole: 'Admin',
        }),
      },
    );
    const updateBody = await updateResponse.json();

    assert.equal(updateResponse.status, 200);
    assert.equal(updateBody.data.price, 'RM 1,050');

    const deleteBlockedResponse = await fetch(
      `${baseUrl}/api/procedures/${createBody.data.id}?actorRole=User`,
      { method: 'DELETE' },
    );
    const deleteBlockedBody = await deleteBlockedResponse.json();

    assert.equal(deleteBlockedResponse.status, 403);
    assert.equal(
      deleteBlockedBody.error.message,
      'Owner or Admin required for procedure management.',
    );

    const deleteResponse = await fetch(
      `${baseUrl}/api/procedures/${createBody.data.id}?actorRole=Owner`,
      { method: 'DELETE' },
    );

    assert.equal(deleteResponse.status, 204);
  });

  it('validates required fields', async () => {
    const response = await fetch(`${baseUrl}/api/invoices`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ patient: 'Missing Invoice' }),
    });
    const body = await response.json();

    assert.equal(response.status, 422);
    assert.ok(body.error.details.includes('number is required'));
  });
});

function listen(server) {
  return new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', () => {
      server.off('error', reject);
      resolve();
    });
  });
}
