import { PartialType } from '@nestjs/mapped-types';
import { Type } from 'class-transformer';
import { IsString, IsNotEmpty, IsOptional, IsNumber, IsEnum, IsDateString, IsArray } from 'class-validator';
import { FlightStatus, WeatherStatus } from '../entities/flight.entity';

export class CreateFlightDto {
  @IsNotEmpty()
  @IsString()
  flightNumber: string;

  @IsOptional()
  @IsString()
  flightTemplateId?: string;

  @IsNotEmpty()
  @IsString()
  operatorId: string;

  @IsNotEmpty()
  @IsString()
  packageId: string;

  @IsOptional()
  @IsString()
  balloonId?: string;

  @IsOptional()
  @IsString()
  pilotId?: string;

  @IsNotEmpty()
  @IsDateString()
  flightDate: Date;

  @IsNotEmpty()
  @IsString()
  departureTime: string;

  @IsNotEmpty()
  @IsNumber()
  capacity: number;

  @IsNotEmpty()
  @IsNumber()
  priceEgp: number;

  @IsOptional()
  @IsEnum(FlightStatus)
  status?: FlightStatus;

  @IsOptional()
  @IsEnum(WeatherStatus)
  weatherStatus?: WeatherStatus;

  @IsOptional()
  @IsArray()
  photos?: string[];

  @IsOptional()
  @IsString()
  videoUrl?: string;
}

export class UpdateFlightDto extends PartialType(CreateFlightDto) {
  @IsOptional()
  @IsString()
  cancellationReason?: string;
}

export class SearchFlightsDto {
  @IsOptional()
  @IsDateString()
  date?: string;

  /**
   * Admin dispatch board filters. Without these the list was hardcoded to
   * SCHEDULED, so a flight vanished the moment its status changed and there
   * was no history, no "yesterday", and no way to undo a mis-click.
   */
  @IsOptional()
  @IsEnum(FlightStatus)
  status?: FlightStatus;

  @IsOptional()
  @IsDateString()
  dateFrom?: string;

  @IsOptional()
  @IsDateString()
  dateTo?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  guests?: number;

  @IsOptional()
  @IsString()
  packageType?: string; // standard | premium | private

  @IsOptional()
  @IsString()
  operatorId?: string;

  @IsOptional()
  @IsString()
  sortBy?: 'price' | 'rating' | 'time';

  @IsOptional()
  @IsString()
  sortOrder?: 'ASC' | 'DESC';
}
