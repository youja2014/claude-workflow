import { ErrorBoundary, type FallbackProps } from 'react-error-boundary';
import type { PropsWithChildren } from 'react';

function ErrorFallback({ error, resetErrorBoundary }: FallbackProps) {
  return (
    <div role="alert" className="min-h-screen flex items-center justify-center p-8">
      <div className="max-w-md w-full space-y-4">
        <h1 className="text-2xl font-bold">Something went wrong</h1>
        <pre className="text-sm bg-gray-100 p-3 rounded overflow-auto">{error.message}</pre>
        <button
          type="button"
          onClick={resetErrorBoundary}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          Try again
        </button>
      </div>
    </div>
  );
}

function logError(error: Error, info: { componentStack?: string | null }) {
  // Wire Sentry here when configured: Sentry.captureException(error, { extra: info })
  // eslint-disable-next-line no-console
  console.error('[ErrorBoundary]', error, info.componentStack);
}

export function AppErrorBoundary({ children }: PropsWithChildren) {
  return (
    <ErrorBoundary FallbackComponent={ErrorFallback} onError={logError}>
      {children}
    </ErrorBoundary>
  );
}
