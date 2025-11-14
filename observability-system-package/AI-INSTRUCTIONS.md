# AI Implementation Instructions for Observability System

**Target Audience:** AI Assistants (Claude, GPT-4, etc.)
**Purpose:** Step-by-step instructions for implementing the bolt.diy observability system in a new project

---

## 🎯 Overview

You are helping implement a production-grade observability system extracted from bolt.diy. This system provides comprehensive logging, monitoring, health checks, and error tracking without requiring third-party services.

---

## 📦 Package Contents

```
observability-system-package/
├── README.md                     # Complete documentation
├── AI-INSTRUCTIONS.md            # This file
├── IMPLEMENTATION-GUIDE.md       # Step-by-step implementation
├── MIGRATION-GUIDE.md            # Migration from existing systems
├── source-files/                 # All source code
│   ├── logger.ts                 # Core logger
│   ├── debugLogger.ts            # Advanced debug capture
│   ├── logs.ts                   # Event store
│   ├── localModelHealthMonitor.ts # Health monitoring
│   ├── hooks/                    # React hooks
│   ├── components/               # UI components
│   └── api/                      # API utilities
└── examples/                     # Usage examples
```

---

## 🚀 Implementation Workflow

Follow these steps in order:

### Step 1: Analyze the Target Project

**Tasks:**
1. Identify the project structure (framework, folder layout)
2. Detect existing observability systems
3. Check dependencies and package manager
4. Determine TypeScript/JavaScript usage
5. Identify state management solution (if any)

**Questions to Ask User:**
- "What framework are you using? (React, Vue, Next.js, Remix, etc.)"
- "Do you have an existing logging or error tracking system?"
- "Are you using TypeScript or JavaScript?"
- "What package manager do you use? (npm, yarn, pnpm, bun)"

**AI Actions:**
```bash
# Scan project structure
ls -la
cat package.json | grep -E "(react|vue|next|remix|vite|webpack)"

# Check for existing observability tools
grep -r "sentry\|datadog\|rollbar\|winston\|pino" package.json
grep -r "console.log\|console.error" --include="*.{ts,tsx,js,jsx}" | wc -l
```

### Step 2: Assess Compatibility

**Framework Compatibility Matrix:**

| Framework | Compatibility | Notes |
|-----------|--------------|-------|
| React 18+ | ✅ Full | Native support |
| Next.js 13+ | ✅ Full | Use in client components |
| Remix | ✅ Full | Works with loader/action patterns |
| Vue 3 | ⚠️ Partial | Requires Vue-specific adapters |
| Svelte | ⚠️ Partial | Requires Svelte-specific adapters |
| Vanilla JS | ✅ Full | Use core utilities only |
| Node.js | ✅ Partial | Server-side logging only |

**Browser Requirements:**
- Modern browsers (Chrome 90+, Firefox 88+, Safari 14+)
- `fetch()`, `performance.now()`, `localStorage`, `EventTarget`

**AI Actions:**
```typescript
// Check browser compatibility
const isCompatible =
  typeof fetch !== 'undefined' &&
  typeof performance !== 'undefined' &&
  typeof localStorage !== 'undefined';

if (!isCompatible) {
  console.warn('Browser compatibility issues detected');
}
```

### Step 3: Prepare for Installation

**Before installing, check for conflicts:**

1. **Existing logging libraries:**
   - winston
   - pino
   - bunyan
   - log4js

2. **Error tracking services:**
   - Sentry (@sentry/react, @sentry/node)
   - Rollbar
   - Bugsnag
   - DataDog

3. **State management conflicts:**
   - Check if nanostores is already used
   - Check for Redux, Zustand, MobX

**AI Decision Tree:**

```
Does project have Sentry/Rollbar/DataDog?
├─ YES → Ask: "Keep existing or replace?"
│   ├─ Keep → Integrate alongside (use INTEGRATION-WITH-EXISTING.md)
│   └─ Replace → Follow MIGRATION-GUIDE.md
└─ NO → Proceed with full installation
```

**User Questions:**
- "I found [Sentry/other service]. Do you want to keep it or replace it?"
- "You have [winston/pino]. Should I integrate or replace?"
- "I see custom logging. Should I migrate to the new system?"

### Step 4: Install Dependencies

**AI Actions:**
```bash
# Detect package manager
if [ -f "pnpm-lock.yaml" ]; then
  PKG_MGR="pnpm"
elif [ -f "yarn.lock" ]; then
  PKG_MGR="yarn"
elif [ -f "bun.lockb" ]; then
  PKG_MGR="bun"
else
  PKG_MGR="npm"
fi

# Install required dependencies
$PKG_MGR install chalk nanostores
$PKG_MGR install -D @types/node
```

**Verify installation:**
```bash
grep -E "(chalk|nanostores)" package.json
```

