import { Controller, Get, Post, Delete, Param, Body, Query, UseGuards } from '@nestjs/common';
import { CouponsService } from './coupons.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';

@Controller('coupons')
export class CouponsController {
  constructor(private readonly couponsService: CouponsService) {}

  @Get('validate/:code')
  async validate(@Param('code') code: string, @Query('operatorId') operatorId?: string) {
    return this.couponsService.validate(code, operatorId);
  }

  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async findAll() {
    return this.couponsService.findAll();
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async create(@Body() data: any) {
    return this.couponsService.create(data);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async remove(@Param('id') id: string) {
    return this.couponsService.remove(id);
  }
}
