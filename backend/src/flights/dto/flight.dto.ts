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

export class UpdateFlightDto extends CreateFlightDto {
  @IsOptional()
  @IsString()
  cancellationReason?: string;
}

export class SearchFlightsDto {
  @IsOptional()
  @IsDateString()
  date?: string;

  @IsOptional()
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
