import { Controller, Get, Post, Patch, Delete, Param, Body, Query, UseGuards } from '@nestjs/common';
import { FlightTemplatesService } from './flight-templates.service';
import { CreateFlightTemplateDto, UpdateFlightTemplateDto } from '../dto/flight-template.dto';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { Roles } from '../../auth/decorators/roles.decorator';
import { UserRole } from '../../users/entities/user.entity';

@Controller('flight-templates')
export class FlightTemplatesController {
  constructor(private readonly flightTemplatesService: FlightTemplatesService) {}

  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async findAll(@Query('operatorId') operatorId?: string) {
    return this.flightTemplatesService.findAll(operatorId);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async findOne(@Param('id') id: string) {
    return this.flightTemplatesService.findOne(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async create(@Body() dto: CreateFlightTemplateDto) {
    return this.flightTemplatesService.create(dto);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async update(@Param('id') id: string, @Body() dto: UpdateFlightTemplateDto) {
    return this.flightTemplatesService.update(id, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async remove(@Param('id') id: string) {
    return this.flightTemplatesService.remove(id);
  }
}
