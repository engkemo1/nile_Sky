import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn,
  ManyToOne, JoinColumn, Index,
} from 'typeorm';
import { Operator } from '../../operators/entities/operator.entity';

export enum CouponType {
  PERCENTAGE = 'percentage',
  FIXED = 'fixed',
}

@Entity('coupons')
export class Coupon {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index({ unique: true })
  @Column({ unique: true, length: 50 })
  code: string;

  @Column({ type: 'enum', enum: CouponType })
  type: CouponType;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  value: number;

  @Column({ name: 'max_discount_egp', type: 'decimal', precision: 10, scale: 2, nullable: true })
  maxDiscountEgp: number;

  @Column({ name: 'valid_from', type: 'date' })
  validFrom: Date;

  @Column({ name: 'valid_to', type: 'date' })
  validTo: Date;

  @Column({ name: 'max_uses', nullable: true })
  maxUses: number;

  @Column({ name: 'used_count', default: 0 })
  usedCount: number;

  @Column({ name: 'operator_id', nullable: true })
  operatorId: string;

  @ManyToOne(() => Operator, { onDelete: 'SET NULL' })
  @JoinColumn({ name: 'operator_id' })
  operator: Operator;

  @Index()
  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
