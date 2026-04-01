import { TodoItem, TodoItemState, createTodoItem } from "./todoItem";
import { TodoList, createTodoList } from "./todoList";

export const createDefaultTodoList = (): TodoList => {
    return createTodoList(
        "Getting started",
        "Sample tasks created automatically for local development."
    );
};

export const createDefaultTodoItems = (listId: string): TodoItem[] => {
    const firstItem = createTodoItem(
        listId,
        "Verify the API is running",
        "Open the Swagger UI and confirm the service responds."
    );

    const secondItem = {
        ...createTodoItem(
            listId,
            "Create your first custom list",
            "Use the UI or POST /lists to add your own list."
        ),
        state: TodoItemState.InProgress,
    };

    const thirdItem = {
        ...createTodoItem(
            listId,
            "Connect Playwright tests",
            "Point your local tests at the emulator-backed API."
        ),
        state: TodoItemState.Done,
        completedDate: new Date(),
    };

    return [firstItem, secondItem, thirdItem];
};