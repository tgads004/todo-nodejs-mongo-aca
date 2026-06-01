// React import needed for Jest test environment JSX transform
// @ts-expect-error - React is used by JSX transform in tests
import React, { FC, ReactElement } from 'react';
import { FontIcon, getTheme, IconButton, IIconProps, IStackStyles, mergeStyles, Persona, PersonaSize, Stack, Text } from '@fluentui/react';
import { useMsal } from '@azure/msal-react';
import type { AccountInfo } from '@azure/msal-browser';

const theme = getTheme();

const logoStyles: IStackStyles = {
    root: {
        width: '300px',
        background: theme.palette.themePrimary,
        alignItems: 'center',
        padding: '0 20px'
    }
}

const logoIconClass = mergeStyles({
    fontSize: 20,
    paddingRight: 10
});

const toolStackClass: IStackStyles = {
    root: {
        alignItems: 'center',
        height: 48,
        paddingRight: 10
    }
}

const iconProps: IIconProps = {
    styles: {
        root: {
            fontSize: 16,
            color: theme.palette.white
        }
    }
}

/**
 * Extracts a display name for the authenticated user from MSAL account info.
 * Implements defensive fallback chain: name → preferred_username → username → "User"
 * @param accounts - MSAL accounts array from useMsal() hook
 * @returns Display name string (never undefined/null)
 */
const getUserDisplayName = (accounts: AccountInfo[]): string => {
    if (!accounts || accounts.length === 0) {
        return "User";
    }
    
    const account = accounts[0];
    
    return account.name 
        || account.idTokenClaims?.preferred_username 
        || account.username 
        || "User";
};

const Header: FC = (): ReactElement => {
    const { accounts } = useMsal();
    const displayName = getUserDisplayName(accounts);
    
    return (
        <Stack horizontal>
            <Stack horizontal styles={logoStyles}>
                <FontIcon aria-label="Check" iconName="SkypeCircleCheck" className={logoIconClass} />
                <Text variant="xLarge">ToDo</Text>
            </Stack>
            <Stack.Item grow={1}>
                <div></div>
            </Stack.Item>
            <Stack.Item>
                <Stack horizontal styles={toolStackClass} grow={1}>
                    <IconButton aria-label="Add" iconProps={{ iconName: "Settings", ...iconProps }} />
                    <IconButton aria-label="Add" iconProps={{ iconName: "Help", ...iconProps }} />
                    <Persona 
                        size={PersonaSize.size24} 
                        text={displayName}
                        aria-label={`Logged in as ${displayName}`}
                    />
                    {/* <Toggle label="Dark Mode" inlineLabel styles={{ root: { marginBottom: 0 } }} onChange={changeTheme} /> */}
                </Stack>
            </Stack.Item>
        </Stack>
    );
}

export default Header;