export interface ObservabilityConfig {
    connectionString: string
    roleName: string
}

export interface DatabaseConfig {
    endpoint: string
    databaseName: string
    key?: string
    connectionString?: string
    autoCreate?: boolean
    seedSampleData?: boolean
}

export interface AppConfig {
    observability: ObservabilityConfig
    database: DatabaseConfig
}
