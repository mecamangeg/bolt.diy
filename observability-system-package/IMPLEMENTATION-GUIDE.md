# Implementation Guide - Bolt.diy Observability System

Step-by-step guide for implementing the observability system in your project.

---

## 🎯 Prerequisites

Before starting, ensure you have:

- [ ] Node.js 18+ installed
- [ ] A modern package manager (npm, yarn, pnpm, or bun)
- [ ] A React 18+ application (or compatible framework)
- [ ] TypeScript support (recommended)
- [ ] Basic understanding of React hooks and context

---

## 📦 Installation Methods

Choose the installation method that best fits your needs:

### Method 1: Minimal Setup (Logging Only)
**Time:** ~10 minutes
**Best for:** Small projects, quick wins, gradual adoption

### Method 2: Standard Setup (Logging + Monitoring)
**Time:** ~20 minutes
**Best for:** Most applications, production-ready logging

### Method 3: Full Setup (All Features)
**Time:** ~30 minutes
**Best for:** Complex applications, comprehensive observability

---

## Method 1: Minimal Setup

### Step 1: Install Dependencies

```bash
# Using npm
npm install chalk nanostores

# Using yarn
yarn add chalk nanostores

# Using pnpm
pnpm add chalk nanostores

# Using bun
bun add chalk nanostores

# Install dev dependencies
npm install -D @types/node
```

### Step 2: Create Directory Structure

```bash
mkdir -p src/utils src/lib/stores
```

### Step 3: Copy Core Files

```bash
cp observability-system-package/source-files/logger.ts src/utils/
cp observability-system-package/source-files/debugLogger.ts src/utils/
cp observability-system-package/source-files/logs.ts src/lib/stores/
```

### Step 4: Update Import Paths

Open each copied file and update imports based on your project's path alias:

**If using `~/` alias:**
```typescript
// No changes needed
import { logger } from '~/utils/logger';
```

**If using `@/` alias:**
```typescript
// Find and replace all instances
// From: ~/utils/logger
// To: @/utils/logger
```

**If using relative paths:**
```typescript
// Change based on file location
// From: ~/utils/logger
// To: ../../utils/logger
```

**Quick find-and-replace (Linux/Mac):**
```bash
# Change ~/ to @/
find src -name "*.ts" -o -name "*.tsx" | xargs sed -i '' "s|'~/|'@/|g"

# Or change to relative (be careful with this!)
# Manual update recommended
```

### Step 5: Configure Environment

Create or update your `.env` file:

```bash
# For Vite projects
VITE_LOG_LEVEL=debug

# For Next.js projects
NEXT_PUBLIC_LOG_LEVEL=debug

# For Create React App
REACT_APP_LOG_LEVEL=debug

# Options: trace | debug | info | warn | error | none
```

### Step 6: Initialize in Entry Point

**For Vite + React:**

```typescript
// src/main.tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import { logger } from './utils/logger';
import { enableDebugMode } from './utils/debugLogger';

// Enable debug mode in development
if (import.meta.env.DEV) {
  enableDebugMode();
  logger.info('Debug mode enabled');
}

logger.info('Application initializing...');

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

**For Next.js (App Router):**

```typescript
// app/layout.tsx
'use client';

import { useEffect } from 'react';
import { logger } from '@/utils/logger';
import { enableDebugMode } from '@/utils/debugLogger';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  useEffect(() => {
    if (process.env.NODE_ENV === 'development') {
      enableDebugMode();
      logger.info('Debug mode enabled');
    }
    logger.info('Application initialized');
  }, []);

  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
```

**For Remix:**

```typescript
// app/root.tsx
import { useEffect } from 'react';
import { Outlet } from '@remix-run/react';
import { logger } from '~/utils/logger';
import { enableDebugMode } from '~/utils/debugLogger';

