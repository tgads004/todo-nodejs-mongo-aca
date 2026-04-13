import express from "express";
import { configureApp } from "./app";
import { logger } from "./config/observability";

const main = async () => {
    const port = process.env.FUNCTIONS_CUSTOMHANDLER_PORT || process.env.PORT || 3100;
    const localUrl = `http://localhost:${port}`;
    const app = express();

    // Start listening immediately so Container Apps startup probe succeeds
    // before async initialization (Key Vault, Cosmos DB) completes
    app.listen(port, () => {
        logger.info(`Server starting at ${localUrl}...`);
    });

    try {
        await configureApp(app);
        logger.info(`API ready at ${localUrl}. Swagger UI is available at ${localUrl}/`);
    } catch (err) {
        logger.error(`Initialization error – API running in degraded mode: ${err}`);
        // Do not exit: keep the server alive so liveness probes pass and logs remain accessible
    }
};

main();