# Quick Start Guide - 5 Minutes to Observability

Get up and running with the bolt.diy observability system in 5 minutes.

---

## ⚡ Quick Install

### 1. Install Dependencies (1 minute)

```bash
npm install chalk nanostores
npm install -D @types/node
```

### 2. Copy Core Files (1 minute)

```bash
# Create directories
mkdir -p src/utils src/lib/stores

# Copy files (adjust paths based on where you extracted this package)
cp observability-system-package/source-files/logger.ts src/utils/
cp observability-system-package/source-files/debugLogger.ts src/utils/
cp observability-system-package/source-files/logs.ts src/lib/stores/
```

### 3. Configure Environment (30 seconds)

Add to your `.env` file:

```bash
# For Vite
VITE_LOG_LEVEL=debug

# For Next.js
NEXT_PUBLIC_LOG_LEVEL=debug

# For Create React App
REACT_APP_LOG_LEVEL=debug
```

### 4. Initialize (1 minute)

**Vite/React:**
```typescript
// src/main.tsx
import { logger } from './utils/logger';
import { enableDebugMode } from './utils/debugLogger';

if (import.meta.env.DEV) {
  enableDebugMode();
}

logger.info('App starting');
```

**Next.js:**
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
    logger.info('App initialized');
  }, []);

  return <html><body>{children}</body></html>;
}
```

### 5. Start Using (1 minute)

```typescript
import { createScopedLogger } from '~/utils/logger';
import { logStore } from '~/lib/stores/logs';

const logger = createScopedLogger('MyComponent');

// Log messages
logger.info('Hello world');
logger.error('Something went wrong', error);

// Track events
logStore.logUserAction('Button clicked', { buttonId: 'submit' });

// Log API calls
logStore.logAPIRequest({
  method: 'POST',
  endpoint: '/api/users',
  duration: 234,
  statusCode: 200,
});
```

---

## ✅ Verify Installation

1. **Build your project:**
   ```bash
   npm run build
   ```

2. **Start dev server:**
   ```bash
   npm run dev
   ```

3. **Check console - you should see colored log output**

4. **Download debug log to test:**
   ```typescript
   import { downloadDebugLog } from '~/utils/debugLogger';
   await downloadDebugLog('test.txt');
   ```

---

## 🎯 What's Next?

- **Full Setup:** See `IMPLEMENTATION-GUIDE.md` for health monitoring, error boundaries, and more
- **Examples:** Check `examples/usage-examples.md` for common patterns
- **Migration:** See `MIGRATION-GUIDE.md` if replacing Sentry/Winston/etc.
- **API Reference:** See `README.md` for complete documentation

---

## 🆘 Troubleshooting

**Import errors?**
- Update tsconfig.json with path aliases
- Or use relative imports: `import { logger } from '../utils/logger'`

**No logs showing?**
- Check VITE_LOG_LEVEL is set to 'debug'
- Verify debugMode is enabled in development

**Build errors?**
- Ensure chalk and nanostores are installed
- Check TypeScript version is 5+

---

**That's it! You're ready to go! 🚀**

For help: See `README.md` or `AI-INSTRUCTIONS.md`
