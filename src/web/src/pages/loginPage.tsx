import { FC, useEffect } from 'react';
import { useMsal } from '@azure/msal-react';
import { Stack, Text, PrimaryButton } from '@fluentui/react';
import { useNavigate } from 'react-router-dom';

const LoginPage: FC = () => {
    const { instance, accounts } = useMsal();
    const navigate = useNavigate();

      useEffect(() => {
        if (accounts.length > 0) {
            navigate('/');
        }
    }, [accounts, navigate]);
    
const handleLogin = () => {
    instance.loginRedirect({
        scopes: ['openid', 'profile', 'email']
    });
};

    return (
        <Stack
            verticalAlign="center"
            horizontalAlign="center"
            styles={{ root: { height: '100vh' } }}
            tokens={{ childrenGap: 24 }}
        >
            <Stack.Item>
                <Text variant="xxLarge" block styles={{ root: { textAlign: 'center' } }}>
                    Todo App
                </Text>
            </Stack.Item>
            <Stack.Item>
                <Text variant="large" block styles={{ root: { textAlign: 'center' } }}>
                    Sign in to manage your tasks
                </Text>
            </Stack.Item>
            <Stack.Item>
                <PrimaryButton
                    text="Sign in with Microsoft"
                    iconProps={{ iconName: 'Signin' }}
                    onClick={handleLogin}
                    styles={{ root: { minWidth: 220, height: 40 } }}
                />
            </Stack.Item>
        </Stack>
    );
};

export default LoginPage;
