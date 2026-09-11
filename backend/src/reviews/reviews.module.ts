import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ReviewsService } from './reviews.service';
import { ReviewsController } from './reviews.controller';
import { Review } from './entities/review.entity';
import { Booking } from '../bookings/entities/booking.entity';
import { Operator } from '../operators/entities/operator.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Review, Booking, Operator])],
  controllers: [ReviewsController],
  providers: [ReviewsService],
  exports: [ReviewsService],
})
export class ReviewsModule {}
