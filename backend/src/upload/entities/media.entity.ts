import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, Index,
} from 'typeorm';

/**
 * Uploaded files live in Postgres rather than on disk: serverless functions
 * have no persistent filesystem, so anything written locally disappears with
 * the instance. `data` is a bytea column holding the raw bytes.
 */
@Entity('media')
export class Media {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 255 })
  filename: string;

  @Column({ length: 100 })
  mimetype: string;

  @Column({ name: 'size_bytes', type: 'int' })
  sizeBytes: number;

  @Index()
  @Column({ length: 60, default: 'general' })
  folder: string;

  /** Raw file bytes. select:false so listings never drag megabytes around. */
  @Column({ type: 'bytea', select: false })
  data: Buffer;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
