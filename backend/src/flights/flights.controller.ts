import { Controller, Get, Post, Patch, Delete, Param, Body, Query, UseGuards } from '@nestjs/common';
import { FlightsService } from './flights.service';
import { CreateFlightDto, UpdateFlightDto, SearchFlightsDto } from './dto/flight.dto';
import { FlightStatus, WeatherStatus } from './entities/flight.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';

@Controller('flights')
export class FlightsController {
  constructor(private readonly flightsService: FlightsService) {}

  @Get()
  async search(@Query() query: SearchFlightsDto) {
    return this.flightsService.search(query);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.flightsService.findOne(id);
  }

  /**
   * The pre-dawn go/no-go. The pilot confirms the flight will fly (or
   * un-confirms it), which is the workflow confirmedAt was designed for and
   * that nothing ever wrote to.
   */
  @Patch(':id/confirm')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async confirmFlight(
    @Param('id') id: string,
    @Body('confirmed') confirmed?: boolean,
  ) {
    return this.flightsService.setConfirmed(id, confirmed !== false);
  }

  @Post('generate')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async generateFlights(@Body('targetDate') targetDate: string) {
    return this.flightsService.generateFlightsFromTemplates(targetDate);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async create(@Body() dto: CreateFlightDto) {
    return this.flightsService.create(dto);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async update(@Param('id') id: string, @Body() dto: UpdateFlightDto) {
    return this.flightsService.update(id, dto);
  }

  @Patch(':id/status')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async updateStatus(
    @Param('id') id: string,
    @Body('status') status: FlightStatus,
    @Body('cancellationReason') cancellationReason?: string,
  ) {
    return this.flightsService.updateStatus(id, status, cancellationReason);
  }

  @Patch(':id/weather')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async updateWeather(
    @Param('id') id: string,
    @Body('weatherStatus') weatherStatus: WeatherStatus,
  ) {
    return this.flightsService.updateWeatherStatus(id, weatherStatus);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN)
  async remove(@Param('id') id: string) {
    return this.flightsService.remove(id);
  }
}
