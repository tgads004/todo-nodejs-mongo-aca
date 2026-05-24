/// <reference types="vite/client" />

import { PublicClientApplication, Configuration } from '@azure/msal-browser';

export interface ApiConfig {
    baseUrl: string
}

export interface ObservabilityConfig {
    connectionString: string
}

export interface AppConfig {
    api: ApiConfig
    observability: ObservabilityConfig
}

const config: AppConfig = {
    api: {
        baseUrl: import.meta.env.VITE_API_BASE_URL || 'http://localhost:3100'
    },
    observability: {
        connectionString: import.meta.env.VITE_APPLICATIONINSIGHTS_CONNECTION_STRING || ''
    }
}

export default config;

const msalConfig: Configuration = {
    auth: {
        clientId: import.meta.env.VITE_AZURE_CLIENT_ID || '',
        authority: import.meta.env.VITE_AZURE_AUTHORITY || 'https://login.microsoftonline.com/common',
        redirectUri: import.meta.env.VITE_REDIRECT_URI || window.location.origin,
    },
    cache: {
        cacheLocation: 'sessionStorage',
    },
};

export const msalInstance = new PublicClientApplication(msalConfig);