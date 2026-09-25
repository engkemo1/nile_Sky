import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Setting } from './entities/setting.entity';

const ROW_ID = 'platform';

/** What a brand new deployment starts with. */
const DEFAULTS: Record<string, any> = {
  platformName: 'NileSky',
  currencyRates: {
    USD: 49.5,
    EUR: 53.2,
    GBP: 62.1,
    EGP: 1.0,
  },
  defaultCommissionRate: 10.0,
  supportEmail: 'support@nilesky.com',
  supportPhone: '+201005385533',
  supportWhatsapp: '+201281824995',
  launchFieldLocation: {
    name: 'West Bank Hot Air Balloon Port, Luxor',
    latitude: 25.7201,
    longitude: 32.6105,
  },
  cancellationPolicy: {
    fullRefundHours: 24,
    partialRefundHours: 12,
    partialRefundPercent: 50,
    weatherCancellationRefundPercent: 100,
  },
  appVersion: '1.0.0',
  minSupportedVersion: '1.0.0',
};

@Injectable()
export class ConfigService implements OnModuleInit {
  /** Read-through cache; the database is the truth. */
  private cache: Record<string, any> = { ...DEFAULTS };

  constructor(
    @InjectRepository(Setting)
    private readonly settingRepo: Repository<Setting>,
  ) {}

  async onModuleInit() {
    await this.load();
  }

  private async load(): Promise<Record<string, any>> {
    try {
      const row = await this.settingRepo.findOne({ where: { id: ROW_ID } });
      if (row?.data) {
        // Defaults first, so a key added in a later release appears without a
        // migration instead of coming back undefined.
        this.cache = { ...DEFAULTS, ...row.data };
      } else {
        await this.settingRepo.save({ id: ROW_ID, data: DEFAULTS });
        this.cache = { ...DEFAULTS };
      }
    } catch {
      // A settings table that is not there yet must not stop the API booting.
      this.cache = { ...DEFAULTS };
    }
    return this.cache;
  }

  async getSettings() {
    return this.cache;
  }

  async getExchangeRates() {
    return this.cache.currencyRates;
  }

  async updateSettings(updates: Partial<Record<string, any>>) {
    const next = { ...this.cache, ...updates };
    // Rates arrive as a whole object; merge so one currency can be changed
    // without wiping the rest.
    if (updates?.currencyRates) {
      next.currencyRates = { ...this.cache.currencyRates, ...updates.currencyRates };
      next.currencyRates.EGP = 1.0;
    }
    await this.settingRepo.save({ id: ROW_ID, data: next });
    this.cache = next;
    return this.cache;
  }
}
