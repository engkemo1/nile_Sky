import { IsString, IsNotEmpty, IsOptional, IsEnum, IsObject } from 'class-validator';
import { NotificationType } from '../entities/notification.entity';

/**
 * The send endpoint previously took an inline type, so nothing validated it.
 * An unknown `type` reached Postgres and came back as a 500; it is now a 400.
 */
export class SendNotificationDto {
  @IsNotEmpty()
  @IsString()
  userId: string;

  @IsNotEmpty()
  @IsString()
  titleEn: string;

  @IsOptional()
  @IsString()
  titleAr?: string;

  @IsNotEmpty()
  @IsString()
  bodyEn: string;

  @IsOptional()
  @IsString()
  bodyAr?: string;

  @IsNotEmpty()
  @IsEnum(NotificationType)
  type: NotificationType;

  @IsOptional()
  @IsObject()
  data?: Record<string, any>;
}
