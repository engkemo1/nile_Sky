import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { StripSecretsInterceptor } from './common/interceptors/strip-secrets.interceptor';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Enable CORS for Flutter Mobile & Flutter Web Admin Panel
  app.enableCors({
    origin: '*',
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

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const port = process.env.PORT || 3000;
  await app.listen(port, '0.0.0.0');
  console.log(`🚀 NileSky Backend API running on: http://localhost:${port}`);
  console.log(`📄 Swagger Docs: http://localhost:${port}/api/docs`);
}
bootstrap();
