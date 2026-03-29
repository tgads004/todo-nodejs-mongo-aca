export type TodoList = {
    id: string
    name: string
    description?: string
    createdDate?: Date
    updatedDate?: Date
    Hash?: string
}

export const createTodoList = (name: string, description?: string): TodoList => {
    const now = new Date();
    const id = generateId();
    return {
        id,
        name,
        description,
        createdDate: now,
        updatedDate: now,
        Hash: id // Partition key for Cosmos DB - same as id for simplicity
    };
};

const generateId = (): string => {
    return Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
};