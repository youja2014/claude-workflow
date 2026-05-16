import type { HealthStatus } from './health';

describe('HealthStatus', () => {
  it('accepts ok and error', () => {
    const ok: HealthStatus = { status: 'ok', timestamp: 'now' };
    const err: HealthStatus = { status: 'error', timestamp: 'now' };
    expect(ok.status).toBe('ok');
    expect(err.status).toBe('error');
  });
});
