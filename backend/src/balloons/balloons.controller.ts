import { Controller, Get, Post, Patch, Delete, Param, Body, Query, UseGuards } from '@nestjs/common';
import { BalloonsService } from './balloons.service';
import { CreateBalloonDto, UpdateBalloonDto } from './dto/balloon.dto';
import { BalloonStatus } from './entities/balloon.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';

@Controller('balloons')
export class BalloonsController {
  constructor(private readonly balloonsService: BalloonsService) {}

  @Get()
  async findAll(
    @Query('operatorId') operatorId?: string,
    @Query('status') status?: BalloonStatus,
  ) {
    return this.balloonsService.findAll(operatorId, status);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.balloonsService.findOne(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async create(@Body() dto: CreateBalloonDto) {
    return this.balloonsService.create(dto);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async update(@Param('id') id: string, @Body() dto: UpdateBalloonDto) {
    return this.balloonsService.update(id, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async remove(@Param('id') id: string) {
    return this.balloonsService.remove(id);
  }
}
