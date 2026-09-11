import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn,
  ManyToOne, JoinColumn, Index,
} from 'typeorm';
import { Operator } from '../../operators/entities/operator.entity';

export enum PilotStatus {
  ACTIVE = 'active',
  ON_LEAVE = 'on_leave',
  INACTIVE = 'inactive',
}

@Entity('pilots')
export class Pilot {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ name: 'operator_id' })
  operatorId: string;

  @ManyToOne(() => Operator, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'operator_id' })
  operator: Operator;

  @Column({ name: 'name_en' })
  nameEn: string;

  @Column({ name: 'name_ar', nullable: true })
  nameAr: string;

  @Column({ name: 'photo_url', nullable: true, length: 512 })
  photoUrl: string;

  @Column({ name: 'license_number', nullable: true, length: 100 })
  licenseNumber: string;

  @Column({ name: 'license_expiry', type: 'date', nullable: true })
  licenseExpiry: Date;

  @Column({ name: 'total_flights', default: 0 })
  totalFlights: number;

  @Column({ name: 'experience_years', default: 0 })
  experienceYears: number;

  @Column({ type: 'decimal', precision: 2, scale: 1, default: 0.0 })
  rating: number;

  @Index()
  @Column({ type: 'enum', enum: PilotStatus, default: PilotStatus.ACTIVE })
  status: PilotStatus;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
