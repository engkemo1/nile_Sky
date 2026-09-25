import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { AnalyticsService } from './analytics.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@Controller('analytics')
export class AnalyticsController {
  constructor(private readonly analyticsService: AnalyticsService) {}

  @Get('dashboard')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async getDashboard(
    @CurrentUser() user: any,
    @Query('operatorId') operatorId?: string,
  ) {
    return this.analyticsService.getDashboardOverview(
      this.scope(user, operatorId),
    );
  }

  /** What each operator is owed for a period, and what the platform keeps. */
  @Get('payouts')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async getPayouts(
    @CurrentUser() user: any,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('operatorId') operatorId?: string,
  ) {
    return this.analyticsService.getPayouts(
      from,
      to,
      this.scope(user, operatorId),
    );
  }

  /** An operator admin only ever sees their own operator's money. */
  private scope(user: any, requested?: string): string | undefined {
    if (user?.role === UserRole.OPERATOR_ADMIN) {
      return user.operatorId ?? '__unlinked__';
    }
    return requested;
  }
}
