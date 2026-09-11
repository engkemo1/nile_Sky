import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  UseGuards,
  Headers,
} from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { User, UserRole } from '../users/entities/user.entity';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { PaymentMethod, PaymentGateway } from './entities/payment.entity';

@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @UseGuards(JwtAuthGuard)
  @Post('intent')
  async createPaymentIntent(
    @CurrentUser() user: User,
    @Body()
    dto: {
      bookingId: string;
      method: PaymentMethod;
      gateway: PaymentGateway;
      currency?: string;
    },
  ) {
    return this.paymentsService.createPaymentIntent(user.id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/verify')
  async verifyPayment(
    @CurrentUser() user: User,
    @Param('id') paymentId: string,
  ) {
    return this.paymentsService.verifyPayment(user.id, paymentId);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  @Post(':id/refund')
  async refundPayment(
    @Param('id') paymentId: string,
    @Body('reason') reason?: string,
  ) {
    return this.paymentsService.refundPayment(paymentId, reason);
  }

  @UseGuards(JwtAuthGuard)
  @Get('booking/:bookingId')
  async getPaymentsForBooking(@Param('bookingId') bookingId: string) {
    return this.paymentsService.getPaymentsForBooking(bookingId);
  }

  @Post('webhook/:gateway')
  async handleWebhook(
    @Param('gateway') gateway: string,
    @Body() payload: any,
  ) {
    return this.paymentsService.handleWebhook(gateway, payload);
  }
}
