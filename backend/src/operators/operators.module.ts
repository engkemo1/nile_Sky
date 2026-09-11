import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OperatorsService } from './operators.service';
import { OperatorsController } from './operators.controller';
import { Operator } from './entities/operator.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Operator])],
  controllers: [OperatorsController],
  providers: [OperatorsService],
  exports: [OperatorsService],
})
export class OperatorsModule {}