export default function App() {
  useEffect(() => {
    if (process.env.NODE_ENV === 'development') {
      enableDebugMode();
    }
    logger.info('Application initialized');
  }, []);

  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
      </head>
      <body>
        <Outlet />
      </body>
    </html>
  );
}
```

### Step 7: Start Using the Logger

**Basic usage in components:**

```typescript
// src/components/MyComponent.tsx
import { createScopedLogger } from '~/utils/logger';
import { logStore } from '~/lib/stores/logs';

const logger = createScopedLogger('MyComponent');

export function MyComponent() {
  useEffect(() => {
    logger.info('Component mounted');
    logStore.logSystem('MyComponent mounted');
  }, []);

  const handleClick = async () => {
    try {
      logger.debug('Button clicked');
      logStore.logUserAction('Button clicked', { buttonId: 'submit' });

      await someAsyncOperation();

      logger.info('Operation successful');
    } catch (error) {
      logger.error('Operation failed', error);
      logStore.logError('Operation failed', error as Error, 'MyComponent');
    }
  };

  return <button onClick={handleClick}>Click me</button>;
}
```

### Step 8: Test the Installation

1. **Build your project:**
```bash
npm run build
```

2. **Start dev server:**
```bash
npm run dev
```

3. **Check console output:**
- You should see colored log messages
- Debug mode should be active (in development)

4. **Test debug log download:**
```typescript
// Add temporarily to test
import { downloadDebugLog } from '~/utils/debugLogger';

// In a button click handler
const handleDownload = async () => {
  await downloadDebugLog('test-log.txt');
};
```

**✅ Minimal Setup Complete!**

You now have:
- Color-coded console logging
- Debug log capture and export
- Event logging with persistence

---

## Method 2: Standard Setup

Follow **Method 1** first, then continue:

### Step 9: Add Health Monitoring

```bash
# Create services directory
mkdir -p src/lib/services src/lib/hooks src/lib/api

# Copy health monitoring files
cp observability-system-package/source-files/localModelHealthMonitor.ts src/lib/services/
cp observability-system-package/source-files/hooks/useLocalModelHealth.ts src/lib/hooks/
cp observability-system-package/source-files/api/health.ts src/lib/api/
```

### Step 10: Add Connection Monitoring

```bash
cp observability-system-package/source-files/api/connection.ts src/lib/api/
cp observability-system-package/source-files/hooks/useConnectionStatus.ts src/lib/hooks/
cp observability-system-package/source-files/hooks/useConnectionTest.ts src/lib/hooks/
```

### Step 11: Create Health Check Endpoint

**For Remix:**
```typescript
// app/routes/api.health.ts
import type { LoaderFunction } from '@remix-run/node';
import { json } from '@remix-run/node';

export const loader: LoaderFunction = async () => {
  return json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
  });
};
```

**For Next.js (App Router):**
```typescript
// app/api/health/route.ts
import { NextResponse } from 'next/server';

export async function GET() {
  return NextResponse.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
  });
}
```

**For Next.js (Pages Router):**
```typescript
// pages/api/health.ts
import type { NextApiRequest, NextApiResponse } from 'next';

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
  });
}
```

### Step 12: Implement Health Monitoring UI

```typescript
// src/components/HealthStatus.tsx
import { useEffect } from 'react';
import { useLocalModelHealth } from '~/lib/hooks/useLocalModelHealth';

export function HealthStatus() {
  const {
    healthStatuses,
    isMonitoring,
    startMonitoring,
    stopMonitoring,
    overallHealth,
  } = useLocalModelHealth();

  useEffect(() => {
    // Monitor your API or services
    startMonitoring([
      { provider: 'API', baseUrl: '/api' },
      // Add more services as needed
    ]);

    return () => stopMonitoring();
  }, []);

  if (!isMonitoring) return null;

  return (
    <div className="health-status">
      <h3>System Health</h3>
      <p>
        {overallHealth.healthy} / {overallHealth.total} services healthy
      </p>
      <ul>
        {Array.from(healthStatuses.values()).map((status) => (
          <li key={status.provider} className={`status-${status.status}`}>
            <strong>{status.provider}:</strong> {status.status}
            {status.responseTime && <span> ({status.responseTime}ms)</span>}
          </li>
        ))}
      </ul>
    </div>
  );
}
```

### Step 13: Add Connection Status Alert

```typescript
// src/components/ConnectionAlert.tsx
import { useConnectionStatus } from '~/lib/hooks/useConnectionStatus';

