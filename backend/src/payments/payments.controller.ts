import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  UseGuards,
  Headers,
  UnauthorizedException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { User, UserRole } from '../users/entities/user.entity';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { PaymentMethod, PaymentGateway } from './entities/payment.entity';
import { timingSafeEqual } from 'crypto';

/** Constant-time compare, so the secret cannot be guessed a character at a time. */
function timingSafeEqualStr(a: string, b: string): boolean {
  const ab = Buffer.from(a);
  const bb = Buffer.from(b);
  if (ab.length !== bb.length) return false;
  return timingSafeEqual(ab, bb);
}

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

  /**
   * Gateways call this with no user token, so the shared secret is the only
   * thing between a stranger and a free flight: without it anyone who guessed
   * a transaction id could mark a booking PAID and CONFIRMED.
   */
  @Post('webhook/:gateway')
  async handleWebhook(
    @Param('gateway') gateway: string,
    @Headers('x-webhook-secret') provided: string,
    @Body() payload: any,
  ) {
    const expected = process.env.PAYMENT_WEBHOOK_SECRET;
    if (!expected) {
      throw new ServiceUnavailableException(
        'Payment webhooks are disabled until PAYMENT_WEBHOOK_SECRET is set.',
      );
    }
    if (!provided || !timingSafeEqualStr(provided, expected)) {
      throw new UnauthorizedException('Invalid webhook signature');
    }
    return this.paymentsService.handleWebhook(gateway, payload);
  }
}
