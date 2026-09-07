import { nextId, persistProjectHistory, store } from '../data/store.js';

export const resources = {
  users: {
    collection: store.users,
    prefix: 'usr',
    required: ['name', 'role', 'status', 'age', 'phone', 'address'],
    searchable: ['name', 'role', 'status', 'age', 'phone', 'address'],
  },
  doctors: {
    collection: store.doctors,
    prefix: 'doc',
    required: ['name', 'specialty', 'status'],
    searchable: ['name', 'specialty', 'status', 'room'],
  },
  appointments: {
    collection: store.appointments,
    prefix: 'apt',
    required: ['patient', 'time', 'procedure', 'doctor'],
    searchable: ['patient', 'time', 'procedure', 'doctor', 'status'],
  },
  bookingSlots: {
    collection: store.bookingSlots,
    prefix: 'slot',
    required: ['time', 'room', 'doctor', 'type', 'status'],
    searchable: ['time', 'room', 'doctor', 'type', 'status'],
  },
  invoices: {
    collection: store.invoices,
    prefix: 'inv',
    required: ['patient', 'number', 'method', 'status', 'amount'],
    searchable: ['patient', 'number', 'method', 'status'],
  },
  payments: {
    collection: store.payments,
    prefix: 'pay',
    required: [
      'patient',
      'invoiceNumber',
      'method',
      'amount',
      'paidDate',
      'reference',
    ],
    searchable: ['patient', 'invoiceNumber', 'method', 'paidDate', 'reference'],
  },
  pharmacy: {
    collection: store.pharmacy,
    prefix: 'med',
    required: ['name', 'category', 'stock', 'unit', 'batch', 'expiry', 'status'],
    searchable: ['name', 'category', 'batch', 'expiry', 'status'],
  },
  pharmacyPayments: {
    collection: store.pharmacyPayments,
    prefix: 'rxp',
    required: ['patient', 'invoiceNumber', 'method', 'status', 'amount'],
    searchable: ['patient', 'invoiceNumber', 'method', 'status'],
  },
  followUps: {
    collection: store.followUps,
    prefix: 'fol',
    required: ['patient', 'reason', 'due', 'channel', 'priority'],
    searchable: ['patient', 'reason', 'due', 'channel', 'priority'],
  },
  procedures: {
    collection: store.procedures,
    prefix: 'pro',
    required: ['name', 'price', 'estimate'],
    searchable: ['name', 'stage', 'doctor', 'category', 'subcategory'],
  },
  projects: {
    collection: store.projects,
    prefix: 'prj',
    required: ['projectId', 'name', 'owner', 'deadline'],
    searchable: ['projectId', 'name', 'owner', 'deadline'],
  },
  projectHistory: {
    collection: store.projectHistory,
    prefix: 'ph',
    required: ['patient', 'number', 'method', 'status', 'amount'],
    searchable: ['patient', 'number', 'method', 'status', 'procedure', 'doctor'],
    afterChange: persistProjectHistory,
  },
};

const creatableUserRoles = new Set([
  'User',
  'Doctor',
  'Cashier',
  'Admin',
  'Owner',
]);
const elevatedCreatorRoles = new Set(['Admin', 'Owner']);
const procedureManagerRoles = new Set(['Admin', 'Owner']);

export function prepareCreateBody(resourceName, body) {
  if (resourceName === 'procedures') {
    return prepareProcedureBody(body);
  }

  if (resourceName !== 'users') {
    return { body };
  }

  const { createdByRole = 'User', ...userBody } = body;

  if (!creatableUserRoles.has(userBody.role)) {
    return {
      errors: [`role must be one of ${[...creatableUserRoles].join(', ')}`],
    };
  }

  if (userBody.role !== 'User' && !elevatedCreatorRoles.has(createdByRole)) {
    return { forbidden: 'Admin or Owner required for this role.' };
  }

  return { body: userBody };
}

export function prepareUpdateBody(resourceName, body) {
  if (resourceName === 'procedures') {
    return prepareProcedureBody(body);
  }

  return { body };
}

export function authorizeDelete(resourceName, searchParams) {
  if (resourceName !== 'procedures') {
    return {};
  }

  const actorRole = searchParams.get('actorRole') ?? 'User';
  if (!procedureManagerRoles.has(actorRole)) {
    return { forbidden: 'Owner or Admin required for procedure management.' };
  }

  return {};
}

function prepareProcedureBody(body) {
  const { actorRole = 'User', ...procedureBody } = body;

  if (!procedureManagerRoles.has(actorRole)) {
    return { forbidden: 'Owner or Admin required for procedure management.' };
  }

  return { body: procedureBody };
}

export function listResource(config, searchParams) {
  const role = searchParams.get('role');
  const query = searchParams.get('q')?.toLowerCase();

  return config.collection.filter((item) => {
    if (role && item.role !== role) {
      return false;
    }

    if (!query) {
      return true;
    }

    return config.searchable.some((key) =>
      String(item[key] ?? '').toLowerCase().includes(query),
    );
  });
}

export function createResource(config, body) {
  const errors = validateRequired(config.required, body);
  if (errors.length) {
    return { errors };
  }

  const item = {
    id: nextId(config.prefix),
    ...body,
  };

  config.collection.unshift(item);
  config.afterChange?.();
  return { item };
}

export function updateResource(config, id, body) {
  const index = config.collection.findIndex((item) => item.id === id);
  if (index === -1) {
    return { notFound: true };
  }

  config.collection[index] = {
    ...config.collection[index],
    ...body,
    id,
  };

  config.afterChange?.();
  return { item: config.collection[index] };
}

export function deleteResource(config, id) {
  const index = config.collection.findIndex((item) => item.id === id);
  if (index === -1) {
    return false;
  }

  config.collection.splice(index, 1);
  config.afterChange?.();
  return true;
}

function validateRequired(fields, body) {
  return fields
    .filter((field) => body[field] === undefined || body[field] === '')
    .map((field) => `${field} is required`);
}
