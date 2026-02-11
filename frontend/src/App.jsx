import { Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './state/AuthContext';
import { ChatProvider } from './state/ChatContext';
import ErrorBoundary from './components/Shared/ErrorBoundary';
import ProtectedRoute from './components/Auth/ProtectedRoute';
import LoginPage from './components/Auth/LoginPage';
import CallbackHandler from './components/Auth/CallbackHandler';
import AppShell from './components/Layout/AppShell';
import styles from './App.module.css';

export default function App() {
  return (
    <ErrorBoundary>
      <AuthProvider>
        <div className={styles.app}>
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route path="/callback" element={<CallbackHandler />} />
            <Route
              path="/*"
              element={
                <ProtectedRoute>
                  <ChatProvider>
                    <AppShell />
                  </ChatProvider>
                </ProtectedRoute>
              }
            />
          </Routes>
        </div>
      </AuthProvider>
    </ErrorBoundary>
  );
}
