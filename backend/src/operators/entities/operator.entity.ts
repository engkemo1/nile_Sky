import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn,
  ManyToOne, OneToMany, JoinColumn, Index,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum OperatorStatus {
  PENDING = 'pending',
  VERIFIED = 'verified',
  SUSPENDED = 'suspended',
}

@Entity('operators')
export class Operator {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'name_en' })
  nameEn: string;

  @Column({ name: 'name_ar', nullable: true })
  nameAr: string;

  @Column({ name: 'description_en', type: 'text', nullable: true })
  descriptionEn: string;

  @Column({ name: 'description_ar', type: 'text', nullable: true })
  descriptionAr: string;

  @Column({ name: 'logo_url', nullable: true, length: 512 })
  logoUrl: string;

  @Column({ name: 'cover_photo_url', nullable: true, length: 512 })
  coverPhotoUrl: string;

  @Column({ name: 'photos', type: 'jsonb', nullable: true, default: '[]' })
  photos: string[]; // Gallery photos for operator profile

  @Column({ name: 'video_url', nullable: true, length: 512 })
  videoUrl: string; // Promo video for operator profile

  @Column({ nullable: true, length: 20 })
  phone: string;

  @Column({ nullable: true })
  email: string;

  @Column({ nullable: true, length: 512 })
  website: string;

  @Column({ nullable: true, length: 20 })
  whatsapp: string;

  @Column({ type: 'decimal', precision: 2, scale: 1, default: 0.0 })
  rating: number;

  @Column({ name: 'total_reviews', default: 0 })
  totalReviews: number;

  @Column({ name: 'total_flights', default: 0 })
  totalFlights: number;

  @Index()
  @Column({ type: 'enum', enum: OperatorStatus, default: OperatorStatus.PENDING })
  status: OperatorStatus;

  @Column({ name: 'license_number', nullable: true, length: 100 })
  licenseNumber: string;

  @Column({ name: 'license_doc_url', nullable: true, length: 512 })
  licenseDocUrl: string;

  @Column({ name: 'license_expiry', type: 'date', nullable: true })
  licenseExpiry: Date;

  @Column({ name: 'insurance_doc_url', nullable: true, length: 512 })
  insuranceDocUrl: string;

  @Column({ name: 'insurance_expiry', type: 'date', nullable: true })
  insuranceExpiry: Date;

  @Column({ type: 'text', nullable: true })
  address: string;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  latitude: number;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  longitude: number;

  @Column({ name: 'commission_rate', type: 'decimal', precision: 4, scale: 2, default: 10.0 })
  commissionRate: number;

  @Column({ name: 'owner_user_id', nullable: true })
  ownerUserId: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL' })
  @JoinColumn({ name: 'owner_user_id' })
  owner: User;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
