// React is required for JSX in Jest test environment
// @ts-expect-error - React is used by JSX transform in tests
import React from 'react';
import { render, screen } from '@testing-library/react';
import { useMsal } from '@azure/msal-react';
import { InteractionStatus, Logger, LogLevel } from '@azure/msal-browser';
import type { AccountInfo, IPublicClientApplication } from '@azure/msal-browser';
import { ThemeProvider } from '@fluentui/react';
import Header from './header';

// Mock the MSAL React hook
jest.mock('@azure/msal-react');
const mockUseMsal = useMsal as jest.MockedFunction<typeof useMsal>;

// Mock Fluent UI's initializeIcons to avoid issues in test environment
jest.mock('@fluentui/react', () => {
  const actual = jest.requireActual('@fluentui/react');
  return {
    ...actual,
    initializeIcons: jest.fn(),
    // Mock FontIcon to avoid initialization issues
    FontIcon: ({ iconName, ...props }: { iconName: string }) => <span data-icon-name={iconName} {...props} />,
  };
});

describe('Header Component', () => {
  const mockLogger = new Logger({
    loggerCallback: () => { },
    piiLoggingEnabled: false,
    logLevel: LogLevel.Error,
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  const renderHeader = () => {
    return render(
      <ThemeProvider>
        <Header />
      </ThemeProvider>
    );
  };

  it('displays display name when account.name is available', () => {
    const mockAccount: Partial<AccountInfo> = {
      name: 'John Doe',
      username: 'john.doe@example.com',
      localAccountId: '123',
      homeAccountId: 'home123',
      environment: 'test',
      tenantId: 'tenant123',
      idTokenClaims: {
        preferred_username: 'johndoe@example.com',
      },
    };

    mockUseMsal.mockReturnValue({
      instance: {} as IPublicClientApplication,
      accounts: [mockAccount as AccountInfo],
      inProgress: InteractionStatus.None,
      logger: mockLogger,
    });

    renderHeader();

    const displayElements = screen.getAllByText('John Doe');
    expect(displayElements.length).toBeGreaterThan(0);
    expect(screen.getByLabelText('Logged in as John Doe')).toBeInTheDocument();
  });

  it('falls back to preferred_username when name is undefined', () => {
    const mockAccount: Partial<AccountInfo> = {
      name: undefined,
      username: 'john.doe@example.com',
      localAccountId: '123',
      homeAccountId: 'home123',
      environment: 'test',
      tenantId: 'tenant123',
      idTokenClaims: {
        preferred_username: 'johndoe@example.com',
      },
    };

    mockUseMsal.mockReturnValue({
      instance: {} as IPublicClientApplication,
      accounts: [mockAccount as AccountInfo],
      inProgress: InteractionStatus.None,
      logger: mockLogger,
    });

    renderHeader();

    const displayElements = screen.getAllByText('johndoe@example.com');
    expect(displayElements.length).toBeGreaterThan(0);
    expect(screen.getByLabelText('Logged in as johndoe@example.com')).toBeInTheDocument();
  });

  it('falls back to username when both name and preferred_username are undefined', () => {
    const mockAccount: Partial<AccountInfo> = {
      name: undefined,
      username: 'john.doe@example.com',
      localAccountId: '123',
      homeAccountId: 'home123',
      environment: 'test',
      tenantId: 'tenant123',
      idTokenClaims: {},
    };

    mockUseMsal.mockReturnValue({
      instance: {} as IPublicClientApplication,
      accounts: [mockAccount as AccountInfo],
      inProgress: InteractionStatus.None,
      logger: mockLogger,
    });

    renderHeader();

    const displayElements = screen.getAllByText('john.doe@example.com');
    expect(displayElements.length).toBeGreaterThan(0);
    expect(screen.getByLabelText('Logged in as john.doe@example.com')).toBeInTheDocument();
  });

  it('shows "User" when all claims are undefined', () => {
    const mockAccount: Partial<AccountInfo> = {
      name: undefined,
      username: undefined,
      localAccountId: '123',
      homeAccountId: 'home123',
      environment: 'test',
      tenantId: 'tenant123',
      idTokenClaims: {},
    };

    mockUseMsal.mockReturnValue({
      instance: {} as IPublicClientApplication,
      accounts: [mockAccount as AccountInfo],
      inProgress: InteractionStatus.None,
      logger: mockLogger,
    });

    renderHeader();

    const displayElements = screen.getAllByText('User');
    expect(displayElements.length).toBeGreaterThan(0);
    expect(screen.getByLabelText('Logged in as User')).toBeInTheDocument();
  });

  it('shows "User" when accounts array is empty', () => {
    mockUseMsal.mockReturnValue({
      instance: {} as IPublicClientApplication,
      accounts: [],
      inProgress: InteractionStatus.None,
      logger: mockLogger,
    });

    renderHeader();

    const displayElements = screen.getAllByText('User');
    expect(displayElements.length).toBeGreaterThan(0);
    expect(screen.getByLabelText('Logged in as User')).toBeInTheDocument();
  });

  it('uses first account when multiple accounts exist', () => {
    const firstAccount: Partial<AccountInfo> = {
      name: 'First User',
      username: 'first@example.com',
      localAccountId: '123',
      homeAccountId: 'home123',
      environment: 'test',
      tenantId: 'tenant123',
      idTokenClaims: {},
    };

    const secondAccount: Partial<AccountInfo> = {
      name: 'Second User',
      username: 'second@example.com',
      localAccountId: '456',
      homeAccountId: 'home456',
      environment: 'test',
      tenantId: 'tenant123',
      idTokenClaims: {},
    };

    mockUseMsal.mockReturnValue({
      instance: {} as IPublicClientApplication,
      accounts: [firstAccount as AccountInfo, secondAccount as AccountInfo],
      inProgress: InteractionStatus.None,
      logger: mockLogger,
    });

    renderHeader();

    const displayElements = screen.getAllByText('First User');
    expect(displayElements.length).toBeGreaterThan(0);
    expect(screen.queryByText('Second User')).toBeNull();
    expect(screen.getByLabelText('Logged in as First User')).toBeInTheDocument();
  });

  it('has proper ARIA label for accessibility', () => {
    const mockAccount: Partial<AccountInfo> = {
      name: 'Jane Smith',
      username: 'jane@example.com',
      localAccountId: '789',
      homeAccountId: 'home789',
      environment: 'test',
      tenantId: 'tenant123',
      idTokenClaims: {},
    };

    mockUseMsal.mockReturnValue({
      instance: {} as IPublicClientApplication,
      accounts: [mockAccount as AccountInfo],
      inProgress: InteractionStatus.None,
      logger: mockLogger,
    });

    renderHeader();

    const personaElement = screen.getByLabelText('Logged in as Jane Smith');
    expect(personaElement).toBeInTheDocument();
    expect(personaElement).toHaveAccessibleName('Logged in as Jane Smith');
  });
});
