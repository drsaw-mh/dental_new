# MTD Frontend MVVM Structure

Frontend code is organized by feature:

```text
lib/frontend/
  core/
    api/                  Shared API configuration and HTTP client
  features/
    project_history/
      data/               Repository/data-source layer
      view_models/        UI state and use-case orchestration
```

Views should depend on view models. View models should depend on repositories.
Repositories should be the only frontend layer that talks directly to backend
HTTP endpoints.