### Step 5: Copy Core Files

**Minimal Setup (Logging only):**
```bash
# Create directories
mkdir -p src/utils src/lib/stores

# Copy core files
cp observability-system-package/source-files/logger.ts src/utils/
cp observability-system-package/source-files/debugLogger.ts src/utils/
cp observability-system-package/source-files/logs.ts src/lib/stores/
```

**Full Setup (All features):**
```bash
# Create directory structure
mkdir -p src/{utils,lib/{stores,services,api,hooks},components}

# Copy all files
cp observability-system-package/source-files/logger.ts src/utils/
cp observability-system-package/source-files/debugLogger.ts src/utils/
cp observability-system-package/source-files/logs.ts src/lib/stores/
cp observability-system-package/source-files/localModelHealthMonitor.ts src/lib/services/

# Copy hooks
cp observability-system-package/source-files/hooks/* src/lib/hooks/

# Copy API utilities
cp observability-system-package/source-files/api/* src/lib/api/

# Copy components (if React project)
cp observability-system-package/source-files/components/* src/components/
```

**AI Decision Logic:**
```typescript
if (userWants === 'minimal') {
  copyFiles(['logger.ts', 'debugLogger.ts', 'logs.ts']);
} else if (userWants === 'monitoring') {
  copyFiles(['logger.ts', 'debugLogger.ts', 'logs.ts', 'localModelHealthMonitor.ts', 'connection.ts']);
} else {
  copyAllFiles();
}
```

### Step 6: Adjust Import Paths

**Common Import Path Patterns:**

| Project Type | Import Path Pattern |
|--------------|-------------------|
| Vite/React | `~/utils/logger` or `@/utils/logger` |
| Next.js | `@/utils/logger` |
| Remix | `~/utils/logger` |
| Create React App | Relative: `../../utils/logger` |

**AI Actions:**
```bash
# Detect path alias from tsconfig.json or vite.config
cat tsconfig.json | grep -A 5 "paths"

# Common aliases to check:
# ~/* → src/*
# @/* → src/*
# $/* → src/*
```

**Update imports in copied files:**
```typescript
// Example: Change from ~/utils/logger to @/utils/logger
sed -i "s|from '~/|from '@/|g" src/**/*.{ts,tsx}

// Or update to relative paths
sed -i "s|from '~/utils/logger'|from '../utils/logger'|g" src/**/*.{ts,tsx}
```

**AI Prompt:**
"I'll update the import paths to match your project's alias configuration. I found that you use `@/` for the src directory."

### Step 7: Configure Environment Variables

**Create or update .env file:**
```bash
# Add to .env
cat >> .env << 'EOF'

# Observability System Configuration
VITE_LOG_LEVEL=debug    # For Vite projects
# or
NEXT_PUBLIC_LOG_LEVEL=debug    # For Next.js
# or
LOG_LEVEL=debug    # For other projects

# Options: trace | debug | info | warn | error | none
EOF
```

**For different frameworks:**

| Framework | Variable Prefix |
|-----------|----------------|
| Vite | `VITE_` |
| Next.js | `NEXT_PUBLIC_` |
| Create React App | `REACT_APP_` |
| Remix | (no prefix) |

**AI Actions:**
```typescript
// Detect framework and suggest correct prefix
const framework = detectFramework();
const prefix = {
  'vite': 'VITE_',
  'next': 'NEXT_PUBLIC_',
  'cra': 'REACT_APP_',
  'remix': ''
}[framework];

console.log(`Use ${prefix}LOG_LEVEL in your .env file`);
```

### Step 8: Initialize in Application Entry Point

**Locate entry point:**
```bash
# Common entry points:
# - src/main.tsx (Vite)
# - src/index.tsx (CRA)
# - app/root.tsx (Remix)
# - app/layout.tsx (Next.js App Router)
# - pages/_app.tsx (Next.js Pages Router)

find src app -name "main.tsx" -o -name "index.tsx" -o -name "root.tsx" -o -name "_app.tsx" -o -name "layout.tsx"
```

**Add initialization code:**

For **Vite/React:**
```typescript
// src/main.tsx
import { logger } from '~/utils/logger';
import { enableDebugMode } from '~/utils/debugLogger';

// Enable debug mode in development
if (import.meta.env.DEV) {
  enableDebugMode();
  logger.info('Debug mode enabled');
}

logger.info('Application starting');

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

For **Next.js (App Router):**
```typescript
// app/layout.tsx
'use client';

import { useEffect } from 'react';
import { logger } from '@/utils/logger';
import { enableDebugMode } from '@/utils/debugLogger';

