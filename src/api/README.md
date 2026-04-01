# Node with Typescript Express REST API

## Setup

### Prerequisites

- Node (18.17.1)
- NPM (9.8.1)

### Local Environment

Create a `.env` with the following configuration:

- `AZURE_COSMOS_CONNECTION_STRING` - Preferred for local emulator usage. If set, the API uses it instead of AAD auth.
- `AZURE_COSMOS_ENDPOINT` - Required when not using `AZURE_COSMOS_CONNECTION_STRING`
- `AZURE_COSMOS_KEY` - Use with `AZURE_COSMOS_ENDPOINT` for local emulator or key-based auth
- `AZURE_COSMOS_DATABASE_NAME` - Cosmos DB database name (default: Todo)
- `AZURE_COSMOS_AUTO_CREATE` - Optional. Set to `true` to create the database and containers on startup. The API enables this automatically when targeting the local emulator.
- `AZURE_COSMOS_SEED_SAMPLE_DATA` - Optional. Set to `true` to create one default list and a few default items, but only when no lists already exist.
- `APPLICATIONINSIGHTS_CONNECTION_STRING` - Azure Application Insights connection string
- `APPLICATIONINSIGHTS_ROLE_NAME` - Azure Application Insights Role name (default: API)

### Cosmos DB Emulator

For the Azure Cosmos DB Emulator, use either the emulator connection string or the endpoint and key exposed by your local emulator instance. A minimal `.env` using the default emulator values looks like:

```env
AZURE_COSMOS_CONNECTION_STRING=AccountEndpoint=https://localhost:8081/;AccountKey=C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLMYhNr8sY6s=;
AZURE_COSMOS_DATABASE_NAME=Todo
AZURE_COSMOS_AUTO_CREATE=true
AZURE_COSMOS_SEED_SAMPLE_DATA=true
NODE_TLS_REJECT_UNAUTHORIZED=0
```

`NODE_TLS_REJECT_UNAUTHORIZED=0` is the simplest local option if you have not trusted the emulator certificate in Windows yet. If you already trust the emulator certificate, you can omit it.

If your local emulator shows a different endpoint or key, use those values instead of the sample above.

### Install Dependencies

Run `npm ci` to install local dependencies

### Build & Compile

Run `npm run build` to build & compile the Typescript code into the `./dist` folder

### Run application

Run `npm start` to start the local development server

Launch browser @ `http://localhost:3100`. The default page hosts the Open API UI where you can try out the API
