import { createApp } from "./app";
import { logger } from "./config/observability";

const main = async () => {
    const app = await createApp();
    const port = process.env.FUNCTIONS_CUSTOMHANDLER_PORT || process.env.PORT || 3100;
    const localUrl = `http://localhost:${port}`;

    app.listen(port, () => {
        logger.info(`Local API ready at ${localUrl}. Swagger UI is available at ${localUrl}/`);
    });
};

main();