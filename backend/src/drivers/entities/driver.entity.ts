import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn,
  ManyToOne, JoinColumn, Index,
} from 'typeorm';
import { Operator } from '../../operators/entities/operator.entity';

export enum DriverStatus {
  AVAILABLE = 'available',
  ON_TRIP = 'on_trip',
  OFF_DUTY = 'off_duty',
}

@Entity('drivers')
export class Driver {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ name: 'operator_id' })
  operatorId: string;

  @ManyToOne(() => Operator, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'operator_id' })
  operator: Operator;

  @Column()
  name: string;

  @Column({ length: 20 })
  phone: string;

  @Column({ name: 'car_model', nullable: true, length: 100 })
  carModel: string;

  @Column({ name: 'car_plate', nullable: true, length: 50 })
  carPlate: string;

  @Column({ name: 'photo_url', nullable: true, length: 512 })
  photoUrl: string;

  @Index()
  @Column({ type: 'enum', enum: DriverStatus, default: DriverStatus.AVAILABLE })
  status: DriverStatus;

  @Column({ name: 'current_lat', type: 'decimal', precision: 10, scale: 7, nullable: true })
  currentLat: number;

  @Column({ name: 'current_lng', type: 'decimal', precision: 10, scale: 7, nullable: true })
  currentLng: number;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
