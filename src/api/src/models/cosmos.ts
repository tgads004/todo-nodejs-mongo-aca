import { CosmosClient, Database, Container } from "@azure/cosmos";
import { DefaultAzureCredential } from "@azure/identity";
import { DatabaseConfig } from "../config/appConfig";
import { logger } from "../config/observability";

let cosmosClient: CosmosClient;
let database: Database;
let todoListContainer: Container;
let todoItemContainer: Container;

export const configureCosmos = async (config: DatabaseConfig) => {
    try {
        logger.info("Configuring Cosmos DB client...");
        
        const credential = new DefaultAzureCredential();
        cosmosClient = new CosmosClient({
            endpoint: config.endpoint,
            aadCredentials: credential
        });

        database = cosmosClient.database(config.databaseName);
        todoListContainer = database.container("TodoList");
        todoItemContainer = database.container("TodoItem");

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
