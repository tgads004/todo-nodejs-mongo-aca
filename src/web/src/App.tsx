import { useReducer, FC, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { MsalProvider, AuthenticatedTemplate, UnauthenticatedTemplate } from '@azure/msal-react';
import Layout from './layout/layout';
import LoginPage from './pages/loginPage';
import './App.css';
import { DarkTheme } from './ux/theme';
import { AppContext, ApplicationState, getDefaultState } from './models/applicationState';
import appReducer from './reducers';
import { TodoContext } from './components/todoContext';
import { initializeIcons } from '@fluentui/react/lib/Icons';
import { ThemeProvider } from '@fluentui/react';
import Telemetry from './components/telemetry';
import { msalInstance } from './config';

initializeIcons(undefined, { disableWarnings: true });
const App: FC = () => {
  const defaultState: ApplicationState = getDefaultState();
  const [applicationState, dispatch] = useReducer(appReducer, defaultState);
  const initialContext: AppContext = { state: applicationState, dispatch: dispatch }

  // Handle redirect response when returning from Microsoft login
  useEffect(() => {
    msalInstance.handleRedirectPromise().catch(err => {
      console.error('Redirect error:', err);
    });
  }, []);
  
  return (
    <MsalProvider instance={msalInstance}>
      <ThemeProvider applyTo="body" theme={DarkTheme}>
        <TodoContext.Provider value={initialContext}>
          <BrowserRouter>
            <Telemetry>
              <Routes>
                <Route path="/login" element={<LoginPage />} />
                <Route path="/*" element={
                  <>
                    <AuthenticatedTemplate><Layout /></AuthenticatedTemplate>
                    <UnauthenticatedTemplate><Navigate to="/login" replace /></UnauthenticatedTemplate>
                  </>
                } />
              </Routes>
            </Telemetry>
          </BrowserRouter>
        </TodoContext.Provider>
      </ThemeProvider>
    </MsalProvider>
  );
};

export default App;
