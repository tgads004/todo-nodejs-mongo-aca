# Node with Typescript Express REST API

## Setup

### Prerequisites

- Node (18.17.1)
- NPM (9.8.1)

### Local Environment

Create a `.env` with the following configuration:

- `AZURE_COSMOS_ENDPOINT` - Cosmos DB endpoint, for the Windows emulator use `https://localhost:8081`
- `AZURE_COSMOS_KEY` - Cosmos DB account key, for the Windows emulator use the well-known emulator key
- `AZURE_COSMOS_CONNECTION_STRING` - Optional alternative to endpoint + key
- `AZURE_COSMOS_DATABASE_NAME` - Cosmos DB database name (default: `todo-db` locally)
- `APPLICATIONINSIGHTS_CONNECTION_STRING` - Azure Application Insights connection string
- `APPLICATIONINSIGHTS_ROLE_NAME` - Azure Application Insights Role name (default: `todo-api-local` locally)

This repo's supported local database path is the native Windows Azure Cosmos DB Emulator. Install and start the emulator, then confirm the local explorer opens at `https://localhost:8081/_explorer/index.html`.

When the API starts against the emulator, it automatically creates the `todo-db` database plus the `TodoList` and `TodoItem` containers if they do not already exist.

To seed sample local data after the emulator is running, use:

```bash
npm run seed:local
```

If the emulator certificate is not trusted correctly on your machine, uncomment `NODE_TLS_REJECT_UNAUTHORIZED=0` in `.env` as a local-only fallback.

### Install Dependencies

Run `npm ci` to install local dependencies

### Build & Compile

Run `npm run build` to build & compile the Typescript code into the `./dist` folder

### Run application

Run `npm start` to start the local development server

Launch browser @ `http://localhost:3100`. The default page hosts the Open API UI where you can try out the API
