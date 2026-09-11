import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PilotsService } from './pilots.service';
import { PilotsController } from './pilots.controller';
import { Pilot } from './entities/pilot.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Pilot])],
  controllers: [PilotsController],
  providers: [PilotsService],
  exports: [PilotsService],
})
export class PilotsModule {}
