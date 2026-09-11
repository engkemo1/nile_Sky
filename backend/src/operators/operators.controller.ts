import { Controller, Get, Post, Patch, Delete, Param, Body, Query, UseGuards } from '@nestjs/common';
import { OperatorsService } from './operators.service';
import { CreateOperatorDto, UpdateOperatorDto } from './dto/operator.dto';
import { OperatorStatus } from './entities/operator.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';

@Controller('operators')
export class OperatorsController {
  constructor(private readonly operatorsService: OperatorsService) {}

  @Get()
  async findAll(@Query('status') status?: OperatorStatus) {
    return this.operatorsService.findAll(status);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.operatorsService.findOne(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN)
  async create(@Body() dto: CreateOperatorDto) {
    return this.operatorsService.create(dto);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async update(@Param('id') id: string, @Body() dto: UpdateOperatorDto) {
    return this.operatorsService.update(id, dto);
  }

  @Patch(':id/verify')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN)
  async verify(@Param('id') id: string) {
    return this.operatorsService.verify(id);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN)
  async remove(@Param('id') id: string) {
    return this.operatorsService.remove(id);
  }
}
