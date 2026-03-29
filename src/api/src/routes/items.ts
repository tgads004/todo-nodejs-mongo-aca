import express from "express";
import { Request } from "express";
import { PagingQueryParams } from "../routes/common";
import { TodoItem, createTodoItem, TodoItemState } from "../models/todoItem";
import { getTodoItemContainer } from "../models/cosmos";

const router = express.Router({ mergeParams: true });

type TodoItemPathParams = {
    listId: string
    itemId: string
    state?: TodoItemState
}

/**
 * Gets a list of Todo item within a list
 */
router.get("/", async (req: Request<TodoItemPathParams, unknown, unknown, PagingQueryParams>, res) => {
    try {
        const container = getTodoItemContainer();
        const skip = req.query.skip ? parseInt(req.query.skip) : 0;
        const top = req.query.top ? parseInt(req.query.top) : 20;
        
        const query = `SELECT * FROM c WHERE c.listId = @listId OFFSET ${skip} LIMIT ${top}`;
        const { resources } = await container.items.query({
            query,
            parameters: [{ name: "@listId", value: req.params.listId }]
        }).fetchAll();
        
        res.json(resources);
    } catch (err: any) {
        console.error("Error getting todo items:", err);
        res.status(500).json({ error: "Internal server error" });
    }
});

/**
 * Creates a new Todo item within a list
 */
router.post("/", async (req: Request<TodoItemPathParams, unknown, TodoItem>, res) => {
    try {
        const container = getTodoItemContainer();
        const item = createTodoItem(req.params.listId, req.body.name, req.body.description);
        
        const { resource } = await container.items.create(item);
        
        if (!resource) {
            return res.status(500).json({ error: "Failed to create todo item" });
        }
        
        res.setHeader("location", `${req.protocol}://${req.get("Host")}/lists/${req.params.listId}/${resource.id}`);
        res.status(201).json(resource);
    } catch (err: any) {
        console.error("Error creating todo item:", err);
        res.status(500).json({ error: "Internal server error" });
    }
});

/**
 * Gets a Todo item with the specified ID within a list
 */
router.get("/:itemId", async (req: Request<TodoItemPathParams>, res) => {
    try {
        const container = getTodoItemContainer();
        const { resource } = await container.item(req.params.itemId, req.params.itemId).read();
        
        if (!resource || resource.listId !== req.params.listId) {
            return res.status(404).send();
        }
        
        res.json(resource);
    } catch (err: any) {
        if (err.code === 404) {
            return res.status(404).send();
        }
        console.error("Error getting todo item:", err);
        res.status(500).json({ error: "Internal server error" });
    }
});

/**
 * Updates a Todo item with the specified ID within a list
 */
router.put("/:itemId", async (req: Request<TodoItemPathParams, unknown, TodoItem>, res) => {
    try {
        const container = getTodoItemContainer();
        const item: TodoItem = {
            ...req.body,
            id: req.params.itemId,
            listId: req.params.listId,
            Hash: req.params.itemId, // Partition key must match id
            updatedDate: new Date()
        };

        const { resource } = await container.item(req.params.itemId, req.params.itemId).replace(item);
        
        res.json(resource);
    } catch (err: any) {
        if (err.code === 404) {
            return res.status(404).send();
        }
        console.error("Error updating todo item:", err);
        res.status(500).json({ error: "Internal server error" });
    }
});

/**
 * Deletes a Todo item with the specified ID within a list
 */
router.delete("/:itemId", async (req, res) => {
    try {
        const container = getTodoItemContainer();
        await container.item(req.params.itemId, req.params.itemId).delete();
        
        res.status(204).send();
    } catch (err: any) {
        if (err.code === 404) {
            return res.status(404).send();
        }
        console.error("Error deleting todo item:", err);
        res.status(500).json({ error: "Internal server error" });
    }
});

/**
 * Get a list of items by state
 */
router.get("/state/:state", async (req: Request<TodoItemPathParams, unknown, unknown, PagingQueryParams>, res) => {
    try {
        const container = getTodoItemContainer();
        const skip = req.query.skip ? parseInt(req.query.skip) : 0;
        const top = req.query.top ? parseInt(req.query.top) : 20;
        
        const query = `SELECT * FROM c WHERE c.listId = @listId AND c.state = @state OFFSET ${skip} LIMIT ${top}`;
        const { resources } = await container.items.query({
            query,
            parameters: [
                { name: "@listId", value: req.params.listId },
                { name: "@state", value: req.params.state as string }
            ]
        }).fetchAll();
        
        res.json(resources);
    } catch (err: any) {
        console.error("Error getting todo items by state:", err);
        res.status(500).json({ error: "Internal server error" });
    }
});

router.put("/state/:state", async (req: Request<TodoItemPathParams, unknown, string[]>, res) => {
    try {
        const container = getTodoItemContainer();
        const completedDate = req.params.state === TodoItemState.Done ? new Date() : undefined;

        const updatePromises = req.body.map(async (id: string) => {
            const { resource } = await container.item(id, id).read();
            if (resource && resource.listId === req.params.listId) {
                resource.state = req.params.state;
                resource.completedDate = completedDate;
                resource.updatedDate = new Date();
                resource.Hash = resource.id; // Ensure partition key is consistent
                await container.item(id, id).replace(resource);
            }
        });

        await Promise.all(updatePromises);

        res.status(204).send();
    } catch (err: any) {
        console.error("Error updating todo items state:", err);
        res.status(500).json({ error: "Internal server error" });
    }
});

export default router;