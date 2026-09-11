import { IsString, IsNotEmpty, IsOptional, IsNumber, IsEnum, IsBoolean, IsArray } from 'class-validator';
import { RecurrenceType } from '../entities/flight-template.entity';

export class CreateFlightTemplateDto {
  @IsNotEmpty()
  @IsString()
  operatorId: string;

  @IsNotEmpty()
  @IsString()
  packageId: string;

  @IsNotEmpty()
  @IsString()
  departureTime: string; // e.g. "06:15:00"

  @IsNotEmpty()
  @IsNumber()
  capacity: number;

  @IsOptional()
  @IsEnum(RecurrenceType)
  recurrence?: RecurrenceType;

  @IsOptional()
  @IsArray()
  customDays?: string[];

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdateFlightTemplateDto extends CreateFlightTemplateDto {}
