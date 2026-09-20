import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { FlightsService } from './flights.service';
import { FlightsController } from './flights.controller';
import { Flight } from './entities/flight.entity';
import { FlightTemplate } from './entities/flight-template.entity';
import { FlightTemplatesService } from './flight-templates/flight-templates.service';
import { FlightTemplatesController } from './flight-templates/flight-templates.controller';
import { Package } from '../packages/entities/package.entity';
import { Booking } from '../bookings/entities/booking.entity';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Flight, FlightTemplate, Package, Booking]),
    NotificationsModule,
  ],
  controllers: [FlightsController, FlightTemplatesController],
  providers: [FlightsService, FlightTemplatesService],
  exports: [FlightsService, FlightTemplatesService],
})
export class FlightsModule {}
