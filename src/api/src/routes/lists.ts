import express, { Request } from "express";
import { PagingQueryParams } from "../routes/common";
import { TodoList, createTodoList } from "../models/todoList";
import { getTodoListContainer } from "../models/cosmos";

const router = express.Router();

type TodoListPathParams = {
    listId: string
}

/**
 * Gets a list of Todo list
 */
router.get("/", async (req: Request<unknown, unknown, unknown, PagingQueryParams>, res) => {
    try {
        const container = getTodoListContainer();
        const skip = req.query.skip ? parseInt(req.query.skip) : 0;
        const top = req.query.top ? parseInt(req.query.top) : 20;
        
        const query = `SELECT * FROM c OFFSET ${skip} LIMIT ${top}`;
        const { resources } = await container.items.query(query).fetchAll();
        
        res.json(resources);
    } catch (err: any) {
        console.error("Error getting todo lists:", err);
        res.status(500).json({ error: "Internal server error" });
    }
});

/**
 * Creates a new Todo list
 */
router.post("/", async (req: Request<unknown, unknown, TodoList>, res) => {
    try {
        const container = getTodoListContainer();
        const list = createTodoList(req.body.name, req.body.description);
        
        const { resource } = await container.items.create(list);
        
        if (!resource) {
            return res.status(500).json({ error: "Failed to create todo list" });
        }
        
        res.setHeader("location", `${req.protocol}://${req.get("Host")}/lists/${resource.id}`);
        res.status(201).json(resource);
    } catch (err: any) {
        console.error("Error creating todo list:", err);
        res.status(500).json({ error: "Internal server error" });
    }
});

/**
 * Gets a Todo list with the specified ID
 */
router.get("/:listId", async (req: Request<TodoListPathParams>, res) => {
    try {
        const container = getTodoListContainer();
        const { resource } = await container.item(req.params.listId, req.params.listId).read();
        
        if (!resource) {
            return res.status(404).send();
        }
        
        res.json(resource);
    } catch (err: any) {
        if (err.code === 404) {
            return res.status(404).send();
        }
        console.error("Error getting todo list:", err);
        res.status(500).json({ error: "Internal server error" });
    }
});

/**
 * Updates a Todo list with the specified ID
 */
router.put("/:listId", async (req: Request<TodoListPathParams, unknown, TodoList>, res) => {
    try {
        const container = getTodoListContainer();
        const list: TodoList = {
            ...req.body,
            id: req.params.listId,
            Hash: req.params.listId, // Partition key must match id
            updatedDate: new Date()
        };

        const { resource } = await container.item(req.params.listId, req.params.listId).replace(list);
        
        res.json(resource);
    } catch (err: any) {
        if (err.code === 404) {
            return res.status(404).send();
        }
        console.error("Error updating todo list:", err);
        res.status(500).json({ error: "Internal server error" });
    }
});

/**
 * Deletes a Todo list with the specified ID
 */
router.delete("/:listId", async (req: Request<TodoListPathParams>, res) => {
    try {
        const container = getTodoListContainer();
        await container.item(req.params.listId, req.params.listId).delete();
        
        res.status(204).send();
    } catch (err: any) {
        if (err.code === 404) {
            return res.status(404).send();
        }
        console.error("Error deleting todo list:", err);
        res.status(500).json({ error: "Internal server error" });
    }
});

export default router;