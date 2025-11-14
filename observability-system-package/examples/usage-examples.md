# Usage Examples - Bolt.diy Observability System

Common patterns and examples for using the observability system.

---

## 📚 Table of Contents

1. [Basic Logging](#basic-logging)
2. [Error Handling](#error-handling)
3. [API Request Logging](#api-request-logging)
4. [Performance Monitoring](#performance-monitoring)
5. [Health Monitoring](#health-monitoring)
6. [User Actions](#user-actions)
7. [Authentication Events](#authentication-events)
8. [Network Monitoring](#network-monitoring)
9. [Custom Hooks](#custom-hooks)
10. [Advanced Patterns](#advanced-patterns)

---

## Basic Logging

### Simple Console Logging

```typescript
import { logger } from '~/utils/logger';

// Different log levels
logger.trace('Very detailed debugging info');
logger.debug('Debugging information');
logger.info('Informational message');
logger.warn('Warning message');
logger.error('Error message');
```

### Scoped Logging

```typescript
import { createScopedLogger } from '~/utils/logger';

const logger = createScopedLogger('UserService');

logger.info('Fetching user data');  // Output: [UserService] Fetching user data
logger.error('Failed to fetch user', error);
```

### Conditional Logging

```typescript
import { createScopedLogger } from '~/utils/logger';

const logger = createScopedLogger('DataProcessor');

function processData(data: any[]) {
  if (data.length === 0) {
    logger.warn('Processing empty dataset');
    return;
  }

  logger.debug('Processing', data.length, 'items');

  // Process data...

  logger.info('Processing complete', { itemsProcessed: data.length });
}
```

---

## Error Handling

### Try-Catch with Logging

```typescript
import { createScopedLogger } from '~/utils/logger';
import { logStore } from '~/lib/stores/logs';

const logger = createScopedLogger('API');

async function fetchUserData(userId: string) {
  try {
    logger.debug('Fetching user data for', userId);

    const response = await fetch(`/api/users/${userId}`);

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    const data = await response.json();

    logger.info('User data fetched successfully', { userId });
    logStore.logAPIRequest({
      method: 'GET',
      endpoint: `/api/users/${userId}`,
      duration: 0,  // Calculate actual duration
      statusCode: response.status,
      component: 'UserService',
    });

    return data;
  } catch (error) {
    logger.error('Failed to fetch user data', error, { userId });
    logStore.logError(
      'Failed to fetch user data',
      error as Error,
      'UserService'
    );
    throw error;
  }
}
```

### React Error Boundary

```typescript
import React, { Component, ErrorInfo, ReactNode } from 'react';
import { logger } from '~/utils/logger';
import { logStore } from '~/lib/stores/logs';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    logger.error('React error boundary caught error:', error, errorInfo);
    logStore.logError(
      `React error: ${error.message}`,
      error,
      'ErrorBoundary'
    );
  }

  handleRetry = () => {
    this.setState({ hasError: false, error: undefined });
  };

  render() {
    if (this.state.hasError) {
      return (
        this.props.fallback || (
          <div style={{ padding: '2rem', textAlign: 'center' }}>
            <h1>Oops! Something went wrong</h1>
            <p>We've logged the error and will look into it.</p>
            <button onClick={this.handleRetry}>Try Again</button>
            {process.env.NODE_ENV === 'development' && (
              <details style={{ marginTop: '1rem', textAlign: 'left' }}>
                <summary>Error Details (Dev Mode)</summary>
                <pre>{this.state.error?.stack}</pre>
              </details>
            )}
          </div>
        )
      );
    }

    return this.props.children;
  }
}
```

---

## API Request Logging

### Axios Interceptor

```typescript
import axios from 'axios';
import { logStore } from '~/lib/stores/logs';
import { logger } from '~/utils/logger';

const api = axios.create({
  baseURL: '/api',
});

// Request interceptor
api.interceptors.request.use(
  (config) => {
    config.metadata = { startTime: performance.now() };
    logger.debug('API Request:', config.method?.toUpperCase(), config.url);
    return config;
  },
  (error) => {
    logger.error('API Request Error:', error);
    return Promise.reject(error);
  }
);

// Response interceptor
api.interceptors.response.use(
  (response) => {
    const duration = performance.now() - response.config.metadata.startTime;

    logStore.logAPIRequest({
      method: response.config.method?.toUpperCase() || 'GET',
      endpoint: response.config.url || '',
      duration,
      statusCode: response.status,
    });

    logger.debug('API Response:', response.status, response.config.url, `${duration}ms`);

    return response;
  },
  (error) => {
    const duration = error.config?.metadata?.startTime
      ? performance.now() - error.config.metadata.startTime
      : 0;

    logStore.logAPIRequest({
      method: error.config?.method?.toUpperCase() || 'GET',
      endpoint: error.config?.url || '',
      duration,
      statusCode: error.response?.status || 0,
    });

    logger.error('API Error:', error.response?.status, error.config?.url);
    logStore.logError(
      `API Error: ${error.message}`,
      error,
      'ApiClient'
    );

    return Promise.reject(error);
  }
);

export default api;
```

### Fetch Wrapper

```typescript
import { logStore } from '~/lib/stores/logs';
import { logger } from '~/utils/logger';

async function fetchWithLogging(url: string, options?: RequestInit) {
  const startTime = performance.now();

  try {
    logger.debug('Fetch:', options?.method || 'GET', url);

    const response = await fetch(url, options);
    const duration = performance.now() - startTime;

    logStore.logAPIRequest({
      method: options?.method || 'GET',
      endpoint: url,
      duration,
      statusCode: response.status,
    });

    logger.debug('Fetch complete:', response.status, url, `${duration}ms`);

    return response;
  } catch (error) {
    const duration = performance.now() - startTime;

    logStore.logAPIRequest({
      method: options?.method || 'GET',
      endpoint: url,
      duration,
      statusCode: 0,
    });

    logger.error('Fetch error:', error);
    logStore.logError(`Fetch error: ${url}`, error as Error, 'FetchClient');

    throw error;
  }
}

// Usage
const response = await fetchWithLogging('/api/users', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ name: 'John' }),
});
```

---

## Performance Monitoring

### Component Render Performance

```typescript
import { useEffect, useRef } from 'react';
import { logStore } from '~/lib/stores/logs';
import { logger } from '~/utils/logger';

export function ExpensiveComponent() {
  const renderCount = useRef(0);
  const mountTime = useRef(performance.now());

  useEffect(() => {
    renderCount.current++;

    if (renderCount.current === 1) {
      const mountDuration = performance.now() - mountTime.current;

      logger.debug('Component mounted in', mountDuration, 'ms');

      if (mountDuration > 1000) {
        logger.warn('Slow component mount:', mountDuration, 'ms');
        logStore.logPerformance({
          metric: 'slow_component_mount',
          value: mountDuration,
          metadata: { component: 'ExpensiveComponent' },
        });
      }
    }
  });

  return <div>{/* ... */}</div>;
}
```

### Page Load Performance

```typescript
// src/main.tsx
import { logStore } from '~/lib/stores/logs';
import { logger } from '~/utils/logger';

window.addEventListener('load', () => {
  const navigation = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;

  if (navigation) {
    const metrics = {
      domContentLoaded: navigation.domContentLoadedEventEnd - navigation.domContentLoadedEventStart,
      loadComplete: navigation.loadEventEnd - navigation.loadEventStart,
      domInteractive: navigation.domInteractive - navigation.fetchStart,
      totalTime: navigation.loadEventEnd - navigation.fetchStart,
    };

    logger.info('Page load metrics:', metrics);

    logStore.logPerformance({
      metric: 'page_load',
      value: metrics.totalTime,
      metadata: metrics,
    });

    // Log slow page loads
    if (metrics.totalTime > 3000) {
      logger.warn('Slow page load:', metrics.totalTime, 'ms');
      logStore.logPerformance({
        metric: 'slow_page_load',
        value: metrics.totalTime,
        metadata: metrics,
      });
    }
  }
});
```

### Function Performance

```typescript
import { logStore } from '~/lib/stores/logs';
import { logger } from '~/utils/logger';

function measurePerformance<T>(
  fn: () => T,
  label: string,
  warnThreshold?: number
): T {
  const start = performance.now();
  const result = fn();
  const duration = performance.now() - start;

  logger.debug(`${label} took ${duration}ms`);

  if (warnThreshold && duration > warnThreshold) {
    logger.warn(`${label} exceeded threshold:`, duration, 'ms');
    logStore.logPerformance({
      metric: 'slow_function',
      value: duration,
      metadata: { function: label },
    });
  }

  return result;
}

// Usage
const data = measurePerformance(
  () => processLargeDataset(items),
  'processLargeDataset',
  1000  // Warn if takes > 1 second
);
```

---

## Health Monitoring

### Monitor External API

```typescript
import { useEffect } from 'react';
import { useLocalModelHealth } from '~/lib/hooks/useLocalModelHealth';

export function APIHealthMonitor() {
  const {
    healthStatuses,
    startMonitoring,
    stopMonitoring,
    overallHealth,
  } = useLocalModelHealth();

  useEffect(() => {
    startMonitoring(
      [
        { provider: 'Main API', baseUrl: 'https://api.example.com' },
        { provider: 'Auth Service', baseUrl: 'https://auth.example.com' },
        { provider: 'Database', baseUrl: '/api/db-health' },
      ],
      30000  // Check every 30 seconds
    );

    return () => stopMonitoring();
  }, []);

  return (
    <div className="health-monitor">
      <h3>System Status</h3>
      <p>
        {overallHealth.healthy} / {overallHealth.total} services healthy
      </p>
      <ul>
        {Array.from(healthStatuses.values()).map((status) => (
          <li key={status.provider}>
            <strong>{status.provider}:</strong>{' '}
            <span className={`status-${status.status}`}>
              {status.status}
            </span>
            {status.responseTime && <span> ({status.responseTime}ms)</span>}
            {status.error && <span className="error"> - {status.error}</span>}
          </li>
        ))}
      </ul>
    </div>
  );
}
```

### Single Service Health Check

```typescript
import { useProviderHealth } from '~/lib/hooks/useLocalModelHealth';

export function DatabaseHealthBadge() {
  const { status, performHealthCheck } = useProviderHealth(
    'Database',
    '/api/db-health'
  );

  const handleRefresh = async () => {
    await performHealthCheck();
  };

  return (
    <div className={`health-badge health-${status.status}`}>
      <span>Database: {status.status}</span>
      {status.responseTime && <span> ({status.responseTime}ms)</span>}
      <button onClick={handleRefresh}>Refresh</button>
    </div>
  );
}
```

---

## User Actions

### Track Button Clicks

```typescript
import { captureUserAction } from '~/utils/debugLogger';
import { logStore } from '~/lib/stores/logs';

export function SubmitButton() {
  const handleClick = () => {
    captureUserAction('submit_button_clicked', {
      timestamp: Date.now(),
      page: window.location.pathname,
    });

    logStore.logUserAction('Submit button clicked', {
      buttonId: 'submit-form',
      formData: {/* ... */},
    });

    // Handle submit logic...
  };

  return <button onClick={handleClick}>Submit</button>;
}
```

### Track Navigation

```typescript
import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { captureUserAction } from '~/utils/debugLogger';
import { logStore } from '~/lib/stores/logs';

export function NavigationTracker() {
  const location = useLocation();

  useEffect(() => {
    captureUserAction('page_navigation', {
      path: location.pathname,
      search: location.search,
      timestamp: Date.now(),
    });

    logStore.logUserAction('Page navigation', {
      from: document.referrer,
      to: location.pathname,
    });
  }, [location]);

  return null;
}
```

### Track Form Submissions

```typescript
import { FormEvent } from 'react';
import { logStore } from '~/lib/stores/logs';
import { logger } from '~/utils/logger';

export function ContactForm() {
  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    const formData = new FormData(e.currentTarget);
    const data = Object.fromEntries(formData.entries());

    logger.info('Form submitted', { fields: Object.keys(data) });
    logStore.logUserAction('Contact form submitted', {
      fields: Object.keys(data),
      timestamp: Date.now(),
    });

    try {
      const response = await fetch('/api/contact', {
        method: 'POST',
        body: JSON.stringify(data),
        headers: { 'Content-Type': 'application/json' },
      });

      if (response.ok) {
        logger.info('Form submission successful');
        logStore.logSystem('Contact form submission successful');
      } else {
        throw new Error(`HTTP ${response.status}`);
      }
    } catch (error) {
      logger.error('Form submission failed', error);
      logStore.logError('Form submission failed', error as Error, 'ContactForm');
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      {/* form fields */}
      <button type="submit">Submit</button>
    </form>
  );
}
```

---

## Authentication Events

### Login Tracking

```typescript
import { logStore } from '~/lib/stores/logs';
import { logger } from '~/utils/logger';

async function login(email: string, password: string) {
  logger.info('Login attempt', { email });

  try {
    const response = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });

    if (!response.ok) {
      throw new Error('Login failed');
    }

    const { user, token } = await response.json();

    logger.info('Login successful', { userId: user.id });
    logStore.logAuth('user_login', {
      userId: user.id,
      email: user.email,
      method: 'password',
      timestamp: Date.now(),
    });

    // Store token...
    return { user, token };
  } catch (error) {
    logger.error('Login failed', error);
    logStore.logAuth('login_failed', {
      email,
      error: (error as Error).message,
    });
    throw error;
  }
}
```

### Logout Tracking

```typescript
import { logStore } from '~/lib/stores/logs';
import { logger } from '~/utils/logger';

function logout(userId: string) {
  logger.info('User logging out', { userId });

  logStore.logAuth('user_logout', {
    userId,
    timestamp: Date.now(),
  });

  // Clear session...
}
```

### Session Expiry

```typescript
import { logStore } from '~/lib/stores/logs';
import { logger } from '~/utils/logger';

function handleSessionExpiry(userId: string) {
  logger.warn('Session expired', { userId });

  logStore.logAuth('session_expired', {
    userId,
    timestamp: Date.now(),
  });

  // Redirect to login...
}
```

---

## Network Monitoring

### Connection Status Alert

```typescript
import { useConnectionStatus } from '~/lib/hooks/useConnectionStatus';

export function ConnectionStatusAlert() {
  const { issue, acknowledgeIssue, connectionStatus } = useConnectionStatus();

  if (!issue) return null;

  return (
    <div className={`alert alert-${issue === 'disconnected' ? 'error' : 'warning'}`}>
      {issue === 'disconnected' && (
        <>
          <h4>No Internet Connection</h4>
          <p>You are currently offline. Please check your internet connection.</p>
        </>
      )}
      {issue === 'high-latency' && (
        <>
          <h4>Slow Connection Detected</h4>
          <p>
            Your connection is slow ({connectionStatus.latency}ms latency).
            Some features may be delayed.
          </p>
        </>
      )}
      <button onClick={acknowledgeIssue}>Dismiss</button>
    </div>
  );
}
```

### Manual Connection Test

```typescript
import { useState } from 'react';
import { useConnectionTest } from '~/lib/hooks/useConnectionTest';

export function ConnectionTestButton() {
  const { testConnection, status, errorMessage } = useConnectionTest();

  const handleTest = async () => {
    await testConnection('/api/health');
  };

  return (
    <div>
      <button onClick={handleTest} disabled={status === 'testing'}>
        {status === 'testing' ? 'Testing...' : 'Test Connection'}
      </button>
      {status === 'success' && <span className="success">✓ Connected</span>}
      {status === 'error' && <span className="error">✗ {errorMessage}</span>}
    </div>
  );
}
```

---

## Custom Hooks

### useDebugLog Hook

```typescript
import { useEffect } from 'react';
import { createScopedLogger } from '~/utils/logger';

export function useDebugLog(componentName: string) {
  const logger = createScopedLogger(componentName);

  useEffect(() => {
    logger.debug(`${componentName} mounted`);

    return () => {
      logger.debug(`${componentName} unmounted`);
    };
  }, [componentName]);

  return logger;
}

// Usage
function MyComponent() {
  const logger = useDebugLog('MyComponent');

  const handleClick = () => {
    logger.info('Button clicked');
  };

  return <button onClick={handleClick}>Click me</button>;
}
```

### usePerformanceMonitor Hook

```typescript
import { useEffect, useRef } from 'react';
import { logStore } from '~/lib/stores/logs';

export function usePerformanceMonitor(componentName: string, warnThreshold = 100) {
  const renderCount = useRef(0);
  const mountTime = useRef(performance.now());
  const lastRenderTime = useRef(performance.now());

  useEffect(() => {
    renderCount.current++;

    if (renderCount.current === 1) {
      // First render (mount)
      const mountDuration = performance.now() - mountTime.current;

      if (mountDuration > warnThreshold) {
        logStore.logPerformance({
          metric: 'slow_component_mount',
          value: mountDuration,
          metadata: { component: componentName },
        });
      }
    } else {
      // Subsequent renders
      const renderDuration = performance.now() - lastRenderTime.current;

      if (renderDuration > warnThreshold) {
        logStore.logPerformance({
          metric: 'slow_component_render',
          value: renderDuration,
          metadata: {
            component: componentName,
            renderCount: renderCount.current,
          },
        });
      }
    }

    lastRenderTime.current = performance.now();
  });
}

// Usage
function ExpensiveComponent() {
  usePerformanceMonitor('ExpensiveComponent', 50);

  return <div>{/* ... */}</div>;
}
```

---

## Advanced Patterns

### Batch Logging

```typescript
import { logStore } from '~/lib/stores/logs';

class LogBatcher {
  private queue: Array<() => void> = [];
  private timeout: NodeJS.Timeout | null = null;

  add(logFn: () => void) {
    this.queue.push(logFn);

    if (!this.timeout) {
      this.timeout = setTimeout(() => this.flush(), 1000);
    }
  }

  flush() {
    this.queue.forEach((logFn) => logFn());
    this.queue = [];
    this.timeout = null;
  }
}

const batcher = new LogBatcher();

// Usage: Batch multiple logs
for (let i = 0; i < 100; i++) {
  batcher.add(() => {
    logStore.logSystem(`Processing item ${i}`);
  });
}

// Logs are flushed after 1 second or manually
batcher.flush();
```

### Conditional Debug Logging

```typescript
import { createScopedLogger } from '~/utils/logger';

const DEBUG_COMPONENTS = new Set(['UserService', 'APIClient', 'AuthManager']);

export function createConditionalLogger(componentName: string) {
  const logger = createScopedLogger(componentName);
  const isDebugEnabled = DEBUG_COMPONENTS.has(componentName);

  return {
    ...logger,
    debug: (...args: any[]) => {
      if (isDebugEnabled) {
        logger.debug(...args);
      }
    },
  };
}

// Usage
const logger = createConditionalLogger('UserService');
logger.debug('This will log');

const logger2 = createConditionalLogger('OtherComponent');
logger2.debug('This will NOT log');
```

### Performance Budget Enforcer

```typescript
import { logStore } from '~/lib/stores/logs';
import { logger } from '~/utils/logger';

interface PerformanceBudget {
  pageLoad: number;
  apiRequest: number;
  componentRender: number;
}

const budget: PerformanceBudget = {
  pageLoad: 3000,
  apiRequest: 1000,
  componentRender: 100,
};

export function enforcePerformanceBudget(
  metric: keyof PerformanceBudget,
  value: number,
  metadata?: any
) {
  const threshold = budget[metric];

  if (value > threshold) {
    logger.warn(`Performance budget exceeded for ${metric}:`, value, 'ms (budget:', threshold, 'ms)');

    logStore.logPerformance({
      metric: `budget_exceeded_${metric}`,
      value,
      metadata: {
        ...metadata,
        budget: threshold,
        overage: value - threshold,
      },
    });

    return false;  // Budget exceeded
  }

  return true;  // Within budget
}

// Usage
const pageLoadTime = 3500;
if (!enforcePerformanceBudget('pageLoad', pageLoadTime)) {
  console.error('Page load too slow!');
}
```

---

## Summary

These examples cover the most common use cases for the observability system. Mix and match these patterns to build a comprehensive logging and monitoring strategy for your application.

For more details, see:
- `README.md` - Complete API reference
- `IMPLEMENTATION-GUIDE.md` - Setup instructions
- `MIGRATION-GUIDE.md` - Migrating from existing systems
