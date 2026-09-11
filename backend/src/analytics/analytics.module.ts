import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AnalyticsService } from './analytics.service';
import { AnalyticsController } from './analytics.controller';
import { Flight } from '../flights/entities/flight.entity';
import { Booking } from '../bookings/entities/booking.entity';
import { Operator } from '../operators/entities/operator.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Flight, Booking, Operator])],
  controllers: [AnalyticsController],
  providers: [AnalyticsService],
  exports: [AnalyticsService],
})
export class AnalyticsModule {}
