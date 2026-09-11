import { Controller, Get, Patch, Body, UseGuards } from '@nestjs/common';
import { ConfigService } from './config.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';

@Controller('config')
export class ConfigController {
  constructor(private readonly configService: ConfigService) {}

  @Get()
  getSettings() {
    return this.configService.getSettings();
  }

  @Get('rates')
  getRates() {
    return this.configService.getExchangeRates();
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN)
  @Patch()
  updateSettings(@Body() updates: Partial<Record<string, any>>) {
    return this.configService.updateSettings(updates);
  }
}
