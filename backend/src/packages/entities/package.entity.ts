import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn,
  ManyToOne, JoinColumn, Index,
} from 'typeorm';
import { Operator } from '../../operators/entities/operator.entity';

export enum PackageType {
  STANDARD = 'standard',
  PREMIUM = 'premium',
  PRIVATE = 'private',
}

@Entity('packages')
export class Package {
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

  @Column({ name: 'description_en', type: 'text', nullable: true })
  descriptionEn: string;

  @Column({ name: 'description_ar', type: 'text', nullable: true })
  descriptionAr: string;

  @Index()
  @Column({ type: 'enum', enum: PackageType, default: PackageType.STANDARD })
  type: PackageType;

  @Column({ name: 'duration_minutes' })
  durationMinutes: number;

  @Column({ name: 'has_pickup', default: true })
  hasPickup: boolean;

  @Column({ name: 'has_breakfast', default: false })
  hasBreakfast: boolean;

  @Column({ name: 'is_private', default: false })
  isPrivate: boolean;

  @Column({ name: 'max_guests_if_private', nullable: true })
  maxGuestsIfPrivate: number;

  @Column({ name: 'base_price_egp', type: 'decimal', precision: 10, scale: 2 })
  basePriceEgp: number;

  @Column({ name: 'price_usd', type: 'decimal', precision: 10, scale: 2, nullable: true })
  priceUsd: number;

  @Column({ name: 'price_eur', type: 'decimal', precision: 10, scale: 2, nullable: true })
  priceEur: number;

  @Column({ name: 'price_gbp', type: 'decimal', precision: 10, scale: 2, nullable: true })
  priceGbp: number;

  @Column({ name: 'cover_photo_url', nullable: true, length: 512 })
  coverPhotoUrl: string;

  @Column({ name: 'photos', type: 'jsonb', nullable: true, default: '[]' })
  photos: string[]; // Album of photo URLs for the trip

  @Column({ name: 'video_url', nullable: true, length: 512 })
  videoUrl: string; // Promo video for the trip profile

  @Index()
  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @Column({ name: 'sort_order', default: 0 })
  sortOrder: number;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
