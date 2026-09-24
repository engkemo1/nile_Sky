import { json, urlencoded } from 'express';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { StripSecretsInterceptor } from './common/interceptors/strip-secrets.interceptor';
import { corsOrigin, swaggerEnabled } from './common/security';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Enable CORS for Flutter Mobile & Flutter Web Admin Panel
  // Uploads arrive as base64 JSON; express defaults to a 100kb body limit.
  app.use(json({ limit: '8mb' }));
  app.use(urlencoded({ extended: true, limit: '8mb' }));

  app.enableCors({
    // Set CORS_ORIGINS (comma separated) in the deployment to lock this down
    // to the admin panel's origin; '*' is the open default.
    origin: corsOrigin(),
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: false,
  });

  // Global Validation
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: false,
    }),
  );

  // Never let credential hashes leave the API, however deeply nested
  app.useGlobalInterceptors(new StripSecretsInterceptor());

  // Swagger API Documentation
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

  if (swaggerEnabled()) {
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api/docs', app, document);
  }

  const port = process.env.PORT || 3000;
  await app.listen(port, '0.0.0.0');
  console.log(`🚀 NileSky Backend API running on: http://localhost:${port}`);
  if (swaggerEnabled()) {
    console.log(`📄 Swagger Docs: http://localhost:${port}/api/docs`);
  }
}
bootstrap();
