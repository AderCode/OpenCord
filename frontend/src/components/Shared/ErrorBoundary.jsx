import { Component } from 'react';

export default class ErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError() {
    return { hasError: true };
  }

  componentDidCatch(error, info) {
    console.error('ErrorBoundary caught:', error, info);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          height: '100vh',
          gap: '16px',
          color: 'rgba(255,255,255,0.6)',
          fontFamily: 'Inter, sans-serif',
        }}>
          <h2 style={{ color: 'rgba(255,255,255,0.95)' }}>Something went wrong</h2>
          <button
            onClick={() => window.location.reload()}
            style={{
              padding: '8px 24px',
              background: 'linear-gradient(135deg, #00d2ff, #7b2ff7)',
              color: 'white',
              border: 'none',
              borderRadius: '8px',
              cursor: 'pointer',
              fontWeight: 600,
            }}
          >
            Reload
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}
