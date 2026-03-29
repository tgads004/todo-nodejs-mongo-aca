export enum TodoItemState {
    Todo = "todo",
    InProgress = "inprogress",
    Done = "done"
}

export type TodoItem = {
    id: string
    listId: string
    name: string
    state: TodoItemState
    description?: string
    dueDate?: Date
    completedDate?: Date
    createdDate?: Date
    updatedDate?: Date
    Hash?: string
}

export const createTodoItem = (listId: string, name: string, description?: string): TodoItem => {
    const now = new Date();
    const id = generateId();
    return {
        id,
        listId,
        name,
        description,
        state: TodoItemState.Todo,
        createdDate: now,
        updatedDate: now,
        Hash: id // Partition key for Cosmos DB - same as id for simplicity
    };
};

const generateId = (): string => {
    return Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
};