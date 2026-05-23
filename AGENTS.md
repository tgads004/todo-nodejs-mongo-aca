# Agent Instructions — todo-nodejs-mongo-aca


**BEFORE making any changes:** Read this file AND every markdown file in `/docs/`in full. Do not modify, create, or delete any code until all standards files have been read.  ALWAYS follow these instructions when reading, writing, or modifying any code in this repository.

## Project at a Glance

A full-stack **ToDo** application deployed to **Azure Container Apps** using the **Azure Developer CLI (azd)**. It consists of:

| Layer | Technology |
|---|---|
| Frontend | React 18 + TypeScript + Vite + Fluent UI |
| Backend API | Node.js + TypeScript + Express |
| Database | Azure Cosmos DB (MongoDB-compatible API) |
| Infrastructure | Azure Bicep, provisioned via `azd` |
| Observability | Azure Application Insights |
| Testing | Jest + Supertest (API integration tests) |
| Containers | Docker (both services containerized) |

## Detailed Standards

Agent instruction details are split into modular documents inside `/docs/`directory. ALWAYS read the relevant file BEFORE modifying or generating code in that area.

| Document | Scope |
|---|---|
| [docs/architecture.md](docs/architecture.md) | Repo layout, service boundaries, data flow |
| [docs/api-standards.md](docs/api-standards.md) | Express API coding conventions, Cosmos DB access, error handling |
| [docs/web-standards.md](docs/web-standards.md) | React/Vite frontend conventions, state management, Fluent UI usage |
| [docs/testing-standards.md](docs/testing-standards.md) | Jest + Supertest patterns, test organization, coverage expectations |
| [docs/infrastructure.md](docs/infrastructure.md) | Bicep/azd conventions, environment variables, deployment workflow |
| [docs/auth-standards.md](docs/auth-standards.md) | Microsoft Entra ID / MSAL authentication, API token validation |
| [docs/ui-components.md](docs/ui-components.md) | Fluent UI component requirements, theming, and styling rules |

## Non-Negotiable Rules

These rules apply everywhere in the codebase and override any other preference:

1. **TypeScript only.** Never introduce plain `.js` files inside `src/`. All source code is TypeScript.
2. **Strict typing.** Avoid `any` except in `catch` blocks where the error type is unknown — annotate those as `catch (err: any)`.
3. **No secrets in source.** Connection strings, keys, and credentials are always resolved from environment variables or Azure Key Vault — never hardcoded.
4. **CORS is intentional.** The CORS configuration in `src/api/src/app.ts` is security-critical. Do not loosen it without explicit instruction. In production, allowed origins must be explicitly enumerated.
5. **Lint must pass.** Run `npm run lint` in both `src/api/` and `src/web/`after every change. Fix all errors before finishing — do not suppress or skip lint failures.
6. **Tests must pass.** Run `npm test` inside `src/api/` before declaring API changes complete.
7. **Do not commit `.env` files or `*.env.local` files.** These are already gitignored.
8. **Follow existing file structure.** Place new API route files in `src/api/src/routes/`, models in `src/api/src/models/`, and configuration in `src/api/src/config/`. Place new web components in `src/web/src/components/`.
9. **Install before importing.** When introducing a package not already listed in `package.json`, run `npm install <package-name>` in the correct service directory (`src/api/` or `src/web/`) before writing any code that imports it.

## Key Commands

```bash
# Install dependencies
cd src/api && npm install
cd src/web && npm install

# Lint
cd src/api && npm run lint
cd src/web && npm run lint

# Build
cd src/api && npm run build
cd src/web && npm run build

# Test (API only — integration tests)
cd src/api && npm test

# Run locally (requires .env from azd or manual setup)
cd src/api && npm run start
cd src/web && npm run dev

# Provision + deploy to Azure
azd up

# Deploy code changes only (infrastructure already provisioned)
azd deploy
```