export function ConnectionAlert() {
  const { issue, acknowledgeIssue, connectionStatus } = useConnectionStatus();

  if (!issue) return null;

  return (
    <div className="alert alert-warning">
      {issue === 'disconnected' && (
        <>
          <strong>No Internet Connection</strong>
          <p>You are currently offline. Some features may not work.</p>
        </>
      )}
      {issue === 'high-latency' && (
        <>
          <strong>Slow Connection</strong>
          <p>Your connection is slow ({connectionStatus.latency}ms). This may affect performance.</p>
        </>
      )}
      <button onClick={acknowledgeIssue}>Dismiss</button>
    </div>
  );
}
```

**Add to your layout:**
```typescript
// In your root layout/app component
import { ConnectionAlert } from '~/components/ConnectionAlert';

export default function App() {
  return (
    <div>
      <ConnectionAlert />
      {/* Rest of your app */}
    </div>
  );
}
```

**✅ Standard Setup Complete!**

You now have:
- Everything from Minimal Setup
- Health monitoring for services
- Connection status monitoring
- Network latency detection

---

## Method 3: Full Setup

Follow **Method 2** first, then continue:

### Step 14: Add Error Boundaries

```bash
# Copy error boundary components
mkdir -p src/components/errors

cp observability-system-package/source-files/components/ErrorBoundary-Generic.tsx src/components/errors/ErrorBoundary.tsx
```

**Update imports in ErrorBoundary.tsx** to match your project.

**Wrap your app:**
```typescript
// src/App.tsx or app/root.tsx
import { ErrorBoundary } from '~/components/errors/ErrorBoundary';

export default function App() {
  return (
    <ErrorBoundary>
      <YourAppComponents />
    </ErrorBoundary>
  );
}
```

### Step 15: Add Notification System

```bash
cp observability-system-package/source-files/api/notifications.ts src/lib/api/
cp observability-system-package/source-files/hooks/useNotifications.ts src/lib/hooks/
```

**Create notification UI:**
```typescript
// src/components/NotificationCenter.tsx
import { useNotifications } from '~/lib/hooks/useNotifications';

