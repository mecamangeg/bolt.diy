# Migration Guide - Replacing Existing Observability Systems

This guide helps you migrate from existing observability and logging systems to the bolt.diy observability system.

---

## 📋 Table of Contents

1. [Migrating from Sentry](#migrating-from-sentry)
2. [Migrating from Winston/Pino](#migrating-from-winstonpino)
3. [Migrating from console.log](#migrating-from-consolelog)
4. [Migrating from DataDog/New Relic](#migrating-from-datadognew-relic)
5. [Coexistence Strategy](#coexistence-strategy)
6. [Rollback Plan](#rollback-plan)

---

## Migrating from Sentry

### Current State Analysis

First, identify how Sentry is used in your project:

```bash
# Find Sentry imports
grep -r "@sentry/react\|@sentry/node" --include="*.{ts,tsx,js,jsx}" src/

# Check Sentry configuration
cat src/sentry.ts 2>/dev/null || cat src/lib/sentry.ts 2>/dev/null
```

### Migration Options

#### Option 1: Full Replacement (Recommended for cost savings)

**Step 1: Audit Sentry Usage**

Create a list of all Sentry features you use:
- [ ] Error tracking
- [ ] Performance monitoring
- [ ] Custom events
- [ ] User context
- [ ] Breadcrumbs
- [ ] Source maps
- [ ] Release tracking
- [ ] Custom tags

**Step 2: Map to New System**

| Sentry Feature | Bolt.diy Equivalent |
|----------------|---------------------|
| `Sentry.captureException()` | `logStore.logError()` + `logger.error()` |
| `Sentry.captureMessage()` | `logger.info/warn()` + `logStore.logSystem()` |
| `Sentry.addBreadcrumb()` | `captureUserAction()` |
| `Sentry.setUser()` | `logStore.logAuth()` with userId |
| `Sentry.setTag()` | Metadata in log entries |
| `Sentry.setContext()` | Component name + metadata |
| Performance monitoring | `logStore.logPerformance()` |
| Session replay | Debug logger network capture |

**Step 3: Create Migration Helper**

```typescript
// src/lib/migration/sentryAdapter.ts
import { logger, createScopedLogger } from '~/utils/logger';
import { logStore } from '~/lib/stores/logs';

export const Sentry = {
  captureException: (error: Error, context?: any) => {
    logger.error('Error captured:', error, context);
    logStore.logError(
      error.message,
      error,
      context?.tags?.component || 'Unknown'
    );
  },

  captureMessage: (message: string, level: 'info' | 'warning' | 'error' = 'info') => {
    logger[level](message);
    const logLevel = level === 'warning' ? 'warning' : level === 'error' ? 'error' : 'info';
    logStore.log({
      level: logLevel,
      category: 'system',
      message,
    });
  },

  addBreadcrumb: (breadcrumb: { message: string; category?: string; data?: any }) => {
    if (breadcrumb.category === 'ui.click') {
      captureUserAction(breadcrumb.message, breadcrumb.data);
    } else {
      logger.debug('Breadcrumb:', breadcrumb.message, breadcrumb.data);
    }
  },

  setUser: (user: { id: string; email?: string; username?: string }) => {
    logger.info('User set:', user.id);
    logStore.logAuth('user_set', { userId: user.id });
  },

  setTag: (key: string, value: string) => {
    logger.debug(`Tag set: ${key}=${value}`);
    // Store in metadata for next log entry
  },

  setContext: (name: string, context: any) => {
    logger.debug(`Context set: ${name}`, context);
  },
};

// For components still using Sentry imports
export * from '~/lib/migration/sentryAdapter';
```

**Step 4: Update Imports (Gradual Migration)**

```typescript
// Before:
import * as Sentry from '@sentry/react';

Sentry.captureException(error);

// After (during migration):
import * as Sentry from '~/lib/migration/sentryAdapter';

Sentry.captureException(error);  // Now uses our system

// After (final state):
import { logger } from '~/utils/logger';
import { logStore } from '~/lib/stores/logs';

logger.error('Error occurred', error);
logStore.logError('Error occurred', error, 'ComponentName');
```

**Step 5: Remove Sentry Dependencies**

```bash
# After verifying migration works
npm uninstall @sentry/react @sentry/node

# Remove Sentry initialization
# Delete src/sentry.ts or similar files

# Remove from entry point
# Delete Sentry.init() calls
```

**Step 6: Cost Comparison**

| Service | Cost (Monthly) | Bolt.diy Cost |
|---------|---------------|---------------|
| Sentry Developer | $26/month | $0 |
| Sentry Team | $80/month | $0 |
| Sentry Business | $400/month | $0 |

**Savings:** $312 - $4,800/year depending on plan

---

#### Option 2: Coexistence (Keep both for transition period)

```typescript
// src/lib/observability.ts
import * as Sentry from '@sentry/react';
import { logger } from '~/utils/logger';
import { logStore } from '~/lib/stores/logs';

export function logError(error: Error, component?: string, context?: any) {
  // Log to both systems during transition
  Sentry.captureException(error, {
    tags: { component },
    extra: context,
  });

  logger.error('Error occurred', error, context);
  logStore.logError(error.message, error, component);
}

export function logEvent(event: string, metadata?: any) {
  // Log to both systems
  Sentry.captureMessage(event);

  logger.info(event, metadata);
  logStore.logSystem(event, metadata);
}
```

**Transition timeline:**
1. Week 1-2: Set up coexistence, validate data parity
2. Week 3-4: Monitor both systems, fix any gaps
3. Week 5: Disable Sentry in staging
4. Week 6: Disable Sentry in production
5. Week 7: Remove Sentry code and dependencies

---

## Migrating from Winston/Pino

### Current State Analysis

```bash
# Find Winston/Pino usage
grep -r "winston\|pino" --include="*.{ts,tsx,js,jsx}" src/

# Check logger configuration
cat src/lib/logger.ts 2>/dev/null || cat src/utils/logger.ts 2>/dev/null
```

### Migration Strategy

#### Step 1: Identify Logger Instances

**Winston:**
```typescript
// Before:
import winston from 'winston';

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
  ],
});

logger.info('Hello world');
logger.error('Error occurred', { error });
```

**Pino:**
```typescript
// Before:
import pino from 'pino';

const logger = pino({
  level: 'info',
  transport: {
    target: 'pino-pretty',
  },
});

logger.info('Hello world');
logger.error('Error occurred');
```

#### Step 2: Create Migration Adapter

```typescript
// src/lib/migration/loggerAdapter.ts
import { logger as newLogger, createScopedLogger } from '~/utils/logger';
import { logStore } from '~/lib/stores/logs';

interface LoggerInstance {
  trace: (message: string, ...args: any[]) => void;
  debug: (message: string, ...args: any[]) => void;
  info: (message: string, ...args: any[]) => void;
  warn: (message: string, ...args: any[]) => void;
  error: (message: string, ...args: any[]) => void;
}

export function createLogger(scope?: string): LoggerInstance {
  const scopedLogger = scope ? createScopedLogger(scope) : newLogger;

  return {
    trace: (message: string, ...args: any[]) => {
      scopedLogger.trace(message, ...args);
    },
    debug: (message: string, ...args: any[]) => {
      scopedLogger.debug(message, ...args);
    },
    info: (message: string, ...args: any[]) => {
      scopedLogger.info(message, ...args);
      logStore.logSystem(message, args[0]);
    },
    warn: (message: string, ...args: any[]) => {
      scopedLogger.warn(message, ...args);
      logStore.logWarning(message, args[0]);
    },
    error: (message: string, ...args: any[]) => {
      scopedLogger.error(message, ...args);
      if (args[0] instanceof Error) {
        logStore.logError(message, args[0], scope);
      }
    },
  };
}

// Default export for backward compatibility
export const logger = createLogger();
```

#### Step 3: Update Import Statements

**Option A: Find and Replace**
```bash
# Replace winston imports
find src -name "*.ts" -o -name "*.tsx" | xargs sed -i '' "s|import winston from 'winston'|import { createLogger } from '~/lib/migration/loggerAdapter'|g"

# Replace pino imports
find src -name "*.ts" -o -name "*.tsx" | xargs sed -i '' "s|import pino from 'pino'|import { createLogger } from '~/lib/migration/loggerAdapter'|g"
```

**Option B: Gradual Migration**
```typescript
// File 1: Keep old logger temporarily
import winston from 'winston';
const logger = winston.createLogger({ /* ... */ });

// File 2: Migrate to new system
import { createLogger } from '~/lib/migration/loggerAdapter';
const logger = createLogger('ServiceName');

// File 3: Direct usage (final state)
import { createScopedLogger } from '~/utils/logger';
const logger = createScopedLogger('ServiceName');
```

#### Step 4: Remove Old Dependencies

```bash
npm uninstall winston pino pino-pretty
```

#### Step 5: Benefits of Migration

| Feature | Winston/Pino | Bolt.diy Logger |
|---------|--------------|-----------------|
| Console output | ✅ | ✅ Color-coded |
| File logging | ✅ | ✅ Via electron-log (desktop) |
| Structured logging | ✅ | ✅ |
| Log levels | ✅ | ✅ |
| Scoped loggers | ✅ | ✅ |
| Browser integration | ❌ | ✅ Full capture |
| Debug log export | ❌ | ✅ One-click download |
| Event store | ❌ | ✅ Persistent logs |
| Network capture | ❌ | ✅ Automatic |
| Error capture | ❌ | ✅ Global handlers |
| Bundle size | 100KB+ | 20KB |

---

## Migrating from console.log

### Current State Analysis

```bash
# Count console statements
grep -r "console\.\(log\|error\|warn\|debug\|info\)" --include="*.{ts,tsx,js,jsx}" src/ | wc -l

# Get a breakdown by type
grep -r "console\.log" --include="*.{ts,tsx,js,jsx}" src/ | wc -l
grep -r "console\.error" --include="*.{ts,tsx,js,jsx}" src/ | wc -l
grep -r "console\.warn" --include="*.{ts,tsx,js,jsx}" src/ | wc -l
```

### Migration Strategy

#### Option 1: Automatic Capture (No Code Changes)

The debug logger automatically captures all console calls when enabled:

```typescript
// src/main.tsx
import { enableDebugMode } from '~/utils/debugLogger';

if (import.meta.env.DEV) {
  enableDebugMode();  // Captures all console.* calls
}

// Your existing console.log calls work as-is
console.log('This is captured automatically');
console.error('This error is captured automatically');
```

**Pros:**
- No code changes needed
- Works immediately
- Backward compatible

**Cons:**
- No structured logging
- No scoped loggers
- Less control over log metadata

#### Option 2: Manual Migration (Recommended for production)

**Step 1: Create Migration Script**

```typescript
// scripts/migrate-console-logs.ts
import { readFileSync, writeFileSync } from 'fs';
import { glob } from 'glob';

const files = glob.sync('src/**/*.{ts,tsx}');

files.forEach((file) => {
  let content = readFileSync(file, 'utf-8');

  // Add import if file has console statements
  if (/console\.(log|error|warn|debug|info)/.test(content)) {
    // Check if logger import already exists
    if (!/from ['"]~\/utils\/logger['"]/.test(content)) {
      // Add import at top (after other imports)
      content = content.replace(
        /(import .+;\n\n)/,
        "$1import { createScopedLogger } from '~/utils/logger';\n\n"
      );

      // Determine component/file name for scope
      const componentName = file
        .split('/')
        .pop()
        ?.replace(/\.(ts|tsx)$/, '');

      // Add logger creation
      content = content.replace(
        /(import .+;\n\n)/g,
        `$1const logger = createScopedLogger('${componentName}');\n\n`
      );
    }

    // Replace console calls
    content = content.replace(/console\.log\(/g, 'logger.info(');
    content = content.replace(/console\.error\(/g, 'logger.error(');
    content = content.replace(/console\.warn\(/g, 'logger.warn(');
    content = content.replace(/console\.debug\(/g, 'logger.debug(');
    content = content.replace(/console\.info\(/g, 'logger.info(');

    writeFileSync(file, content);
  }
});

console.log(`Migrated ${files.length} files`);
```

**Step 2: Run Migration Script**

```bash
# IMPORTANT: Commit your changes first!
git add .
git commit -m "Pre-migration checkpoint"

# Run migration
npx ts-node scripts/migrate-console-logs.ts

# Review changes
git diff

# If looks good, commit
git add .
git commit -m "Migrate console.log to logger"

# If not good, rollback
git reset --hard HEAD
```

**Step 3: Manual Cleanup**

The script is a starting point. Manually review and improve:

```typescript
// Before (auto-migrated):
logger.info('User logged in', userId);

// After (improved):
import { logStore } from '~/lib/stores/logs';

logger.info('User logged in', { userId, timestamp: Date.now() });
logStore.logAuth('user_login', { userId });
```

#### Option 3: Gradual Migration (File by File)

**Week 1: New code**
- All new code uses `logger` instead of `console.log`

**Week 2-4: High-priority files**
- Migrate authentication, payment, critical business logic

**Week 5-8: Medium-priority files**
- Migrate main user flows, common components

**Week 9+: Low-priority files**
- Migrate remaining files as time permits
- Consider leaving some console.debug calls for local development

---

## Migrating from DataDog/New Relic

### Current State Analysis

```bash
# Find DataDog
grep -r "datadog\|dd-trace" --include="*.{ts,tsx,js,jsx}" src/

# Find New Relic
grep -r "newrelic\|@newrelic" --include="*.{ts,tsx,js,jsx}" src/
```

### Migration Considerations

**What you'll lose:**
- Centralized cloud dashboard
- Historical data retention (years)
- Advanced querying and analytics
- APM (Application Performance Monitoring)
- Infrastructure monitoring
- Team collaboration features
- Alerting/paging integration

**What you'll gain:**
- $0 cost (vs $15-$450/month per host)
- No data sent to third parties (privacy)
- Faster performance (no network calls)
- Full control over data
- Client-side visibility (browser logs)

### Decision Matrix

| Use Case | Keep DataDog/New Relic | Use Bolt.diy System |
|----------|------------------------|---------------------|
| Small team (<5) | ❌ | ✅ |
| Indie/side project | ❌ | ✅ |
| Enterprise (>100 employees) | ✅ | ❌ |
| SOC2/compliance required | ✅ | ⚠️ (depends) |
| Multi-service architecture | ✅ | ⚠️ (per-service) |
| Client-side debugging | ❌ | ✅ |
| Server monitoring | ✅ | ❌ |
| Cost-sensitive | ❌ | ✅ |

### Recommended Approach: Hybrid

**Use DataDog/New Relic for:**
- Server-side APM
- Infrastructure monitoring
- Production error tracking
- Performance monitoring
- Alerting (PagerDuty integration)

**Use Bolt.diy System for:**
- Client-side logging
- Development debugging
- User session debugging
- Feature usage tracking
- Client-side performance

**Implementation:**
```typescript
// src/lib/observability.ts
import { logger } from '~/utils/logger';
import { logStore } from '~/lib/stores/logs';

export function logError(error: Error, component?: string, context?: any) {
  // Always log locally
  logger.error('Error occurred', error, context);
  logStore.logError(error.message, error, component);

  // Also send to DataDog in production
  if (import.meta.env.PROD && window.DD_RUM) {
    window.DD_RUM.addError(error, {
      component,
      ...context,
    });
  }
}

export function logPerformance(metric: string, value: number, metadata?: any) {
  // Always log locally
  logStore.logPerformance({ metric, value, metadata });

  // Also send to DataDog
  if (import.meta.env.PROD && window.DD_RUM) {
    window.DD_RUM.addTiming(metric, value);
  }
}
```

---

## Coexistence Strategy

### Running Multiple Systems Simultaneously

#### Setup Unified Logging Interface

```typescript
// src/lib/observability/index.ts
import * as Sentry from '@sentry/react';
import { logger as localLogger } from '~/utils/logger';
import { logStore } from '~/lib/stores/logs';

interface ObservabilityConfig {
  enableSentry: boolean;
  enableDataDog: boolean;
  enableLocal: boolean;
}

const config: ObservabilityConfig = {
  enableSentry: import.meta.env.PROD,
  enableDataDog: import.meta.env.PROD,
  enableLocal: true,  // Always enabled
};

export const observability = {
  logError: (error: Error, component?: string, context?: any) => {
    // Local logging (always enabled)
    if (config.enableLocal) {
      localLogger.error('Error occurred', error, context);
      logStore.logError(error.message, error, component);
    }

    // Sentry (production only)
    if (config.enableSentry) {
      Sentry.captureException(error, {
        tags: { component },
        extra: context,
      });
    }

    // DataDog (production only)
    if (config.enableDataDog && window.DD_RUM) {
      window.DD_RUM.addError(error, { component, ...context });
    }
  },

  logEvent: (event: string, metadata?: any) => {
    if (config.enableLocal) {
      localLogger.info(event, metadata);
      logStore.logSystem(event, metadata);
    }

    if (config.enableSentry) {
      Sentry.captureMessage(event);
    }
  },

  logPerformance: (metric: string, value: number, metadata?: any) => {
    if (config.enableLocal) {
      logStore.logPerformance({ metric, value, metadata });
    }

    if (config.enableDataDog && window.DD_RUM) {
      window.DD_RUM.addTiming(metric, value);
    }
  },

  logAPIRequest: (params: {
    method: string;
    endpoint: string;
    duration: number;
    statusCode?: number;
  }) => {
    if (config.enableLocal) {
      logStore.logAPIRequest(params);
    }

    if (config.enableDataDog && window.DD_RUM) {
      window.DD_RUM.addAction('api_request', {
        method: params.method,
        endpoint: params.endpoint,
        duration: params.duration,
        status: params.statusCode,
      });
    }
  },
};

// Export for use throughout app
export const { logError, logEvent, logPerformance, logAPIRequest } = observability;
```

#### Usage Throughout App

```typescript
// Before (direct Sentry usage):
import * as Sentry from '@sentry/react';
Sentry.captureException(error);

// After (unified interface):
import { logError } from '~/lib/observability';
logError(error, 'ComponentName', { userId, action: 'submit' });
```

#### Gradual Transition

```typescript
// Week 1-2: Enable both systems, validate parity
const config = {
  enableSentry: true,
  enableLocal: true,
};

// Week 3-4: Production uses Sentry, staging uses local
const config = {
  enableSentry: import.meta.env.PROD,
  enableLocal: !import.meta.env.PROD,
};

// Week 5+: Fully migrated, Sentry disabled
const config = {
  enableSentry: false,
  enableLocal: true,
};
```

---

## Rollback Plan

### If Migration Goes Wrong

**Step 1: Immediate Rollback (Git)**

```bash
# If issues discovered immediately
git reset --hard HEAD~1

# If issues discovered later
git revert <commit-hash>

# Deploy previous version
npm run deploy
```

**Step 2: Feature Flag Rollback**

```typescript
// Add feature flag for gradual rollout
const USE_NEW_LOGGING = import.meta.env.VITE_USE_NEW_LOGGING === 'true';

export function logError(error: Error, component?: string) {
  if (USE_NEW_LOGGING) {
    // New system
    logger.error('Error occurred', error);
    logStore.logError(error.message, error, component);
  } else {
    // Old system (Sentry)
    Sentry.captureException(error, { tags: { component } });
  }
}

// Rollback via environment variable
// .env
VITE_USE_NEW_LOGGING=false
```

**Step 3: Gradual Rollout (Percentage-based)**

```typescript
// Roll out to 10% of users first
const USE_NEW_LOGGING = Math.random() < 0.1;

// If successful, increase to 50%
const USE_NEW_LOGGING = Math.random() < 0.5;

// If successful, increase to 100%
const USE_NEW_LOGGING = true;
```

**Step 4: Monitor During Migration**

```typescript
// Track migration health
const migrationHealth = {
  errorsOld: 0,
  errorsNew: 0,
  performanceOld: 0,
  performanceNew: 0,
};

// Log to both systems temporarily
try {
  // Old system
  const startOld = performance.now();
  Sentry.captureException(error);
  migrationHealth.performanceOld += performance.now() - startOld;
} catch (e) {
  migrationHealth.errorsOld++;
}

try {
  // New system
  const startNew = performance.now();
  logger.error('Error', error);
  logStore.logError('Error', error);
  migrationHealth.performanceNew += performance.now() - startNew;
} catch (e) {
  migrationHealth.errorsNew++;
}

// Report health metrics
console.log('Migration health:', migrationHealth);
```

---

## Testing Your Migration

### Validation Checklist

Before removing old system:

- [ ] All error logs captured
- [ ] All event logs captured
- [ ] Performance metrics tracked
- [ ] User context preserved
- [ ] No data loss compared to old system
- [ ] Performance not degraded (check bundle size, runtime)
- [ ] Team trained on new system
- [ ] Documentation updated
- [ ] Debug log export working
- [ ] Production tested for 1+ week

### Side-by-Side Comparison

```typescript
// Test script to validate parity
import { logError as oldLogError } from '~/lib/sentry';
import { logError as newLogError } from '~/lib/observability';

async function testParity() {
  const testError = new Error('Test error');

  // Log with old system
  console.time('Old system');
  oldLogError(testError, 'TestComponent', { userId: '123' });
  console.timeEnd('Old system');

  // Log with new system
  console.time('New system');
  newLogError(testError, 'TestComponent', { userId: '123' });
  console.timeEnd('New system');

  // Download debug log to verify
  const { downloadDebugLog } = await import('~/utils/debugLogger');
  await downloadDebugLog('parity-test.txt');

  // Manual verification:
  // 1. Check console output
  // 2. Check debug log file
  // 3. Verify all context captured
}
```

---

## Cost-Benefit Analysis

### Before Migration (Example Costs)

| Service | Plan | Cost/Month | Cost/Year |
|---------|------|------------|-----------|
| Sentry | Team | $80 | $960 |
| DataDog | Pro | $15/host × 5 | $900 |
| **Total** | | **$155** | **$1,860** |

### After Migration

| Service | Plan | Cost/Month | Cost/Year |
|---------|------|------------|-----------|
| Bolt.diy Observability | Self-hosted | $0 | $0 |
| **Total** | | **$0** | **$0** |

**Savings: $1,860/year**

### Time Investment

| Activity | Hours | Hourly Rate | Cost |
|----------|-------|-------------|------|
| Setup | 4 | $100 | $400 |
| Migration | 16 | $100 | $1,600 |
| Testing | 8 | $100 | $800 |
| **Total** | **28** | | **$2,800** |

**Break-even point:** ~18 months

**ROI after 2 years:** $1,060 (38% ROI)

---

## Support During Migration

If you encounter issues:

1. Review the `README.md` for API reference
2. Check `IMPLEMENTATION-GUIDE.md` for setup steps
3. Review source code comments
4. Test in staging before production
5. Keep old system running during transition
6. Use feature flags for gradual rollout

---

**Good luck with your migration! 🚀**
