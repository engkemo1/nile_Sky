import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
  ManyToOne, JoinColumn, Index,
} from 'typeorm';
import { Booking } from '../../bookings/entities/booking.entity';
import { User } from '../../users/entities/user.entity';

export enum PaymentMethod {
  CARD = 'card',
  WALLET = 'wallet',
  CASH = 'cash',
  BANK_TRANSFER = 'bank_transfer',
}

export enum PaymentGateway {
  PAYMOB = 'paymob',
  FAWRY = 'fawry',
  STRIPE = 'stripe',
}

export enum TransactionStatus {
  PENDING = 'pending',
  SUCCESS = 'success',
  FAILED = 'failed',
  REFUNDED = 'refunded',
}

@Entity('payments')
export class Payment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ name: 'booking_id' })
  bookingId: string;

  @ManyToOne(() => Booking, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'booking_id' })
  booking: Booking;

  @Index()
  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'amount_egp', type: 'decimal', precision: 10, scale: 2 })
  amountEgp: number;

  @Column({ name: 'currency_charged', default: 'EGP', length: 3 })
  currencyCharged: string;

  @Column({ name: 'amount_charged', type: 'decimal', precision: 10, scale: 2, nullable: true })
  amountCharged: number;

  @Column({ type: 'enum', enum: PaymentMethod, nullable: true })
  method: PaymentMethod;

  @Column({ type: 'enum', enum: PaymentGateway, nullable: true })
  gateway: PaymentGateway;

  @Index()
  @Column({ name: 'gateway_transaction_id', nullable: true })
  gatewayTransactionId: string;

  @Index()
  @Column({ type: 'enum', enum: TransactionStatus, default: TransactionStatus.PENDING })
  status: TransactionStatus;

  @Column({ name: 'gateway_response', type: 'jsonb', nullable: true })
  gatewayResponse: any;

  @Column({ name: 'paid_at', type: 'timestamptz', nullable: true })
  paidAt: Date;

  @Column({ name: 'refunded_at', type: 'timestamptz', nullable: true })
  refundedAt: Date;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
