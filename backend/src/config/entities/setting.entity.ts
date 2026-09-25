import { Entity, PrimaryColumn, Column, UpdateDateColumn } from 'typeorm';

/**
 * One row holding the whole platform settings blob.
 *
 * Settings used to live in a field on the service, which meant an admin could
 * change the exchange rates, watch them take effect, and then find them back
 * to the defaults after the next cold start — on serverless, that is minutes.
 */
@Entity('platform_settings')
export class Setting {
  @PrimaryColumn({ length: 32 })
  id: string;

  @Column({ type: 'jsonb' })
  data: Record<string, any>;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
