import { Controller, Get, Post, Patch, Param, Body, Query, UseGuards } from '@nestjs/common';
import { BookingsService } from './bookings.service';
import { CreateBookingDto, AssignDriverDto } from './dto/booking.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserRole } from '../users/entities/user.entity';

@Controller('bookings')
export class BookingsController {
  constructor(private readonly bookingsService: BookingsService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  async create(@CurrentUser() user: any, @Body() dto: CreateBookingDto) {
    return this.bookingsService.create(user.id, dto);
  }

  @Get()
  @UseGuards(JwtAuthGuard)
  async findAll(
    @CurrentUser() user: any,
    @Query('operatorId') operatorId?: string,
    @Query('flightId') flightId?: string,
  ) {
    return this.bookingsService.findAll(user, operatorId, flightId);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  async findOne(@Param('id') id: string) {
    return this.bookingsService.findOne(id);
  }

  @Get('ref/:ref')
  async findByRef(@Param('ref') ref: string) {
    return this.bookingsService.findByRef(ref);
  }

  @Patch(':id/cancel')
  @UseGuards(JwtAuthGuard)
  async cancel(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body('reason') reason?: string,
  ) {
    return this.bookingsService.cancelBooking(id, user.id, user.role, reason);
  }

  @Patch('check-in/:ref')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async checkIn(@Param('ref') ref: string) {
    return this.bookingsService.checkIn(ref);
  }

  @Patch(':id/assign-driver')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async assignDriver(@Param('id') id: string, @Body() dto: AssignDriverDto) {
    return this.bookingsService.assignDriver(id, dto);
  }
}
