# MTD Backend Structure

Backend code is organized separately from Flutter:

```text
backend/
  data/                   Database/store seed and persisted JSON collections
  lib/                    Business logic, resource definitions, HTTP helpers
  test/                   Node API tests
  server.js               REST API entrypoint
```

Project History is stored through `/api/projectHistory` and persisted to:

```text
backend/data/project-history.json
```
