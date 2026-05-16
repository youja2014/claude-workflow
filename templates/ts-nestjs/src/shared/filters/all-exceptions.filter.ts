import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { Logger } from 'nestjs-pino';

interface ProblemDetails {
  type: string;
  title: string;
  status: number;
  detail: string;
  instance: string;
}

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  constructor(private readonly logger: Logger) {}

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const title =
      exception instanceof HttpException
        ? exception.name
        : (exception as { name?: string })?.name ?? 'InternalServerError';

    const detail =
      exception instanceof HttpException
        ? this.extractDetail(exception.getResponse())
        : (exception as { message?: string })?.message ?? 'Unexpected error';

    if (status >= 500) {
      this.logger.error({ err: exception, path: request.url }, 'Unhandled exception');
    }

    const body: ProblemDetails = {
      type: `about:blank#${title}`,
      title,
      status,
      detail,
      instance: request.url,
    };

    response.status(status).json(body);
  }

  private extractDetail(payload: string | object): string {
    if (typeof payload === 'string') return payload;
    if (typeof payload === 'object' && payload !== null && 'message' in payload) {
      const msg = (payload as { message: unknown }).message;
      return Array.isArray(msg) ? msg.join(', ') : String(msg);
    }
    return JSON.stringify(payload);
  }
}
