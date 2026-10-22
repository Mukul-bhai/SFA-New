import { StrictMode, Component } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'

class ErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }
  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }
  componentDidCatch(error, info) {
    console.error('DMS Portal Render Error:', error, info);
  }
  render() {
    if (this.state.hasError) {
      return (
        <div style={{ padding: '40px', fontFamily: 'system-ui, sans-serif', maxWidth: '640px', margin: '60px auto', background: '#fff', borderRadius: '16px', boxShadow: '0 10px 30px rgba(0,0,0,0.1)', textAlign: 'center' }}>
          <div style={{ fontSize: '48px', marginBottom: '16px' }}>⚠️</div>
          <h2 style={{ color: '#0f172a', marginBottom: '8px', fontSize: '22px' }}>DMS Portal Reload Required</h2>
          <p style={{ color: '#64748b', fontSize: '14px', marginBottom: '24px' }}>
            {this.state.error?.message || 'Cache synchronization error occurred.'}
          </p>
          <button
            onClick={() => {
              try { localStorage.clear(); } catch (_) {}
              window.location.reload();
            }}
            style={{ background: '#2563eb', color: '#fff', border: 'none', padding: '12px 28px', borderRadius: '10px', cursor: 'pointer', fontWeight: 'bold', fontSize: '15px' }}
          >
            Reset Portal Cache & Launch
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <ErrorBoundary>
      <App />
    </ErrorBoundary>
  </StrictMode>,
)
