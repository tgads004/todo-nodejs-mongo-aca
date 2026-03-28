
import { CosmosClient, Container, Database } from "@azure/cosmos";
import { DefaultAzureCredential } from "@azure/identity";
import { Agent as HttpsAgent } from "https";
import { DatabaseConfig } from "../config/appConfig";
import { logger } from "../config/observability";

const TODO_LIST_CONTAINER_NAME = "TodoList";
const TODO_ITEM_CONTAINER_NAME = "TodoItem";

let cosmosClient: CosmosClient;
let database: Database;
let todoListContainer: Container;
let todoItemContainer: Container;

export const configureCosmos = async (config: DatabaseConfig) => {
    // Skip Cosmos DB configuration in test environment
    if (process.env.NODE_ENV === "test") {
        logger.info("Skipping Cosmos DB configuration in test environment");
        return;
    }

    try {
        cosmosClient = createCosmosClient(config);
        database = await initializeDatabase(cosmosClient, config);
        todoListContainer = database.container(TODO_LIST_CONTAINER_NAME);
        todoItemContainer = database.container(TODO_ITEM_CONTAINER_NAME);

        await database.read();
        logger.info("Cosmos DB connected successfully!");

    } catch (err) {
        logger.error(`Cosmos DB connection error: ${err}`);
        throw err;
    }
};

export const getTodoListContainer = () => {
    if (process.env.NODE_ENV === "test") {
        // Return a mock container for testing
        return createMockContainer();
    }
    if (!todoListContainer) {
        throw new Error("Cosmos DB not initialized. Call configureCosmos first.");
    }
    return todoListContainer;
};

export const getTodoItemContainer = () => {
    if (process.env.NODE_ENV === "test") {
        // Return a mock container for testing
        return createMockContainer();
    }
    if (!todoItemContainer) {
        throw new Error("Cosmos DB not initialized. Call configureCosmos first.");
    }
    return todoItemContainer;
};

// Mock container for testing
const mockData = new Map<string, any>();

const createMockContainer = () => ({
    items: {
        create: async (item: any) => {
            const resource = {
                id: `mock-${Date.now()}-${Math.random()}`,
                ...item,
                createdDate: new Date(),
                updatedDate: new Date()
            };
            mockData.set(resource.id, resource);
            return { resource };
        },
        readAll: () => ({
            fetchAll: async () => ({
                resources: Array.from(mockData.values())
            })
        }),
        query: (spec: any) => ({
            fetchAll: async () => {
                const resources = Array.from(mockData.values());
                // Simple query implementation for tests
                if (spec.query && spec.query.includes("listId")) {
                    const listIdParam = spec.parameters?.find((p: any) => p.name === "@listId");
                    if (listIdParam) {
                        return {
                            resources: resources.filter((r: any) => r.listId === listIdParam.value)
                        };
                    }
                }
                return { resources };
            }
        }),
    },
    item: (id: string) => ({
        read: async () => ({
            resource: mockData.get(id) || null
        }),
        replace: async (item: any) => {
            const resource = { ...item, updatedDate: new Date() };
            mockData.set(id, resource);
            return { resource };
        },
        delete: async () => {
            mockData.delete(id);
            return {};
        },
    }),
});

export const getCosmosClient = () => {
    if (!cosmosClient) {
        throw new Error("Cosmos DB not initialized. Call configureCosmos first.");
    }
    return cosmosClient;
};

export const clearMockData = () => {
    if (process.env.NODE_ENV === "test") {
        mockData.clear();
    }
};

const createCosmosClient = (config: DatabaseConfig): CosmosClient => {
    const agent = createLocalEmulatorAgent(config);

    if (config.connectionString) {
        logger.info("Connecting to Cosmos DB using connection string...");
        return new CosmosClient({
            connectionString: config.connectionString,
            agent,
        });
    }

    if (config.key) {
        logger.info("Connecting to Cosmos DB using endpoint and key...");
        return new CosmosClient({
            endpoint: config.endpoint,
            key: config.key,
            agent,
        });
    }

    logger.info("Connecting to Cosmos DB using managed identity...");

    const credential = new DefaultAzureCredential();

    return new CosmosClient({
        endpoint: config.endpoint,
        aadCredentials: credential,
        agent,
    });
};

const createLocalEmulatorAgent = (config: DatabaseConfig) => {
    if (!isEmulatorConfig(config)) {
        return undefined;
    }

    logger.info("Using local HTTPS agent for Cosmos DB emulator.");

    return new HttpsAgent({
        rejectUnauthorized: false,
    });
};

const initializeDatabase = async (client: CosmosClient, config: DatabaseConfig): Promise<Database> => {
    if (isEmulatorConfig(config)) {
        logger.info(`Ensuring local Cosmos DB emulator database '${config.databaseName}' exists...`);

        const { database: initializedDatabase } = await client.databases.createIfNotExists({
            id: config.databaseName,
        });

        await initializedDatabase.containers.createIfNotExists({
            id: TODO_LIST_CONTAINER_NAME,
            partitionKey: {
                paths: ["/id"],
            },
        });

        await initializedDatabase.containers.createIfNotExists({
            id: TODO_ITEM_CONTAINER_NAME,
            partitionKey: {
                paths: ["/id"],
            },
        });

        return initializedDatabase;
    }

    return client.database(config.databaseName);
};

const isEmulatorConfig = (config: DatabaseConfig): boolean => {
    const endpoint = config.endpoint || extractEndpointFromConnectionString(config.connectionString);

    if (!endpoint) {
        return false;
    }

    return endpoint.includes("localhost") || endpoint.includes("127.0.0.1");
};

const extractEndpointFromConnectionString = (connectionString?: string): string => {
    if (!connectionString) {
        return "";
    }

    const endpointSegment = connectionString
        .split(";")
        .find((segment) => segment.trim().toLowerCase().startsWith("accountendpoint="));

    return endpointSegment?.split("=")[1]?.trim() || "";
};