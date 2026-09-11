import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BookingsService } from './bookings.service';
import { BookingsController } from './bookings.controller';
import { Booking } from './entities/booking.entity';
import { Flight } from '../flights/entities/flight.entity';
import { Operator } from '../operators/entities/operator.entity';
import { Coupon } from '../coupons/entities/coupon.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Booking, Flight, Operator, Coupon])],
  controllers: [BookingsController],
  providers: [BookingsService],
  exports: [BookingsService],
})
export class BookingsModule {}
