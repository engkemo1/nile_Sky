import { PartialType } from '@nestjs/mapped-types';
import { IsString, IsNotEmpty, IsOptional, IsNumber, IsEnum, IsDateString } from 'class-validator';
import { PilotStatus } from '../entities/pilot.entity';

export class CreatePilotDto {
  @IsNotEmpty()
  @IsString()
  operatorId: string;

  @IsNotEmpty()
  @IsString()
  nameEn: string;

  @IsOptional()
  @IsString()
  nameAr?: string;

  @IsOptional()
  @IsString()
  photoUrl?: string;

  @IsOptional()
  @IsString()
  licenseNumber?: string;

  @IsOptional()
  @IsDateString()
  licenseExpiry?: Date;

  @IsOptional()
  @IsNumber()
  totalFlights?: number;

  @IsOptional()
  @IsNumber()
  experienceYears?: number;

  @IsOptional()
  @IsNumber()
  rating?: number;

  @IsOptional()
  @IsEnum(PilotStatus)
  status?: PilotStatus;
}

export class UpdatePilotDto extends PartialType(CreatePilotDto) {}
