import { PartialType } from '@nestjs/mapped-types';
import { IsString, IsNotEmpty, IsOptional, IsEmail, IsNumber, IsEnum, IsArray } from 'class-validator';
import { OperatorStatus } from '../entities/operator.entity';

export class CreateOperatorDto {
  @IsNotEmpty()
  @IsString()
  nameEn: string;

  @IsOptional()
  @IsString()
  nameAr?: string;

  @IsOptional()
  @IsString()
  descriptionEn?: string;

  @IsOptional()
  @IsString()
  descriptionAr?: string;

  @IsOptional()
  @IsString()
  logoUrl?: string;

  @IsOptional()
  @IsString()
  coverPhotoUrl?: string;

  @IsOptional()
  @IsArray()
  photos?: string[];

  @IsOptional()
  @IsString()
  videoUrl?: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  website?: string;

  @IsOptional()
  @IsString()
  whatsapp?: string;

  @IsOptional()
  @IsString()
  licenseNumber?: string;

  @IsOptional()
  @IsString()
  licenseDocUrl?: string;

  @IsOptional()
  @IsString()
  insuranceDocUrl?: string;

  @IsOptional()
  @IsString()
  address?: string;

  @IsOptional()
  @IsNumber()
  latitude?: number;

  @IsOptional()
  @IsNumber()
  longitude?: number;

  @IsOptional()
  @IsNumber()
  commissionRate?: number;
}

export class UpdateOperatorDto extends PartialType(CreateOperatorDto) {
  @IsOptional()
  @IsEnum(OperatorStatus)
  status?: OperatorStatus;
}
