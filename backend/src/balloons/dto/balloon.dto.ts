import { IsString, IsNotEmpty, IsOptional, IsNumber, IsEnum, IsArray, IsDateString } from 'class-validator';
import { BalloonStatus } from '../entities/balloon.entity';

export class CreateBalloonDto {
  @IsNotEmpty()
  @IsString()
  operatorId: string;

  @IsNotEmpty()
  @IsString()
  registrationCode: string;

  @IsOptional()
  @IsString()
  name?: string;

  @IsNotEmpty()
  @IsNumber()
  capacity: number;

  @IsOptional()
  @IsEnum(BalloonStatus)
  status?: BalloonStatus;

  @IsOptional()
  @IsDateString()
  lastInspection?: Date;

  @IsOptional()
  @IsString()
  inspectionDocUrl?: string;

  @IsOptional()
  @IsString()
  insuranceDocUrl?: string;

  @IsOptional()
  @IsDateString()
  insuranceExpiry?: Date;

  @IsOptional()
  @IsString()
  photoUrl?: string;

  @IsOptional()
  @IsArray()
  photos?: string[];

  @IsOptional()
  @IsString()
  videoUrl?: string;

  @IsOptional()
  @IsString()
  notes?: string;
}

export class UpdateBalloonDto extends CreateBalloonDto {}
