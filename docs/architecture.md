# Architecture

## Repository Layout

```
todo-nodejs-mongo-aca/
├── AGENTS.md                  # LLM agent instructions (start here)
├── azure.yaml                 # azd service + workflow definitions
├── openapi.yaml               # OpenAPI spec for the REST API
├── infra/                     # Bicep infrastructure-as-code
│   ├── main.bicep
│   ├── main.parameters.json
│   └── app/
│       ├── cosmos-role-assignment.bicep
│       └── db-avm.bicep
├── seed/                      # Database seed scripts
├── src/
│   ├── api/                   # Node.js + Express backend
│   │   ├── src/
│   │   │   ├── app.ts         # Express app factory + middleware
│   │   │   ├── index.ts       # Server entry point
│   │   │   ├── config/        # Config loading + Application Insights transport
│   │   │   ├── models/        # Cosmos DB models and factory functions
│   │   │   └── routes/        # Express route handlers + integration tests
│   │   └── config/            # node-config JSON files
│   └── web/                   # React 18 frontend
│       └── src/
│           ├── actions/       # Redux-style action creators
│           ├── components/    # Reusable React components
│           ├── config/        # Runtime config (API base URL, App Insights)
│           ├── layout/        # Page shell (header, sidebar, layout)
│           ├── models/        # TypeScript interfaces and application state
│           ├── pages/         # Top-level page components
│           ├── reducers/      # State reducers (useReducer pattern)
│           ├── services/      # REST API client services
│           └── ux/            # Fluent UI theme and shared styles
└── docs/                      # Agent instruction detail files
```

## Service Boundaries

| Service | Port (local) | Container App (Azure) | Responsibilities |
|---|---|---|---|
| `api` | 3100 | `containerapp` | CRUD REST API, Cosmos DB access, OpenAPI/Swagger UI |
| `web` | 5173 (Vite dev) | `containerapp` | React SPA, calls `api` via `VITE_API_BASE_URL` |

The web frontend is a **pure static SPA** — it has no server-side rendering and no direct database access. All data operations go through the API.

## Data Flow

```
Browser
  └─► React SPA (web)
        └─► axios HTTP calls ─► Express API (api)
                                    └─► Azure Cosmos DB (MongoDB-compatible API)
```

Telemetry flows separately:

```
React SPA ─► Application Insights JS SDK ─► Azure Monitor
Express API ─► applicationinsights Node SDK ─► Azure Monitor
```

## Key Design Decisions

### Cosmos DB Access Pattern
- The API uses the **Azure Cosmos DB SDK for Node.js** (`@azure/cosmos`), not the MongoDB driver.
- Two containers are used: `TodoList` and `TodoItem`, both in the `Todo` database.
- Each container is accessed via factory functions `getTodoListContainer()` and `getTodoItemContainer()` defined in `src/api/src/models/cosmos.ts`.
- Partition keys: `TodoList` uses `/Hash` (same value as `id`); `TodoItem` uses `/listId`.

### Authentication to Cosmos DB
- In production on Azure, the API authenticates to Cosmos DB using **managed identity** via `DefaultAzureCredential` from `@azure/identity`. No connection strings or keys are stored in environment variables for production.
- In local development, a connection string or key can be provided via environment variable.

### CORS Strategy
- CORS is enforced server-side in `app.ts` via the `cors` middleware.
- In `NODE_ENV=development`, all origins are permitted (`*`) to allow local Vite dev server calls.
- In all other environments, only explicitly listed origins are allowed. The list always includes `https://portal.azure.com` and the deployed web Container App URL (injected as `API_ALLOW_ORIGINS`).

### Configuration Loading
- The API uses the `config` npm package. Defaults live in `src/api/config/default.json`; environment variable overrides are declared in `src/api/config/custom-environment-variables.json`.
- The web app reads runtime config from `import.meta.env` (Vite env vars prefixed with `VITE_`).

### State Management (Web)
- The web app uses React's built-in `useReducer` hook with a single application-level context (`TodoContext`). There is **no Redux or external state library**.
- State is defined in `src/web/src/models/applicationState.ts`. Actions are in `src/web/src/actions/`. Reducers are in `src/web/src/reducers/`.

## Environment Variables

### API (`src/api/`)

| Variable | Required | Description |
|---|---|---|
| `AZURE_COSMOS_ENDPOINT` | Yes (prod) | Cosmos DB account endpoint URL |
| `AZURE_COSMOS_DATABASE_NAME` | No | Database name (default: `Todo`) |
| `AZURE_COSMOS_KEY` | No | Account key (dev only; prefer managed identity in prod) |
| `AZURE_COSMOS_CONNECTION_STRING` | No | Connection string (dev alternative) |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | No | App Insights telemetry |
| `API_ALLOW_ORIGINS` | No | Comma-separated list of additional allowed CORS origins |
| `NODE_ENV` | No | Set to `development` to disable CORS restriction |
| `PORT` | No | HTTP listen port (default: `3100`) |

### Web (`src/web/`)

| Variable | Required | Description |
|---|---|---|
| `VITE_API_BASE_URL` | Yes | Base URL for API calls (e.g., `http://localhost:3100`) |
| `VITE_APPLICATIONINSIGHTS_CONNECTION_STRING` | No | App Insights connection string for browser telemetry |
