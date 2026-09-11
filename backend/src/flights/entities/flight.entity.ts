import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn,
  ManyToOne, JoinColumn, Index,
} from 'typeorm';
import { Operator } from '../../operators/entities/operator.entity';
import { Package } from '../../packages/entities/package.entity';
import { Balloon } from '../../balloons/entities/balloon.entity';
import { Pilot } from '../../pilots/entities/pilot.entity';
import { FlightTemplate } from './flight-template.entity';

export enum FlightStatus {
  SCHEDULED = 'scheduled',
  BOARDING = 'boarding',
  IN_FLIGHT = 'in_flight',
  LANDED = 'landed',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
}

export enum WeatherStatus {
  FAVORABLE = 'favorable',
  UNCERTAIN = 'uncertain',
  UNFAVORABLE = 'unfavorable',
}

@Entity('flights')
export class Flight {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index({ unique: true })
  @Column({ name: 'flight_number', unique: true, length: 20 })
  flightNumber: string;

  @Column({ name: 'flight_template_id', nullable: true })
  flightTemplateId: string;

  @ManyToOne(() => FlightTemplate, { onDelete: 'SET NULL' })
  @JoinColumn({ name: 'flight_template_id' })
  flightTemplate: FlightTemplate;

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

  @Column({ name: 'balloon_id', nullable: true })
  balloonId: string;

  @ManyToOne(() => Balloon, { onDelete: 'SET NULL' })
  @JoinColumn({ name: 'balloon_id' })
  balloon: Balloon;

  @Column({ name: 'pilot_id', nullable: true })
  pilotId: string;

  @ManyToOne(() => Pilot, { onDelete: 'SET NULL' })
  @JoinColumn({ name: 'pilot_id' })
  pilot: Pilot;

  @Index()
  @Column({ name: 'flight_date', type: 'date' })
  flightDate: Date;

  @Column({ name: 'departure_time', type: 'time' })
  departureTime: string;

  @Column()
  capacity: number;

  @Column({ name: 'booked_count', default: 0 })
  bookedCount: number;

  @Column({ name: 'price_egp', type: 'decimal', precision: 10, scale: 2 })
  priceEgp: number;

  @Index()
  @Column({ type: 'enum', enum: FlightStatus, default: FlightStatus.SCHEDULED })
  status: FlightStatus;

  @Column({ name: 'weather_status', type: 'enum', enum: WeatherStatus, default: WeatherStatus.FAVORABLE })
  weatherStatus: WeatherStatus;

  @Column({ name: 'cancellation_reason', type: 'text', nullable: true })
  cancellationReason: string;

  @Column({ name: 'confirmed_at', type: 'timestamptz', nullable: true })
  confirmedAt: Date;

  @Column({ name: 'photos', type: 'jsonb', nullable: true, default: '[]' })
  photos: string[]; // Flight-specific photos (e.g. taken during this flight)

  @Column({ name: 'video_url', nullable: true, length: 512 })
  videoUrl: string; // Flight video recording

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
