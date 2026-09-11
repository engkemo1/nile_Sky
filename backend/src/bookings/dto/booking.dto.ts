import { IsString, IsNotEmpty, IsOptional, IsNumber, IsEnum, IsArray, Min } from 'class-validator';
import { BookingStatus, PaymentStatus } from '../entities/booking.entity';

export class GuestDetailDto {
  @IsNotEmpty()
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsString()
  email?: string;
}

export class CreateBookingDto {
  @IsNotEmpty()
  @IsString()
  flightId: string;

  @IsNotEmpty()
  @IsNumber()
  @Min(1)
  guestCount: number;

  @IsOptional()
  @IsString()
  pickupLocation?: string;

  @IsOptional()
  @IsString()
  pickupHotelName?: string;

  @IsOptional()
  @IsNumber()
  pickupLat?: number;

  @IsOptional()
  @IsNumber()
  pickupLng?: number;

  @IsOptional()
  @IsString()
  specialRequests?: string;

  @IsOptional()
  @IsArray()
  guestDetails?: GuestDetailDto[];

  @IsOptional()
  @IsString()
  couponCode?: string;
}

export class UpdateBookingStatusDto {
  @IsNotEmpty()
  @IsEnum(BookingStatus)
  status: BookingStatus;

  @IsOptional()
  @IsString()
  cancellationReason?: string;
}

export class AssignDriverDto {
  @IsNotEmpty()
  @IsString()
  driverId: string;

  @IsOptional()
  @IsString()
  pickupTime?: string; // e.g. "04:15:00"
}
