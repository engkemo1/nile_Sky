import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BalloonsService } from './balloons.service';
import { BalloonsController } from './balloons.controller';
import { Balloon } from './entities/balloon.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Balloon])],
  controllers: [BalloonsController],
  providers: [BalloonsService],
  exports: [BalloonsService],
})
export class BalloonsModule {}
