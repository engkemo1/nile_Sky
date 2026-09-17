import { PartialType } from '@nestjs/mapped-types';
import { IsString, IsNotEmpty, IsOptional, IsEnum, IsNumber, IsBoolean, IsArray } from 'class-validator';
import { PackageType } from '../entities/package.entity';

export class CreatePackageDto {
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
  descriptionEn?: string;

  @IsOptional()
  @IsString()
  descriptionAr?: string;

  @IsOptional()
  @IsEnum(PackageType)
  type?: PackageType;

  @IsNotEmpty()
  @IsNumber()
  durationMinutes: number;

  @IsOptional()
  @IsBoolean()
  hasPickup?: boolean;

  @IsOptional()
  @IsBoolean()
  hasBreakfast?: boolean;

  @IsOptional()
  @IsBoolean()
  isPrivate?: boolean;

  @IsOptional()
  @IsNumber()
  maxGuestsIfPrivate?: number;

  @IsNotEmpty()
  @IsNumber()
  basePriceEgp: number;

  @IsOptional()
  @IsNumber()
  priceUsd?: number;

  @IsOptional()
  @IsNumber()
  priceEur?: number;

  @IsOptional()
  @IsNumber()
  priceGbp?: number;

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
  @IsBoolean()
  isActive?: boolean;
}

export class UpdatePackageDto extends PartialType(CreatePackageDto) {}
