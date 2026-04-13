import https from "https";
import { CosmosClient, Database, Container } from "@azure/cosmos";
import { DefaultAzureCredential } from "@azure/identity";
import { DatabaseConfig } from "../config/appConfig";
import { logger } from "../config/observability";
import { createDefaultTodoItems, createDefaultTodoList } from "./sampleData";

let cosmosClient: CosmosClient;
let database: Database;
let todoListContainer: Container;
let todoItemContainer: Container;

const databaseId = "Todo";
const todoListContainerId = "TodoList";
const todoItemContainerId = "TodoItem";

export const configureCosmos = async (config: DatabaseConfig) => {
    try {
        logger.info("Configuring Cosmos DB client...");

        cosmosClient = createCosmosClient(config);

        const shouldAutoCreate = Boolean(config.autoCreate) || isCosmosEmulatorConfig(config);

        if (shouldAutoCreate) {
            logger.info(`Ensuring Cosmos DB database '${config.databaseName}' and containers exist...`);
            const databaseResponse = await cosmosClient.databases.createIfNotExists({
                id: config.databaseName || databaseId,
            });
            database = databaseResponse.database;

            const todoListResponse = await database.containers.createIfNotExists({
                id: todoListContainerId,
                partitionKey: {
                    paths: ["/Hash"],
                },
            });

            const todoItemResponse = await database.containers.createIfNotExists({
                id: todoItemContainerId,
                partitionKey: {
                    paths: ["/Hash"],
                },
            });

            todoListContainer = todoListResponse.container;
            todoItemContainer = todoItemResponse.container;
        } else {
            database = cosmosClient.database(config.databaseName);
            todoListContainer = database.container(todoListContainerId);
            todoItemContainer = database.container(todoItemContainerId);
        }

        if (config.seedSampleData) {
            await seedSampleDataIfEmpty();
        }

        logger.info("Cosmos DB client configured successfully!");
    }
    catch (err) {
        logger.error(`Cosmos DB client configuration error: ${err}`);
        throw err;
    }
};

export const getTodoListContainer = (): Container => {
    if (!todoListContainer) {
        throw new Error("Cosmos DB client not configured. Call configureCosmos first.");
    }
    return todoListContainer;
};

export const getTodoItemContainer = (): Container => {
    if (!todoItemContainer) {
        throw new Error("Cosmos DB client not configured. Call configureCosmos first.");
    }
    return todoItemContainer;
};

const createCosmosClient = (config: DatabaseConfig): CosmosClient => {
    if (config.connectionString) {
        logger.info("Using Cosmos DB connection string authentication.");
        return new CosmosClient(config.connectionString);
    }

    if (config.endpoint && config.key) {
        logger.info("Using Cosmos DB endpoint and key authentication.");
        const clientOptions: ConstructorParameters<typeof CosmosClient>[0] = {
            endpoint: config.endpoint,
            key: config.key,
        };
        // Node.js 20's native fetch (undici) does not reliably honour
        // NODE_TLS_REJECT_UNAUTHORIZED at runtime.  Pass a custom agent
        // so the emulator's self-signed cert is accepted without hanging.
        if (isCosmosEmulatorConfig(config)) {
            (clientOptions as any).agent = new https.Agent({ rejectUnauthorized: false });
        }
        return new CosmosClient(clientOptions);
    }

    if (!config.endpoint) {
        throw new Error("Cosmos DB endpoint is required when AZURE_COSMOS_CONNECTION_STRING is not set.");
    }

    logger.info("Using Cosmos DB AAD authentication.");
    const credential = new DefaultAzureCredential();
    return new CosmosClient({
        endpoint: config.endpoint,
        aadCredentials: credential,
    });
};

const isCosmosEmulatorConfig = (config: DatabaseConfig): boolean => {
    const endpoint = config.endpoint || getEndpointFromConnectionString(config.connectionString);

    if (!endpoint) {
        return false;
    }

    try {
        const url = new URL(endpoint);
        return url.hostname === "localhost" || url.hostname === "127.0.0.1";
    } catch {
        return endpoint.includes("localhost") || endpoint.includes("127.0.0.1");
    }
};

const getEndpointFromConnectionString = (connectionString?: string): string | undefined => {
    if (!connectionString) {
        return undefined;
    }

    const accountEndpoint = connectionString
        .split(";")
        .find((segment) => segment.toLowerCase().startsWith("accountendpoint="));

    return accountEndpoint?.split("=")[1];
};

const seedSampleDataIfEmpty = async (): Promise<void> => {
    const existingLists = await todoListContainer.items
        .query({
            query: "SELECT TOP 1 c.id FROM c",
        })
        .fetchAll();

    if (existingLists.resources.length > 0) {
        logger.info("Skipping sample data seed because todo lists already exist.");
        return;
    }

    const defaultList = createDefaultTodoList();

    await todoListContainer.items.create(defaultList);

    const sampleItems = createDefaultTodoItems(defaultList.id);
    await Promise.all(sampleItems.map((item) => todoItemContainer.items.create(item)));

    logger.info(`Seeded sample data with default list '${defaultList.name}' and ${sampleItems.length} items.`);
};

