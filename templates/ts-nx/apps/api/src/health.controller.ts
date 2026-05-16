import { Controller, Get } from '@nestjs/common';
import type { HealthStatus } from '@__project_kebab__/shared-types';

@Controller('health')
export class HealthController {
  @Get()
  check(): HealthStatus {
    return { status: 'ok', timestamp: new Date().toISOString() };
  }
}
