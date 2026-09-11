import { Injectable } from '@nestjs/common';

@Injectable()
export class ConfigService {
  private settings: Record<string, any> = {
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

  getSettings() {
    return this.settings;
  }

  getExchangeRates() {
    return this.settings.currencyRates;
  }

  updateSettings(newSettings: Partial<Record<string, any>>) {
    this.settings = { ...this.settings, ...newSettings };
    return this.settings;
  }
}
