import type { HealthStatus } from '@__project_kebab__/shared-types';
import { useEffect, useState } from 'react';

export function App(): JSX.Element {
  const [status, setStatus] = useState<HealthStatus | null>(null);

  useEffect(() => {
    const base = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:3000';
    fetch(`${base}/health`)
      .then((r) => r.json() as Promise<HealthStatus>)
      .then(setStatus)
      .catch(() => setStatus({ status: 'error', timestamp: new Date().toISOString() }));
  }, []);

  return (
    <main>
      <h1>__project_name__</h1>
      <p>api status: {status?.status ?? 'loading...'}</p>
    </main>
  );
}
