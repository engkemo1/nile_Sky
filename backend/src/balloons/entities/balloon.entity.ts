import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn,
  ManyToOne, JoinColumn, Index,
} from 'typeorm';
import { Operator } from '../../operators/entities/operator.entity';

export enum BalloonStatus {
  AVAILABLE = 'available',
  IN_FLIGHT = 'in_flight',
  MAINTENANCE = 'maintenance',
  RETIRED = 'retired',
}

@Entity('balloons')
export class Balloon {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ name: 'operator_id' })
  operatorId: string;

  @ManyToOne(() => Operator, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'operator_id' })
  operator: Operator;

  @Column({ name: 'registration_code', unique: true, length: 50 })
  registrationCode: string;

  @Column({ nullable: true, length: 100 })
  name: string;

  @Column()
  capacity: number;

  @Index()
  @Column({ type: 'enum', enum: BalloonStatus, default: BalloonStatus.AVAILABLE })
  status: BalloonStatus;

  @Column({ name: 'last_inspection', type: 'date', nullable: true })
  lastInspection: Date;

  @Column({ name: 'inspection_doc_url', nullable: true, length: 512 })
  inspectionDocUrl: string;

  @Column({ name: 'insurance_doc_url', nullable: true, length: 512 })
  insuranceDocUrl: string;

  @Column({ name: 'insurance_expiry', type: 'date', nullable: true })
  insuranceExpiry: Date;

  @Column({ name: 'photo_url', nullable: true, length: 512 })
  photoUrl: string;

  @Column({ name: 'photos', type: 'jsonb', nullable: true, default: '[]' })
  photos: string[]; // Album of photo URLs

  @Column({ name: 'video_url', nullable: true, length: 512 })
  videoUrl: string; // Promo or flight video

  @Column({ type: 'text', nullable: true })
  notes: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
