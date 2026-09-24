import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn,
  OneToMany, Index,
} from 'typeorm';

export enum UserRole {
  CUSTOMER = 'customer',
  OPERATOR_ADMIN = 'operator_admin',
  PLATFORM_ADMIN = 'platform_admin',
}

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index({ unique: true })
  @Column({ unique: true })
  email: string;

  @Column({ nullable: true, length: 20 })
  phone: string;

  @Column({ name: 'password_hash', nullable: true })
  passwordHash: string;

  @Column()
  name: string;

  @Column({ name: 'avatar_url', nullable: true, length: 512 })
  avatarUrl: string;

  @Column({ type: 'enum', enum: UserRole, default: UserRole.CUSTOMER })
  role: UserRole;

  /**
   * Which operator an OPERATOR_ADMIN belongs to. Null for customers and for
   * platform admins, who see everything. Without this an operator admin could
   * read every rival operator's bookings and every passenger's contact details.
   */
  @Column({ name: 'operator_id', type: 'uuid', nullable: true })
  operatorId: string | null;

  @Column({ name: 'language_pref', default: 'en', length: 5 })
  languagePref: string;

  @Column({ name: 'currency_pref', default: 'EGP', length: 3 })
  currencyPref: string;

  @Column({ name: 'is_verified', default: false })
  isVerified: boolean;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @Column({ name: 'social_provider', nullable: true, length: 20 })
  socialProvider: string;

  @Column({ name: 'social_id', nullable: true })
  socialId: string;

  @Column({ name: 'refresh_token_hash', nullable: true })
  refreshTokenHash: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
