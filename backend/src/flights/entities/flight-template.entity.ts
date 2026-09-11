import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn,
  ManyToOne, JoinColumn, Index,
} from 'typeorm';
import { Operator } from '../../operators/entities/operator.entity';
import { Package } from '../../packages/entities/package.entity';

export enum RecurrenceType {
  DAILY = 'daily',
  WEEKDAYS = 'weekdays',
  WEEKENDS = 'weekends',
  CUSTOM = 'custom',
}

@Entity('flight_templates')
export class FlightTemplate {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ name: 'operator_id' })
  operatorId: string;

  @ManyToOne(() => Operator, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'operator_id' })
  operator: Operator;

  @Column({ name: 'package_id' })
  packageId: string;

  @ManyToOne(() => Package, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'package_id' })
  package: Package;

  @Column({ name: 'departure_time', type: 'time' })
  departureTime: string;

  @Column()
  capacity: number;

  @Column({ type: 'enum', enum: RecurrenceType, default: RecurrenceType.DAILY })
  recurrence: RecurrenceType;

  @Column({ name: 'custom_days', type: 'jsonb', nullable: true })
  customDays: string[];

  @Index()
  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
