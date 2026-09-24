import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule as NestConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { ConfigModule } from './config/config.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { OperatorsModule } from './operators/operators.module';
import { PackagesModule } from './packages/packages.module';
import { FlightsModule } from './flights/flights.module';
import { BookingsModule } from './bookings/bookings.module';
import { PaymentsModule } from './payments/payments.module';
import { BalloonsModule } from './balloons/balloons.module';
import { PilotsModule } from './pilots/pilots.module';
import { DriversModule } from './drivers/drivers.module';
import { ReviewsModule } from './reviews/reviews.module';
import { NotificationsModule } from './notifications/notifications.module';
import { CouponsModule } from './coupons/coupons.module';
import { WeatherModule } from './weather/weather.module';
import { AnalyticsModule } from './analytics/analytics.module';
import { UploadModule } from './upload/upload.module';
import { I18nModule } from './i18n/i18n.module';
import { SeedService } from './database/seed.service';

import { User } from './users/entities/user.entity';
import { Operator } from './operators/entities/operator.entity';
import { Package } from './packages/entities/package.entity';
import { Balloon } from './balloons/entities/balloon.entity';
import { Pilot } from './pilots/entities/pilot.entity';
import { Driver } from './drivers/entities/driver.entity';
import { FlightTemplate } from './flights/entities/flight-template.entity';
import { Flight } from './flights/entities/flight.entity';
import { Booking } from './bookings/entities/booking.entity';
import { Payment } from './payments/entities/payment.entity';
import { Review } from './reviews/entities/review.entity';
import { Notification } from './notifications/entities/notification.entity';
import { Coupon } from './coupons/entities/coupon.entity';
import { Media } from './upload/entities/media.entity';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';

// Build TypeORM config — supports DATABASE_URL (Neon, Render, etc.) or individual env vars
function buildTypeOrmConfig() {
  const databaseUrl = process.env.DATABASE_URL;
  const isProd = process.env.NODE_ENV === 'production';

  const baseConfig = {
    type: 'postgres' as const,
    entities: [
      User, Operator, Package, Balloon, Pilot, Driver,
      FlightTemplate, Flight, Booking, Payment, Review,
      Notification, Coupon, Media,
    ],
    // TypeORM rewrites the live schema on every boot to match the entities.
    // That is how new columns appear without migrations, and also how a
    // renamed column silently drops its data — set DB_SYNCHRONIZE=false once
    // the schema has settled and there is real customer data to lose.
    synchronize: process.env.DB_SYNCHRONIZE !== 'false',
  };

  if (databaseUrl) {
    return {
      ...baseConfig,
      url: databaseUrl,
      ssl: isProd ? { rejectUnauthorized: false } : false,
    };
  }

  return {
    ...baseConfig,
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT, 10) || 5432,
    username: process.env.DB_USERNAME || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    database: process.env.DB_DATABASE || 'nilesky',
    ssl: isProd ? { rejectUnauthorized: false } : false,
  };
}

@Module({
  imports: [
    NestConfigModule.forRoot({ isGlobal: true }),
    // A blanket ceiling on request rate. Login is tightened further on its own
    // route; without this, an admin email plus a wordlist was all it took.
    ThrottlerModule.forRoot([{ name: 'default', ttl: 60_000, limit: 120 }]),
    TypeOrmModule.forRoot(buildTypeOrmConfig()),
    TypeOrmModule.forFeature([
      User, Operator, Package, Balloon, Pilot, Driver,
      FlightTemplate, Flight, Booking, Payment, Review,
      Notification, Coupon, Media,
    ]),
    ConfigModule,
    AuthModule,
    UsersModule,
    OperatorsModule,
    PackagesModule,
    FlightsModule,
    BookingsModule,
    PaymentsModule,
    BalloonsModule,
    PilotsModule,
    DriversModule,
    ReviewsModule,
    NotificationsModule,
    CouponsModule,
    WeatherModule,
    AnalyticsModule,
    UploadModule,
    I18nModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    SeedService,
    { provide: APP_GUARD, useClass: ThrottlerGuard },
  ],
})
export class AppModule {}
