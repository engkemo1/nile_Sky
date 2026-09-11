import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
  ManyToOne, JoinColumn, Index,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum NotificationType {
  BOOKING_CONFIRM = 'booking_confirm',
  REMINDER = 'reminder',
  PICKUP = 'pickup',
  FLIGHT_UPDATE = 'flight_update',
  WEATHER = 'weather',
  REVIEW_REQUEST = 'review_request',
  PROMO = 'promo',
}

@Entity('notifications')
export class Notification {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'title_en', nullable: true })
  titleEn: string;

  @Column({ name: 'title_ar', nullable: true })
  titleAr: string;

  @Column({ name: 'body_en', type: 'text', nullable: true })
  bodyEn: string;

  @Column({ name: 'body_ar', type: 'text', nullable: true })
  bodyAr: string;

  @Column({ type: 'enum', enum: NotificationType })
  type: NotificationType;

  @Column({ type: 'jsonb', nullable: true })
  data: any;

  @Column({ name: 'is_read', default: false })
  isRead: boolean;

  @Column({ name: 'scheduled_at', type: 'timestamptz', nullable: true })
  scheduledAt: Date;

  @Column({ name: 'sent_at', type: 'timestamptz', nullable: true })
  sentAt: Date;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
