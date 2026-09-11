import { Module } from '@nestjs/common';
import { FlightTemplatesController } from './flight-templates.controller';
import { FlightTemplatesService } from './flight-templates.service';

@Module({
  controllers: [FlightTemplatesController],
  providers: [FlightTemplatesService]
})
export class FlightTemplatesModule {}