export function NotificationCenter() {
  const { notifications, unreadCount, markAsRead, markAllAsRead } = useNotifications();

  return (
    <div className="notification-center">
      <div className="notification-header">
        <h3>Notifications</h3>
        {unreadCount > 0 && <span className="badge">{unreadCount}</span>}
        {unreadCount > 0 && (
          <button onClick={markAllAsRead}>Mark All Read</button>
        )}
      </div>
      <div className="notification-list">
        {notifications.length === 0 && <p>No notifications</p>}
        {notifications.map((notification) => (
          <div
            key={notification.id}
            className={`notification notification-${notification.level}`}
            onClick={() => markAsRead(notification.id)}
          >
            <span className="notification-level">{notification.level}</span>
            <div className="notification-content">
              <p className="notification-message">{notification.message}</p>
              <small className="notification-time">
                {new Date(notification.timestamp).toLocaleString()}
              </small>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
```

### Step 16: Add Debug Log Download UI

```typescript
// src/components/DebugLogDownload.tsx
import { downloadDebugLog } from '~/utils/debugLogger';

export function DebugLogDownload() {
  const [isDownloading, setIsDownloading] = useState(false);

  const handleDownload = async () => {
    setIsDownloading(true);
    try {
      await downloadDebugLog(`debug-log-${Date.now()}.txt`);
    } catch (error) {
      console.error('Failed to download debug log:', error);
    } finally {
      setIsDownloading(false);
    }
  };

  return (
    <button onClick={handleDownload} disabled={isDownloading}>
      {isDownloading ? 'Downloading...' : 'Download Debug Log'}
    </button>
  );
}
```

**Add to settings or dev tools:**
```typescript
// In your settings menu or developer tools panel
import { DebugLogDownload } from '~/components/DebugLogDownload';

function SettingsMenu() {
  return (
    <div>
      {/* Other settings */}
      <div className="developer-section">
        <h3>Developer Tools</h3>
        <DebugLogDownload />
      </div>
    </div>
  );
}
```

### Step 17: Create Event Logs Viewer (Optional)

```typescript
// src/components/EventLogsViewer.tsx
import { useState } from 'react';
import { logStore } from '~/lib/stores/logs';
import { useStore } from '@nanostores/react';

export function EventLogsViewer() {
  const [filter, setFilter] = useState<string>('all');
  const logs = useStore(logStore.$logs);

  const filteredLogs = logs.filter((log) => {
    if (filter === 'all') return true;
    if (filter === 'errors') return log.level === 'error';
    if (filter === 'warnings') return log.level === 'warning';
    if (filter === 'api') return log.category === 'api';
    return true;
  });

  return (
    <div className="event-logs-viewer">
      <div className="filter-bar">
        <button onClick={() => setFilter('all')}>All</button>
        <button onClick={() => setFilter('errors')}>Errors</button>
        <button onClick={() => setFilter('warnings')}>Warnings</button>
        <button onClick={() => setFilter('api')}>API Calls</button>
      </div>
      <div className="logs-list">
        {filteredLogs.map((log) => (
          <div key={log.id} className={`log-entry log-${log.level}`}>
            <span className="log-time">
              {new Date(log.timestamp).toLocaleTimeString()}
            </span>
            <span className="log-level">{log.level}</span>
            <span className="log-category">{log.category}</span>
            <span className="log-message">{log.message}</span>
            {log.component && (
              <span className="log-component">{log.component}</span>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
```

**✅ Full Setup Complete!**

You now have:
- Everything from Standard Setup
- Error boundaries for graceful error handling
- Notification center
- Debug log download UI
- Event logs viewer

---

## 🎨 Styling the Components

Add basic CSS for the components:

```css
/* src/styles/observability.css */

/* Health Status */
.health-status {
  padding: 1rem;
  background: #f5f5f5;
  border-radius: 8px;
}

.status-healthy {
  color: #22c55e;
}

.status-unhealthy {
  color: #ef4444;
}

.status-checking {
  color: #3b82f6;
}

/* Connection Alert */
.alert {
  padding: 1rem;
  margin: 1rem 0;
  border-radius: 4px;
}

.alert-warning {
  background: #fef3c7;
  border-left: 4px solid #f59e0b;
}

/* Notifications */
.notification-center {
  max-width: 400px;
}

.notification {
  padding: 0.75rem;
  margin: 0.5rem 0;
  border-left: 3px solid;
  cursor: pointer;
  background: white;
  border-radius: 4px;
}

.notification-error {
  border-left-color: #ef4444;
}

.notification-warning {
  border-left-color: #f59e0b;
}

.notification-info {
  border-left-color: #3b82f6;
}

.badge {
  display: inline-block;
  padding: 0.25rem 0.5rem;
  background: #ef4444;
  color: white;
  border-radius: 9999px;
  font-size: 0.75rem;
}

/* Event Logs Viewer */
.event-logs-viewer {
  font-family: monospace;
  font-size: 0.875rem;
}

.log-entry {
  padding: 0.5rem;
  border-bottom: 1px solid #e5e7eb;
}

.log-error {
  background: #fee2e2;
}

.log-warning {
  background: #fef3c7;
}

.log-level {
  display: inline-block;
  padding: 0.125rem 0.5rem;
  margin: 0 0.5rem;
  border-radius: 4px;
  font-weight: bold;
  text-transform: uppercase;
  font-size: 0.75rem;
}
```

---

## 🧪 Testing Your Implementation

### Test 1: Basic Logging
```typescript
import { logger } from '~/utils/logger';

logger.trace('Trace message');
logger.debug('Debug message');
logger.info('Info message');
logger.warn('Warning message');
logger.error('Error message');
```

**Expected:** Colored console output with all messages visible (if LOG_LEVEL=trace)

### Test 2: Scoped Logging
```typescript
import { createScopedLogger } from '~/utils/logger';

const logger = createScopedLogger('TestComponent');
logger.info('This should show [TestComponent] prefix');
```

**Expected:** Console output with `[TestComponent]` prefix

### Test 3: Event Logging
```typescript
import { logStore } from '~/lib/stores/logs';

logStore.logSystem('Test system event');
logStore.logError('Test error', new Error('Test'), 'TestComponent');

console.log('Total logs:', logStore.getLogs().length);
```

**Expected:** Logs stored and retrievable

### Test 4: Debug Log Download
```typescript
import { downloadDebugLog } from '~/utils/debugLogger';

await downloadDebugLog('test.txt');
```

**Expected:** File downloads with comprehensive debug information

### Test 5: Error Boundary
```typescript
function BuggyComponent() {
  throw new Error('Test error boundary');
  return <div>This won't render</div>;
}

function TestApp() {
  return (
    <ErrorBoundary>
      <BuggyComponent />
    </ErrorBoundary>
  );
}
```

**Expected:** Error boundary catches error, shows fallback UI

### Test 6: Health Monitoring
```typescript
const { healthStatuses, startMonitoring } = useLocalModelHealth();

startMonitoring([
  { provider: 'Test', baseUrl: '/api/health' }
]);

// Wait 5 seconds
setTimeout(() => {
  console.log('Health status:', healthStatuses.get('Test'));
}, 5000);
```

**Expected:** Health status updates after check interval

### Test 7: Connection Monitoring
```typescript
const { issue, connectionStatus } = useConnectionStatus();

console.log('Connection issue:', issue);
console.log('Connection status:', connectionStatus);
```

**Expected:** Connection status reflects actual network state

---

## 🔧 Configuration Options

### Environment Variables

```bash
# Log level (affects console output)
VITE_LOG_LEVEL=debug  # trace | debug | info | warn | error | none

# For production, use:
VITE_LOG_LEVEL=warn
```

### Debug Logger Configuration

```typescript
import { debugLogger } from '~/utils/debugLogger';

debugLogger.updateConfig({
  enabled: true,                 // Enable/disable debug capture
  captureConsole: true,          // Capture console.* calls
  captureNetwork: true,          // Capture fetch() requests
  captureErrors: true,           // Capture global errors
  terminalDebounceMs: 100,       // Debounce terminal logs
});
```

### Health Monitoring Intervals

```typescript
// Default: 30000ms (30 seconds)
startMonitoring(providers, 60000);  // Check every 60 seconds
```

### Connection Monitoring Intervals

```typescript
// In useConnectionStatus.ts, modify:
const checkInterval = 10000;  // Default: 10 seconds
```

### Log Storage Limits

```typescript
// In logs.ts, modify:
const MAX_LOGS = 1000;  // Default: 1000 entries
```

---

## 🚀 Next Steps

After completing the implementation:

1. **Customize the UI** to match your design system
2. **Add more logging** throughout your application
3. **Set up monitoring** for your critical services
4. **Configure alerts** for important errors
5. **Review logs regularly** to identify issues early
6. **Train your team** on how to use the system
7. **Document** your project-specific logging conventions

---

## 📚 Additional Resources

- See `README.md` for complete API reference
- See `MIGRATION-GUIDE.md` if replacing existing systems
- See `examples/` for more usage examples
- See source code comments for implementation details

---

**Congratulations! You've successfully implemented the bolt.diy observability system! 🎉**
