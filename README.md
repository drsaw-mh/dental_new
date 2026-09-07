# DentalOps

Cross-platform Flutter dental clinic app with a local Node.js REST backend.

## Frontend

Frontend app code follows an MTD-style MVVM layout under `lib/frontend`:

```text
lib/frontend/
  core/api
  features/<feature>/data
  features/<feature>/view_models
```

Run the Flutter app:

```sh
flutter run
```

Build the web app:

```sh
flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:4000
```

## Backend

Backend code is separate under `backend`:

```text
backend/
  data
  lib
  test
```

Run the API:

```sh
cd backend
npm start
```

The backend runs on:

```text
http://127.0.0.1:4000
```

No install step is required because the backend uses built-in Node.js modules.

## Production Runbook

Build the web app with the API URL that the browser should call:

```sh
flutter build web --release --dart-define=API_BASE_URL=https://api.example.com
```

Start the API with explicit host, port, and allowed frontend origins:

```sh
cd backend
NODE_ENV=production \
API_HOST=0.0.0.0 \
PORT=4000 \
ALLOWED_ORIGINS=https://app.example.com \
npm start
```

Serve the compiled Flutter web bundle:

```sh
cd backend
WEB_HOST=0.0.0.0 WEB_PORT=8080 npm run web
```

Runtime environment variables:

```text
NODE_ENV                    development | production
API_HOST                    API bind host, defaults to 127.0.0.1
PORT                        API port, defaults to 4000
WEB_HOST                    Web bind host, defaults to 127.0.0.1
WEB_PORT                    Web port, defaults to 8080
ALLOWED_ORIGINS             Comma-separated browser origins allowed by CORS
REQUEST_BODY_LIMIT_BYTES    JSON body limit, defaults to 1048576
```

## API

Health:

```text
GET /health
```

Dashboard:

```text
GET /api/dashboard
```

Booking:

```text
GET  /api/booking
POST /api/booking
```

Clinic resources:

```text
GET    /api/users
POST   /api/users
PATCH  /api/users/:id
DELETE /api/users/:id

GET    /api/doctors
GET    /api/appointments
GET    /api/bookingSlots
GET    /api/invoices
GET    /api/projectHistory
POST   /api/projectHistory
GET    /api/followUps
GET    /api/procedures
GET    /api/projects
```

Every resource supports `GET`, `POST`, `PATCH`, and `DELETE`. List endpoints also support search:

```text
GET /api/users?q=doctor
GET /api/users?role=Doctor
```

Run backend tests:

```sh
cd backend
npm test
```
