# Bolt.diy Observability System - Complete Documentation

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [System Components](#system-components)
4. [Implementation Details](#implementation-details)
5. [Dependencies](#dependencies)
6. [Integration Guide](#integration-guide)
7. [API Reference](#api-reference)
8. [Best Practices](#best-practices)

---

## Overview

This is a **production-grade, self-contained observability system** extracted from bolt.diy that provides:

- ✅ Multi-layered logging (console, debug capture, event persistence)
- ✅ Real-time health monitoring
- ✅ Network connectivity tracking
- ✅ Performance metrics collection
- ✅ Error boundaries and exception handling
- ✅ User-accessible debug log exports
- ✅ Memory-efficient circular buffers
- ✅ Zero third-party observability services required

**Key Philosophy:** Everything runs in-house without external services like Sentry, Rollbar, or DataDog.

---

## Architecture

### 🏗️ Three-Layer Logging System

```
┌─────────────────────────────────────────────────────┐
│                 APPLICATION LAYER                    │
│  (Components, Services, API Routes, Utilities)      │
└──────────────┬────────────────┬─────────────────────┘
               │                │
               ▼                ▼
     ┌─────────────────┐  ┌──────────────────┐
     │  LOGGER.TS      │  │  LOGS.TS (Store) │
     │  Console Output │  │  Event Persistence│
     │  Color-Coded    │  │  Cookie Storage   │
     └─────────────────┘  └──────────────────┘
               │                │
               ▼                ▼
         ┌─────────────────────────────────┐
         │     DEBUGLOGGER.TS              │
         │  Comprehensive Data Capture:    │
         │  - Console Interception         │
         │  - Network Monitoring           │
         │  - Error Capture                │
         │  - Terminal Logs                │
         │  - Performance Metrics          │
         │  - System Information           │
         └─────────────────────────────────┘
                      │
                      ▼
         ┌──────────────────────────┐
         │   CIRCULAR BUFFERS       │
         │   (Memory-Efficient      │
         │    Max 1000 Entries)     │
         └──────────────────────────┘
                      │
                      ▼
         ┌──────────────────────────┐
         │  DOWNLOADABLE DEBUG LOG  │
         │  (JSON + Human-Readable) │
         └──────────────────────────┘
```

### 🔄 Health Monitoring Flow

```
┌────────────────────────────────────────────┐
│     LocalModelHealthMonitor Service        │
│  (Monitors Ollama, LMStudio, OpenAI-like) │
└──────────────┬─────────────────────────────┘
               │ 30-second intervals
               ▼
    ┌──────────────────────┐
    │  Health Check APIs   │
    │  - /api/tags         │
    │  - /v1/models        │
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────┐
    │   EventEmitter       │
    │  'statusChanged'     │
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────┐
    │ useLocalModelHealth  │
    │  React Hook          │
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────────┐
    │  UI Components           │
    │  - StatusDashboard       │
    │  - HealthStatusBadge     │
    └──────────────────────────┘
```

---

## System Components

### 1. Core Logging

#### **logger.ts** - Global Logger
**Location:** `source-files/logger.ts`

**Purpose:** Primary console logging with color coding and scoped contexts

**Features:**
- Log levels: `trace`, `debug`, `info`, `warn`, `error`, `none`
- Environment variable control: `VITE_LOG_LEVEL`
- Scoped loggers: `createScopedLogger('ComponentName')`
- Color-coded output using Chalk
- Lazy-loaded debug capture integration

**API:**
```typescript
import { logger, createScopedLogger } from '~/utils/logger';

// Global logger
logger.info('Application started');
logger.error('Failed to load', error);

// Scoped logger
const componentLogger = createScopedLogger('MyComponent');
componentLogger.debug('Rendering with props:', props);
```

**Configuration:**
```typescript
// Set via environment variable
VITE_LOG_LEVEL=debug  // trace | debug | info | warn | error | none
```

---

#### **debugLogger.ts** - Advanced Debug Capture
**Location:** `source-files/debugLogger.ts`

**Purpose:** Comprehensive debugging system with circular buffer memory management

**Key Classes:**

1. **CircularBuffer** (Lines 38-86)
   - Fixed-size buffer preventing memory leaks
   - Automatic overflow handling
   - O(1) push operation

2. **DebugLogger** (Lines 218-1118)
   - Multiple circular buffers (logs, errors, network, user actions, terminal)
   - Max 1000 entries per buffer
   - Configurable capture options

**Captured Data:**
- **Console logs** - All console.log/warn/error calls
- **Network requests** - Method, URL, status, duration, size
- **Errors** - Stack traces, timestamps, context
- **User actions** - Click events, navigation, form submissions
- **Terminal output** - WebContainer/terminal logs (debounced 100ms)
- **Performance** - Page load, FCP, memory usage
- **System info** - Browser, platform, screen, timezone

**API:**
```typescript
import {
  debugLogger,
  downloadDebugLog,
  captureUserAction,
  captureTerminalLog,
  enableDebugMode,
  disableDebugMode
} from '~/utils/debugLogger';

// Enable/disable debug mode
enableDebugMode();
disableDebugMode();

// Capture custom events
captureUserAction('button_clicked', { buttonId: 'submit' });
captureTerminalLog('$ npm install');

// Download debug logs
await downloadDebugLog('my-debug-log.txt');

// Get debug data programmatically
const debugData = debugLogger.getDebugLog();
console.log(debugData.logs);
console.log(debugData.networkRequests);
```

**Configuration:**
```typescript
debugLogger.updateConfig({
  enabled: true,
  captureConsole: true,
  captureNetwork: true,
  captureErrors: true,
  terminalDebounceMs: 100
});
```

---

#### **logs.ts** - Event Store (Persistent Logging)
**Location:** `source-files/logs.ts`

**Purpose:** Application-wide event logging with persistence

**Storage:**
- Primary: Cookie storage (`eventLogs`)
- Read state: localStorage (`bolt_read_logs`)
- Max 1000 entries with automatic trimming

**Log Entry Structure:**
```typescript
interface LogEntry {
  id: string;
  timestamp: string;
  level: 'info' | 'warning' | 'error' | 'debug';
  category: 'system' | 'provider' | 'user' | 'error' | 'api' |
            'auth' | 'database' | 'network' | 'performance' |
            'settings' | 'task' | 'update' | 'feature';
  message: string;
  component?: string;
  action?: string;
  userId?: string;
  sessionId?: string;
  metadata?: Record<string, any>;
  duration?: number;
  statusCode?: number;
}
```

**API:**
```typescript
import { logStore } from '~/lib/stores/logs';

// Specialized logging methods
logStore.logSystem('Application initialized');
logStore.logProvider('OpenAI', 'API call started');
logStore.logUserAction('Button clicked', { buttonId: 'submit' });

logStore.logAPIRequest({
  method: 'POST',
  endpoint: '/api/chat',
  duration: 234,
  statusCode: 200,
  component: 'ChatInterface'
});

logStore.logError('Failed to load data', error, 'DataLoader');

logStore.logPerformance({
  metric: 'page_load',
  value: 1234,
  metadata: { route: '/dashboard' }
});

logStore.logAuth('user_login', { userId: '123', method: 'oauth' });

logStore.logNetworkStatus('online');

// Read operations
const allLogs = logStore.getLogs();
const errorLogs = logStore.getFilteredLogs({ level: 'error' });
const apiLogs = logStore.getFilteredLogs({ category: 'api' });

// Mark as read
logStore.markAsRead(logId);
logStore.markAllAsRead();

// Export
const exportedLogs = logStore.exportLogs();
```

---

### 2. Health Monitoring

#### **localModelHealthMonitor.ts** - Service Health Checker
**Location:** `source-files/localModelHealthMonitor.ts`

**Purpose:** Monitor local AI provider health (Ollama, LMStudio, OpenAI-compatible)

**Features:**
- Periodic health checks (30-second default interval)
- Response time tracking
- Available model detection
- Version information retrieval
- CORS error detection
- 10-second timeout protection
- EventEmitter for real-time updates

**Health Status Structure:**
```typescript
interface ModelHealthStatus {
  provider: 'Ollama' | 'LMStudio' | 'OpenAI-like';
  baseUrl: string;
  status: 'healthy' | 'unhealthy' | 'checking' | 'unknown';
  responseTime?: number;  // milliseconds
  availableModels?: string[];
  version?: string;
  lastChecked: string;  // ISO timestamp
  error?: string;
}
```

**API:**
```typescript
import { LocalModelHealthMonitor } from '~/lib/services/localModelHealthMonitor';

const monitor = new LocalModelHealthMonitor();

// Start monitoring
monitor.startMonitoring(
  [
    { provider: 'Ollama', baseUrl: 'http://localhost:11434' },
    { provider: 'LMStudio', baseUrl: 'http://localhost:1234' }
  ],
  30000  // Check every 30 seconds
);

// Listen for status changes
monitor.on('statusChanged', (status: ModelHealthStatus) => {
  console.log(`${status.provider} is now ${status.status}`);
  if (status.responseTime) {
    console.log(`Response time: ${status.responseTime}ms`);
  }
});

// Manual health check
const status = await monitor.performHealthCheck('Ollama', 'http://localhost:11434');

// Get all statuses
const allStatuses = monitor.getAllHealthStatuses();

// Stop monitoring
monitor.stopMonitoring();
```

---

#### **useLocalModelHealth.ts** - React Hook
**Location:** `source-files/hooks/useLocalModelHealth.ts`

**Purpose:** React integration for health monitoring

**API:**
```typescript
import { useLocalModelHealth } from '~/lib/hooks/useLocalModelHealth';

function MyComponent() {
  const {
    healthStatuses,      // Map<string, ModelHealthStatus>
    isMonitoring,        // boolean
    startMonitoring,     // (providers, interval?) => void
    stopMonitoring,      // () => void
    performHealthCheck,  // (provider, baseUrl) => Promise<ModelHealthStatus>
    overallHealth        // { healthy: number, unhealthy: number, total: number }
  } = useLocalModelHealth();

  // Start monitoring on mount
  useEffect(() => {
    startMonitoring([
      { provider: 'Ollama', baseUrl: 'http://localhost:11434' }
    ]);
    return () => stopMonitoring();
  }, []);

  return (
    <div>
      <p>Healthy: {overallHealth.healthy} / {overallHealth.total}</p>
      {Array.from(healthStatuses.values()).map(status => (
        <div key={status.provider}>
          {status.provider}: {status.status} ({status.responseTime}ms)
        </div>
      ))}
    </div>
  );
}
```

---

### 3. Network Monitoring

#### **connection.ts** - Connection Status API
**Location:** `source-files/api/connection.ts`

**Purpose:** Monitor network connectivity and latency

**API:**
```typescript
import { checkConnection } from '~/lib/api/connection';

const status = await checkConnection();
// Returns: {
//   connected: boolean;
//   latency: number;  // milliseconds
//   lastChecked: string;  // ISO timestamp
// }

if (status.connected && status.latency < 1000) {
  console.log('Good connection');
} else if (status.latency > 1000) {
  console.warn('High latency:', status.latency, 'ms');
}
```

**Implementation:**
- Checks `navigator.onLine` first
- Falls back to endpoint checks: `/api/health`, `/`, `/favicon.ico`
- Uses HEAD requests for efficiency
- Measures latency with `performance.now()`

---

#### **useConnectionStatus.ts** - Connection Monitor Hook
**Location:** `source-files/hooks/useConnectionStatus.ts`

**Purpose:** React hook for continuous connection monitoring

**API:**
```typescript
import { useConnectionStatus } from '~/lib/hooks/useConnectionStatus';

function MyComponent() {
  const {
    issue,                    // 'disconnected' | 'high-latency' | null
    acknowledgeIssue,         // () => void
    resetAcknowledgements,    // () => void
    connectionStatus          // { connected: boolean, latency: number }
  } = useConnectionStatus();

  // Automatically checks every 10 seconds

  if (issue === 'disconnected') {
    return (
      <Alert>
        No internet connection
        <button onClick={acknowledgeIssue}>Dismiss</button>
      </Alert>
    );
  }

  if (issue === 'high-latency') {
    return (
      <Alert>
        Slow connection detected ({connectionStatus.latency}ms)
        <button onClick={acknowledgeIssue}>Dismiss</button>
      </Alert>
    );
  }

  return <div>Connection OK</div>;
}
```

**Features:**
- 10-second polling interval
- High-latency threshold: 1000ms
- localStorage-based acknowledgment system
- Automatic issue detection

---

### 4. Error Handling

#### **ErrorBoundary Components**
**Locations:**
- `source-files/components/ErrorBoundary-Generic.tsx`
- `source-files/components/ErrorBoundary-GitHub.tsx`

**Purpose:** React error boundaries for graceful error handling

**Generic Error Boundary API:**
```typescript
import { ErrorBoundary } from '~/components/ErrorBoundary';

function App() {
  return (
    <ErrorBoundary>
      <YourComponents />
    </ErrorBoundary>
  );
}
```

**Features:**
- Catches rendering errors in child components
- Displays fallback UI with error details (dev mode only)
- Logs errors to console
- Provides retry mechanism
- Prevents entire app crash

**Custom Error Boundary:**
```typescript
import React, { Component, ErrorInfo, ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

class CustomErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('Error caught by boundary:', error, errorInfo);
    // You can also log to your error logging service here
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback || <div>Something went wrong</div>;
    }

    return this.props.children;
  }
}
```

---

### 5. Notifications

#### **notifications.ts** - Notification API
**Location:** `source-files/api/notifications.ts`

**Purpose:** User-facing notifications derived from log entries

**API:**
```typescript
import {
  getNotifications,
  getUnreadNotificationCount,
  markNotificationAsRead,
  markAllNotificationsAsRead
} from '~/lib/api/notifications';

// Get all notifications (filters out 'system' category)
const notifications = getNotifications();
// Returns: LogEntry[]

// Get unread count
const unreadCount = getUnreadNotificationCount();
// Returns: number

// Mark as read
markNotificationAsRead(notificationId);
markAllNotificationsAsRead();
```

---

#### **useNotifications.ts** - Notifications Hook
**Location:** `source-files/hooks/useNotifications.ts`

**Purpose:** React hook for notification management

**API:**
```typescript
import { useNotifications } from '~/lib/hooks/useNotifications';

function NotificationCenter() {
  const {
    notifications,      // LogEntry[]
    unreadCount,        // number
    markAsRead,         // (id: string) => void
    markAllAsRead       // () => void
  } = useNotifications();

  // Automatically polls every 60 seconds

  return (
    <div>
      <h2>Notifications ({unreadCount})</h2>
      {notifications.map(notif => (
        <div key={notif.id} onClick={() => markAsRead(notif.id)}>
          <span className={`level-${notif.level}`}>{notif.level}</span>
          <span>{notif.message}</span>
          <span>{notif.timestamp}</span>
        </div>
      ))}
      <button onClick={markAllAsRead}>Mark All Read</button>
    </div>
  );
}
```

---

### 6. Health Check Endpoint

#### **health.ts** - API Route
**Location:** `source-files/api/health.ts`

**Purpose:** Simple health check endpoint for monitoring

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-11-14T10:30:00.000Z"
}
```

**Usage:**
```typescript
// In your application
fetch('/api/health')
  .then(res => res.json())
  .then(data => console.log('API is', data.status));

// For external monitoring
curl https://your-app.com/api/health
```

---

## Dependencies

### Required NPM Packages

```json
{
  "dependencies": {
    "chalk": "^5.3.0",           // Color-coded console output
    "nanostores": "^0.10.0"      // Lightweight state management for logs
  },
  "devDependencies": {
    "@types/node": "^20.0.0"     // Node.js type definitions
  }
}
```

### Framework Requirements

- **React** 18+ (for hooks and components)
- **TypeScript** 5+ (type safety)
- **Modern Browser** with support for:
  - `fetch()` API
  - `performance.now()`
  - `EventTarget` / `EventEmitter`
  - `localStorage` and `document.cookie`
  - `navigator.onLine`

### Optional Integrations

- **Electron** - For desktop app logging (electron-log)
- **WebContainer** - For terminal logging capture
- **Vite** - For environment variable handling

---

## Integration Guide

### Quick Start (Minimal Setup)

**Step 1: Install Dependencies**
```bash
npm install chalk nanostores
npm install -D @types/node
```

**Step 2: Copy Core Files**
```bash
# Copy logger utilities
cp source-files/logger.ts your-project/src/utils/
cp source-files/debugLogger.ts your-project/src/utils/
cp source-files/logs.ts your-project/src/lib/stores/
```

**Step 3: Initialize in Your App**
```typescript
// app/root.tsx or main.tsx
import { logger } from '~/utils/logger';
import { enableDebugMode } from '~/utils/debugLogger';

// Enable debug mode in development
if (import.meta.env.DEV) {
  enableDebugMode();
}

logger.info('Application started');
```

**Step 4: Use in Components**
```typescript
import { createScopedLogger } from '~/utils/logger';
import { logStore } from '~/lib/stores/logs';

const logger = createScopedLogger('MyComponent');

function MyComponent() {
  useEffect(() => {
    logger.info('Component mounted');
    logStore.logSystem('MyComponent mounted');
  }, []);

  const handleError = (error: Error) => {
    logger.error('Failed to load data', error);
    logStore.logError('Data loading failed', error, 'MyComponent');
  };

  return <div>...</div>;
}
```

---

### Full Setup (All Features)

**Step 1: Copy All Files**
```bash
# Core logging
cp source-files/logger.ts your-project/src/utils/
cp source-files/debugLogger.ts your-project/src/utils/
cp source-files/logs.ts your-project/src/lib/stores/

# Health monitoring
cp source-files/localModelHealthMonitor.ts your-project/src/lib/services/

# APIs
cp -r source-files/api/* your-project/src/lib/api/

# Hooks
cp -r source-files/hooks/* your-project/src/lib/hooks/

# Components
cp -r source-files/components/* your-project/src/components/
```

**Step 2: Configure Environment**
```bash
# .env
VITE_LOG_LEVEL=debug  # trace | debug | info | warn | error | none
```

**Step 3: Setup Error Boundaries**
```typescript
// app/root.tsx
import { ErrorBoundary } from '~/components/ErrorBoundary';

export default function App() {
  return (
    <ErrorBoundary>
      <YourApp />
    </ErrorBoundary>
  );
}
```

**Step 4: Setup Health Monitoring**
```typescript
// app/components/HealthMonitor.tsx
import { useLocalModelHealth } from '~/lib/hooks/useLocalModelHealth';

export function HealthMonitor() {
  const { healthStatuses, startMonitoring } = useLocalModelHealth();

  useEffect(() => {
    startMonitoring([
      { provider: 'Ollama', baseUrl: 'http://localhost:11434' }
    ]);
  }, []);

  return <StatusDashboard statuses={healthStatuses} />;
}
```

**Step 5: Add Debug Log Export**
```typescript
// In your settings dropdown or dev tools
import { downloadDebugLog } from '~/utils/debugLogger';

function SettingsMenu() {
  const handleDownloadLogs = async () => {
    await downloadDebugLog('debug-logs.txt');
  };

  return (
    <button onClick={handleDownloadLogs}>
      Download Debug Logs
    </button>
  );
}
```

---

## API Reference

### Logger API

```typescript
// Global logger
logger.trace(message: string, ...args: any[]): void
logger.debug(message: string, ...args: any[]): void
logger.info(message: string, ...args: any[]): void
logger.warn(message: string, ...args: any[]): void
logger.error(message: string, ...args: any[]): void

// Scoped logger
createScopedLogger(scope: string): Logger
```

### Debug Logger API

```typescript
// Enable/disable
enableDebugMode(): void
disableDebugMode(): void

// Configuration
updateDebugConfig(config: Partial<DebugConfig>): void

// Capture custom events
captureUserAction(action: string, metadata?: any): void
captureTerminalLog(log: string): void

// Export
downloadDebugLog(filename?: string): Promise<void>
debugLogger.getDebugLog(): DebugLogData
```

### Log Store API

```typescript
// Logging methods
logStore.logSystem(message: string, metadata?: any): void
logStore.logProvider(provider: string, message: string, metadata?: any): void
logStore.logUserAction(action: string, metadata?: any): void
logStore.logAPIRequest(params: APIRequestParams): void
logStore.logError(message: string, error: Error, component?: string): void
logStore.logPerformance(params: PerformanceParams): void
logStore.logAuth(event: string, metadata?: any): void
logStore.logNetworkStatus(status: 'online' | 'offline'): void

// Read operations
logStore.getLogs(): LogEntry[]
logStore.getFilteredLogs(filter: LogFilter): LogEntry[]
logStore.markAsRead(id: string): void
logStore.markAllAsRead(): void
logStore.exportLogs(): string  // JSON string
```

### Health Monitor API

```typescript
// Instance methods
monitor.startMonitoring(providers: ProviderConfig[], interval?: number): void
monitor.stopMonitoring(): void
monitor.performHealthCheck(provider: string, baseUrl: string): Promise<ModelHealthStatus>
monitor.getAllHealthStatuses(): Map<string, ModelHealthStatus>

// Events
monitor.on('statusChanged', (status: ModelHealthStatus) => void)
monitor.off('statusChanged', callback)
```

---

## Best Practices

### 1. Log Levels
- **trace**: Extremely detailed debugging (function entry/exit)
- **debug**: Detailed debugging information
- **info**: General informational messages (default for production)
- **warn**: Warning messages (deprecated APIs, potential issues)
- **error**: Error messages (exceptions, failures)

### 2. Scoped Logging
Always use scoped loggers for better log organization:
```typescript
// ✅ Good
const logger = createScopedLogger('UserService');
logger.info('User created', { userId });

// ❌ Bad
console.log('User created', userId);
```

### 3. Error Logging
Always log errors with context:
```typescript
// ✅ Good
try {
  await fetchData();
} catch (error) {
  logger.error('Failed to fetch data', error, { userId, endpoint });
  logStore.logError('Data fetch failed', error, 'DataService');
}

// ❌ Bad
try {
  await fetchData();
} catch (error) {
  console.error(error);
}
```

### 4. Performance Logging
Log performance metrics for slow operations:
```typescript
const startTime = performance.now();
await expensiveOperation();
const duration = performance.now() - startTime;

if (duration > 1000) {
  logStore.logPerformance({
    metric: 'expensive_operation',
    value: duration,
    metadata: { userId, params }
  });
}
```

### 5. Health Monitoring
Monitor critical external services:
```typescript
// ✅ Monitor all external dependencies
startMonitoring([
  { provider: 'Database', baseUrl: 'postgresql://...' },
  { provider: 'Cache', baseUrl: 'redis://...' },
  { provider: 'AI Model', baseUrl: 'http://localhost:11434' }
]);
```

### 6. Memory Management
- The system uses circular buffers (max 1000 entries) to prevent memory leaks
- Logs are automatically trimmed when capacity is exceeded
- Cookie storage is limited; consider periodic cleanup for long-running sessions

### 7. Privacy Considerations
- Avoid logging sensitive data (passwords, tokens, PII)
- Sanitize user data before logging
- Consider GDPR compliance for EU users

```typescript
// ✅ Good
logger.info('User logged in', { userId: hashUserId(userId) });

// ❌ Bad
logger.info('User logged in', { email: user.email, password: user.password });
```

### 8. Production vs Development
```typescript
if (import.meta.env.PROD) {
  // Disable verbose logging
  process.env.VITE_LOG_LEVEL = 'warn';
  disableDebugMode();
} else {
  // Enable all logging
  process.env.VITE_LOG_LEVEL = 'trace';
  enableDebugMode();
}
```

---

## Troubleshooting

### Issue: Logs not appearing
- Check `VITE_LOG_LEVEL` environment variable
- Verify debug mode is enabled: `enableDebugMode()`
- Check console for errors

### Issue: Memory consumption high
- Verify circular buffers are working
- Check log count: `debugLogger.getDebugLog().logs.length`
- Should never exceed 1000 entries per buffer

### Issue: Health checks failing
- Verify service URLs are correct
- Check CORS configuration for cross-origin requests
- Increase timeout if needed (default: 10 seconds)

### Issue: Debug logs not downloading
- Check browser permissions for file downloads
- Verify blob creation support
- Check for JavaScript errors in console

---

## Performance Impact

- **Logger**: Negligible (~0.1ms per log call)
- **DebugLogger**: Low (~1-2ms per captured event)
- **Health Monitor**: Low (30-second intervals, async)
- **Connection Monitor**: Low (10-second intervals, HEAD requests)
- **Memory Usage**: ~2-5MB for full debug capture with 1000 entries per buffer

---

## License

Extracted from bolt.diy (MIT License)

---

## Support

For issues or questions:
1. Check examples in `examples/usage-examples.md`
2. Review source code comments
3. Refer to bolt.diy original implementation

---

**Version:** 1.0.0
**Last Updated:** 2025-11-14
**Extracted From:** bolt.diy (https://github.com/stackblitz/bolt.diy)
