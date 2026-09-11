import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn,
  ManyToOne, JoinColumn, Index,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Flight } from '../../flights/entities/flight.entity';
import { Operator } from '../../operators/entities/operator.entity';
import { Driver } from '../../drivers/entities/driver.entity';

export enum BookingStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  CHECKED_IN = 'checked_in',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
  NO_SHOW = 'no_show',
}

export enum PaymentStatus {
  PENDING = 'pending',
  PAID = 'paid',
  REFUNDED = 'refunded',
  PARTIAL_REFUND = 'partial_refund',
}

@Entity('bookings')
export class Booking {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index({ unique: true })
  @Column({ name: 'booking_ref', unique: true, length: 20 })
  bookingRef: string;

  @Index()
  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Index()
  @Column({ name: 'flight_id' })
  flightId: string;

  @ManyToOne(() => Flight, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'flight_id' })
  flight: Flight;

  @Index()
  @Column({ name: 'operator_id' })
  operatorId: string;

  @ManyToOne(() => Operator, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'operator_id' })
  operator: Operator;

  @Column({ name: 'guest_count' })
  guestCount: number;

  @Column({ name: 'total_price_egp', type: 'decimal', precision: 10, scale: 2 })
  totalPriceEgp: number;

  @Column({ name: 'commission_amount', type: 'decimal', precision: 10, scale: 2, default: 0 })
  commissionAmount: number;

  @Index()
  @Column({ name: 'payment_status', type: 'enum', enum: PaymentStatus, default: PaymentStatus.PENDING })
  paymentStatus: PaymentStatus;

  @Index()
  @Column({ name: 'booking_status', type: 'enum', enum: BookingStatus, default: BookingStatus.PENDING })
  bookingStatus: BookingStatus;

  @Column({ name: 'pickup_location', nullable: true })
  pickupLocation: string;

  @Column({ name: 'pickup_hotel_name', nullable: true })
  pickupHotelName: string;

  @Column({ name: 'pickup_lat', type: 'decimal', precision: 10, scale: 7, nullable: true })
  pickupLat: number;

  @Column({ name: 'pickup_lng', type: 'decimal', precision: 10, scale: 7, nullable: true })
  pickupLng: number;

  @Column({ name: 'driver_id', nullable: true })
  driverId: string;

  @ManyToOne(() => Driver, { onDelete: 'SET NULL' })
  @JoinColumn({ name: 'driver_id' })
  driver: Driver;

  @Column({ name: 'pickup_time', type: 'time', nullable: true })
  pickupTime: string;

  @Column({ name: 'qr_code_data', type: 'text', nullable: true })
  qrCodeData: string;

  @Column({ name: 'special_requests', type: 'text', nullable: true })
  specialRequests: string;

  @Column({ name: 'guest_details', type: 'jsonb', nullable: true })
  guestDetails: { name: string; phone?: string; email?: string }[];

  @Column({ name: 'coupon_id', nullable: true })
  couponId: string;

  @Column({ name: 'discount_amount', type: 'decimal', precision: 10, scale: 2, default: 0 })
  discountAmount: number;

  @Column({ name: 'cancellation_reason', type: 'text', nullable: true })
  cancellationReason: string;

  @Column({ name: 'cancelled_at', type: 'timestamptz', nullable: true })
  cancelledAt: Date;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
