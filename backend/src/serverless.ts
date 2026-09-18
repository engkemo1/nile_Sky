/**
 * Serverless entry point (Vercel).
 *
 * `main.ts` calls app.listen() and owns a port, which is right for a
 * long-lived server but wrong for a function. This module builds the same
 * Nest application over a bare Express instance and hands that Express
 * instance back as the request handler, so every route, pipe, guard and
 * the Swagger UI behave exactly as they do locally.
 *
 * Nest is bootstrapped once per warm instance and the promise is cached,
 * so concurrent requests during a cold start all wait on the same init.
 */
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { ExpressAdapter } from '@nestjs/platform-express';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { StripSecretsInterceptor } from './common/interceptors/strip-secrets.interceptor';

// tsconfig has no esModuleInterop, so a default import of express compiles
// to `express_1.default`, which is undefined. require() is unambiguous.
// eslint-disable-next-line @typescript-eslint/no-var-requires
const express = require('express');
const server = express();
let bootstrapped: Promise<void> | null = null;

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule, new ExpressAdapter(server));

  app.enableCors({
    origin: '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: false,
  });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: false,
    }),
  );

  app.useGlobalInterceptors(new StripSecretsInterceptor());

  const config = new DocumentBuilder()
    .setTitle('NileSky API')
    .setDescription('Luxor Hot Air Balloon Booking & Operations Platform API')
    .setVersion('1.0')
    .addBearerAuth()
    .addTag('auth', 'Authentication & Registration')
    .addTag('users', 'User Profiles')
    .addTag('operators', 'Balloon Operators')
    .addTag('packages', 'Flight Packages')
    .addTag('flights', 'Flight Schedule & Management')
    .addTag('bookings', 'Booking Engine')
    .addTag('payments', 'Payment Processing')
    .addTag('reviews', 'Customer Reviews')
    .addTag('balloons', 'Fleet Management')
    .addTag('pilots', 'Pilot Management')
    .addTag('drivers', 'Driver Management')
    .addTag('coupons', 'Discount Coupons')
    .addTag('weather', 'Luxor Weather')
    .addTag('analytics', 'Dashboard Analytics')
    .build();

  SwaggerModule.setup('api/docs', app, SwaggerModule.createDocument(app, config));

  await app.init();
}

export default async function handler(req: any, res: any) {
  if (!bootstrapped) bootstrapped = bootstrap();
  await bootstrapped;

  // Every request is rewritten to /api?__path=/<original path> (see
  // vercel.json). A rewrite destination is a fixed path, so the original one
  // would otherwise be lost and Nest would see /api and 404 on everything.
  // Dynamic filenames like [[...slug]].js are a Next.js convention and are
  // not honoured for plain Vercel functions, hence the query parameter.
  try {
    const parsed = new URL(req.url, 'http://localhost');
    const original = parsed.searchParams.get('__path');
    if (original) {
      parsed.searchParams.delete('__path');
      const qs = parsed.searchParams.toString();
      req.url = original + (qs ? '?' + qs : '');
    }
  } catch {
    // Leave req.url untouched if it cannot be parsed.
  }

  server(req, res);
}
