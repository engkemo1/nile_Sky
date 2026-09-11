import { Controller, Get, Post, Patch, Delete, Param, Body, Query, UseGuards } from '@nestjs/common';
import { PilotsService } from './pilots.service';
import { CreatePilotDto, UpdatePilotDto } from './dto/pilot.dto';
import { PilotStatus } from './entities/pilot.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';

@Controller('pilots')
export class PilotsController {
  constructor(private readonly pilotsService: PilotsService) {}

  @Get()
  async findAll(
    @Query('operatorId') operatorId?: string,
    @Query('status') status?: PilotStatus,
  ) {
    return this.pilotsService.findAll(operatorId, status);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.pilotsService.findOne(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async create(@Body() dto: CreatePilotDto) {
    return this.pilotsService.create(dto);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async update(@Param('id') id: string, @Body() dto: UpdatePilotDto) {
    return this.pilotsService.update(id, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async remove(@Param('id') id: string) {
    return this.pilotsService.remove(id);
  }
}
