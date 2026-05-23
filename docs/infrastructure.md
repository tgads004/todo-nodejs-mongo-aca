# Infrastructure

Standards and conventions for Azure infrastructure and deployment in this project.

## Overview

Infrastructure is defined with **Azure Bicep** and provisioned via the **Azure Developer CLI (`azd`)**. All infrastructure code lives in the `infra/` directory.

```
infra/
├── main.bicep               # Root Bicep template (subscription scope)
├── main.parameters.json     # Parameter file (azd populates values from env)
├── abbreviations.json       # Resource name prefix conventions
└── app/
    ├── cosmos-role-assignment.bicep  # Managed identity → Cosmos DB RBAC
    └── db-avm.bicep                  # Cosmos DB account (via AVM module)
```

## Provisioned Resources

| Resource | Purpose |
|---|---|
| Resource Group | Container for all environment resources |
| Azure Container Apps Environment | Shared ACA environment for `api` and `web` |
| Azure Container Registry (Basic SKU) | Stores Docker images for both services |
| Azure Cosmos DB (MongoDB API) | Database backend for the API |
| Azure Key Vault | Secrets management |
| Azure Monitor / Log Analytics Workspace | Centralized log aggregation |
| Azure Application Insights | APM and distributed tracing |
| Azure API Management *(optional)* | API gateway (enabled via `USE_APIM=true`) |

## Services Defined in `azure.yaml`

```yaml
services:
  web:
    project: ./src/web
    language: js
    host: containerapp
  api:
    project: ./src/api
    language: js
    host: containerapp
```

Both services are containerized and deployed to Azure Container Apps. `azd` builds Docker images, pushes them to ACR, and updates the Container App revisions.

## Bicep Conventions

- **Subscription scope.** `main.bicep` uses `targetScope = 'subscription'`. All resource group-scoped resources are defined in modules deployed with `scope: rg`.
- **Azure Verified Modules (AVM).** Use AVM public registry modules (`br/public:avm/...`) for shared infrastructure patterns instead of writing raw resource definitions. Check `main.bicep` for existing usage before adding a new resource type.
- **Resource naming.** Use the `abbreviations.json` file for resource type prefixes combined with a `resourceToken` (derived from subscription ID + environment name + location). Never hardcode resource names.
- **Tags.** Apply `tags = { 'azd-env-name': environmentName }` to every top-level resource and module.
- **Optional features via parameters.** Feature flags (e.g., `useAPIM`) are controlled by Bicep parameters backed by environment variables, not by conditional file inclusion.
- **No secrets in Bicep outputs.** Never output connection strings, keys, or passwords from Bicep templates. Use Key Vault references or managed identity instead.

### Parameter Patterns

Parameters that may be overridden have defaults:

```bicep
param apiContainerAppName string = ''   // empty = auto-generated name
param useAPIM bool = false              // opt-in feature flag
```

`main.parameters.json` maps `azd` environment variables to Bicep parameters using the `${VARIABLE_NAME}` syntax:

```json
{
  "parameters": {
    "environmentName": { "value": "${AZURE_ENV_NAME}" },
    "location":        { "value": "${AZURE_LOCATION}" }
  }
}
```

## Authentication and Identity

- Both Container Apps (`api` and `web`) are assigned **user-assigned managed identities**.
- The API's managed identity is granted the **Cosmos DB Built-in Data Contributor** role via `infra/app/cosmos-role-assignment.bicep`. No connection strings or account keys are needed in production.
- The managed identity is also granted access to Key Vault for any secrets that cannot be expressed as Cosmos DB roles.

**Do not** add Cosmos DB keys or connection strings to Container App environment variable secrets. Managed identity is the required authentication path in production.

## Environment Variables in Azure

`azd` captures Bicep output values and injects them as environment variables into the deployed Container Apps. Mapping is done in `main.bicep` via the Container App module's `env` parameter. The API container expects:

| Env Var | Source |
|---|---|
| `AZURE_COSMOS_ENDPOINT` | Cosmos DB account endpoint (Bicep output) |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | App Insights connection string (Bicep output) |
| `API_ALLOW_ORIGINS` | Web Container App FQDN (Bicep output) |

The web container expects:

| Env Var | Source |
|---|---|
| `VITE_API_BASE_URL` | API Container App FQDN (injected at build time via predeploy hook) |
| `VITE_APPLICATIONINSIGHTS_CONNECTION_STRING` | App Insights connection string (injected at build time) |

The Vite variables are injected at **build time** (not runtime) via the `predeploy` hook in `azure.yaml`, which writes a `.env.local` file before `azd` builds the Docker image.

## Deployment Workflow

### First-time provisioning and deployment

```bash
azd auth login          # Authenticate with Azure
azd up                  # Provision infrastructure + build + deploy
```

### Code-only redeployment (infrastructure already exists)

```bash
azd deploy              # Build + push images + update Container Apps
azd deploy --service api  # Deploy only the API
azd deploy --service web  # Deploy only the web frontend
```

### Supported Azure Regions

Only the following regions are supported due to Container Apps availability:

- Australia East, Brazil South, Canada Central, Central US, East Asia
- East US, East US 2, Germany West Central, Japan East, Korea Central
- North Central US, North Europe, South Central US, UK South
- West Europe, West US

Attempting to deploy to an unsupported region will cause the provision step to fail.

## Optional: API Management

To enable Azure API Management as a gateway in front of the API:

```bash
azd env set USE_APIM true
azd up
```

When enabled, `main.bicep` deploys an APIM instance (Consumption SKU by default) and routes traffic through it. The API's CORS configuration remains unchanged — APIM does not bypass server-side CORS checks.

## CI/CD

GitHub Actions workflows live in `.github/workflows/` and Azure Pipelines definitions in `.azdo/pipelines/`. These workflows:

1. Run `azd provision` to ensure infrastructure is up to date.
2. Run `azd deploy` to push new images.

Pipeline secrets required: `AZURE_CREDENTIALS` (service principal JSON) or equivalent federated identity configuration. Never store secrets in the workflow YAML files.

## Local Development Setup

```bash
# 1. Provision infrastructure (only needed once or when infra changes)
azd provision

# 2. Load environment variables into your shell from .azure/<env>/.env
azd env get-values > .env && source .env  # Linux/macOS
# or use the VS Code "Start API" / "Start Web" tasks (dotenv task type)

# 3. Start the API (port 3100)
cd src/api && npm run start

# 4. Start the web dev server (port 5173)
cd src/web && npm run dev
```

The VS Code workspace includes launch configurations and tasks (`.vscode/tasks.json`) that automate steps 3 and 4 with environment variable injection via the `dotenv` task type.
