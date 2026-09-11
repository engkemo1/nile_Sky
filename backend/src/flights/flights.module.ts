import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { FlightsService } from './flights.service';
import { FlightsController } from './flights.controller';
import { Flight } from './entities/flight.entity';
import { FlightTemplate } from './entities/flight-template.entity';
import { FlightTemplatesService } from './flight-templates/flight-templates.service';
import { FlightTemplatesController } from './flight-templates/flight-templates.controller';
import { Package } from '../packages/entities/package.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Flight, FlightTemplate, Package])],
  controllers: [FlightsController, FlightTemplatesController],
  providers: [FlightsService, FlightTemplatesService],
  exports: [FlightsService, FlightTemplatesService],
})
export class FlightsModule {}