export default function RootLayout({ children }) {
  useEffect(() => {
    if (process.env.NODE_ENV === 'development') {
      enableDebugMode();
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

For **Remix:**
```typescript
// app/root.tsx
import { useEffect } from 'react';
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
    <html>
      <head />
      <body>
        <Outlet />
      </body>
    </html>
  );
}
```

### Step 9: Add Error Boundary

**For React 18+:**
```typescript
// src/components/ErrorBoundary.tsx
import React, { Component, ErrorInfo, ReactNode } from 'react';
import { logger } from '~/utils/logger';
import { logStore } from '~/lib/stores/logs';

interface Props {
  children: ReactNode;
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
    logger.error('Error caught by boundary:', error, errorInfo);
    logStore.logError('Application error', error, 'ErrorBoundary');
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{ padding: '20px', textAlign: 'center' }}>
          <h1>Something went wrong</h1>
          <button onClick={() => this.setState({ hasError: false })}>
            Try again
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}
```

**Wrap your app:**
```typescript
// In your root component
import { ErrorBoundary } from './components/ErrorBoundary';

function App() {
  return (
    <ErrorBoundary>
      <YourApp />
    </ErrorBoundary>
  );
}
```

### Step 10: Replace Existing console.log Calls (Optional)

**AI can help automate this:**

```bash
# Find all console.log calls
grep -r "console\.(log|error|warn)" --include="*.{ts,tsx,js,jsx}" src/

# Show user the count
COUNT=$(grep -r "console\.(log|error|warn)" --include="*.{ts,tsx,js,jsx}" src/ | wc -l)
echo "Found $COUNT console statements to migrate"
```

**AI Prompt to User:**
"I found 247 console.log statements in your codebase. Would you like me to:
1. Keep them as-is (logger will capture them automatically)
2. Migrate them to use the new logger
3. Migrate only specific files/folders"

**If user chooses migration:**
```typescript
// Example migration pattern
// Before:
console.log('User logged in', userId);

// After:
import { createScopedLogger } from '~/utils/logger';
const logger = createScopedLogger('AuthService');
logger.info('User logged in', { userId });
```

**Automated migration (careful!):**
```typescript
// AI can help with this, but should ask for confirmation first
// Example for a single file:

// 1. Add import at top
// 2. Create scoped logger
// 3. Replace console.log → logger.info
// 4. Replace console.error → logger.error
// 5. Replace console.warn → logger.warn
```

### Step 11: Test the Installation

**AI should verify:**

1. **Build succeeds:**
```bash
npm run build
# or: pnpm build, yarn build, bun build
```

2. **No TypeScript errors:**
```bash
npx tsc --noEmit
```

3. **Logs appear in console:**
```typescript
// Add test code temporarily
import { logger } from '~/utils/logger';
logger.info('Test log from observability system');
```

4. **Debug log download works:**
```typescript
import { downloadDebugLog } from '~/utils/debugLogger';
await downloadDebugLog('test-log.txt');
```

**AI Checklist:**
- [ ] Dependencies installed successfully
- [ ] Files copied to correct locations
- [ ] Import paths updated
- [ ] Environment variables configured
- [ ] Application builds without errors
- [ ] Logs appear in browser console
- [ ] Error boundary catches test errors
- [ ] Debug log download works

### Step 12: Advanced Features (Optional)

**If user wants health monitoring:**
```typescript
// Set up health monitoring
import { useLocalModelHealth } from '~/lib/hooks/useLocalModelHealth';

function HealthMonitor() {
  const { healthStatuses, startMonitoring } = useLocalModelHealth();

  useEffect(() => {
    startMonitoring([
      { provider: 'API', baseUrl: 'https://api.example.com' }
    ]);
  }, []);

  return <div>Status: {healthStatuses.get('API')?.status}</div>;
}
```

**If user wants connection monitoring:**
```typescript
import { useConnectionStatus } from '~/lib/hooks/useConnectionStatus';

function ConnectionAlert() {
  const { issue, acknowledgeIssue } = useConnectionStatus();

  if (issue === 'disconnected') {
    return (
      <Alert onDismiss={acknowledgeIssue}>
        No internet connection
      </Alert>
    );
  }

  return null;
}
```

**If user wants notification center:**
```typescript
import { useNotifications } from '~/lib/hooks/useNotifications';

function NotificationCenter() {
  const { notifications, unreadCount, markAsRead } = useNotifications();

  return (
    <div>
      <Badge count={unreadCount} />
      {notifications.map(n => (
        <Notification key={n.id} data={n} onRead={() => markAsRead(n.id)} />
      ))}
    </div>
  );
}
```

---

## 🔧 Common Issues & Solutions

### Issue 1: Import Path Errors

**Error:**
```
Cannot find module '~/utils/logger'
```

**AI Solution:**
```bash
# Check tsconfig.json for path aliases
cat tsconfig.json | grep -A 10 "paths"

# Update tsconfig.json if needed
{
  "compilerOptions": {
    "paths": {
      "~/*": ["./src/*"]
    }
  }
}

# Or update imports to relative paths
sed -i "s|from '~/|from '../|g" src/**/*.ts
```

### Issue 2: Chalk Import Error (ESM vs CommonJS)

**Error:**
```
require() of ES Module not supported
```

**AI Solution:**
```json
// package.json
{
  "type": "module"
}

// Or use dynamic import
const chalk = await import('chalk');
```

### Issue 3: nanostores Type Errors

**Error:**
```
Property '$logs' does not exist on type 'WritableAtom'
```

**AI Solution:**
```bash
# Ensure @types/node is installed
npm install -D @types/node

# Check nanostores version
npm list nanostores
# Should be >= 0.10.0
```

### Issue 4: localStorage Not Available (SSR)

**Error:**
```
ReferenceError: localStorage is not defined
```

**AI Solution:**
```typescript
// Add guards for SSR
const isBrowser = typeof window !== 'undefined';

function saveToStorage(key: string, value: any) {
  if (!isBrowser) return;
  localStorage.setItem(key, JSON.stringify(value));
}
```

### Issue 5: Performance Issues

**Symptom:** App feels slow after installation

**AI Solution:**
```typescript
// Reduce debug capture in production
if (import.meta.env.PROD) {
  debugLogger.updateConfig({
    captureConsole: false,
    captureNetwork: false,
    captureErrors: true  // Keep error capture
  });
}

// Disable debug mode entirely
disableDebugMode();
```

---

## 📝 Post-Installation Checklist

**AI should confirm with user:**

- [ ] All files copied successfully
- [ ] Dependencies installed
- [ ] Import paths working
- [ ] Environment variables set
- [ ] Application builds without errors
- [ ] Logs visible in console
- [ ] Error boundary tested
- [ ] Debug log download tested
- [ ] No performance degradation
- [ ] Existing functionality unaffected

---

## 🎓 Teaching the User

**AI should explain:**

1. **How to use the logger:**
```typescript
import { createScopedLogger } from '~/utils/logger';
const logger = createScopedLogger('MyComponent');

logger.info('This is informational');
logger.error('This is an error', error);
```

2. **How to access logs:**
- Console: Open DevTools
- Event logs: Add EventLogsTab component
- Debug export: Call `downloadDebugLog()`

3. **How to monitor health:**
```typescript
// Set up monitoring for external services
const monitor = new LocalModelHealthMonitor();
monitor.startMonitoring([
  { provider: 'API', baseUrl: 'https://api.example.com' }
]);
```

4. **How to customize:**
- Log levels via environment variables
- Circular buffer size in debugLogger.ts
- Health check intervals
- Connection check intervals

---

## 🚨 Migration from Existing Systems

**If user has Sentry:**
```typescript
// Option 1: Keep both
import * as Sentry from '@sentry/react';
import { logStore } from '~/lib/stores/logs';

// Log to both systems
try {
  await operation();
} catch (error) {
  Sentry.captureException(error);
  logStore.logError('Operation failed', error, 'Service');
}

// Option 2: Replace Sentry
// See MIGRATION-GUIDE.md for full instructions
```

**If user has Winston/Pino:**
```typescript
// Option 1: Adapter pattern
import winston from 'winston';
import { logger } from '~/utils/logger';

// Bridge winston to our logger
const winstonToLogger = winston.createLogger({
  transports: [
    new winston.transports.Console({
      log(info, callback) {
        logger[info.level](info.message, info);
        callback();
      }
    })
  ]
});

// Option 2: Gradual migration
// Migrate one module at a time
```

---

## 💡 AI Best Practices When Implementing

1. **Always ask before replacing existing systems**
2. **Test after each major step**
3. **Provide clear explanations for each action**
4. **Show examples of how to use the system**
5. **Warn about potential breaking changes**
6. **Offer rollback instructions**
7. **Document any custom adaptations needed**
8. **Verify TypeScript types are correct**
9. **Check for framework-specific issues (SSR, etc.)**
10. **Explain the benefit of each component**

---

## 📚 Additional Resources

- **README.md**: Complete system documentation
- **IMPLEMENTATION-GUIDE.md**: Detailed step-by-step guide
- **MIGRATION-GUIDE.md**: Migrate from existing systems
- **examples/**: Usage examples for common scenarios
- **source-files/**: Original source code with comments

---

## 🎯 Success Criteria

The implementation is successful when:

1. ✅ Application builds without errors
2. ✅ Logs appear in console with colors
3. ✅ Debug logs can be downloaded
4. ✅ Error boundaries catch and log errors
5. ✅ No performance regression
6. ✅ User understands how to use the system
7. ✅ All existing features still work

---

**Remember:** This is a production system. Take time to understand each component before implementing. Ask the user questions when uncertain.

**Good luck! 🚀**
