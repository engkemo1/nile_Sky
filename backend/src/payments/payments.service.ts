import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  Payment,
  PaymentMethod,
  PaymentGateway,
  TransactionStatus,
} from './entities/payment.entity';
import {
  Booking,
  BookingStatus,
  PaymentStatus,
} from '../bookings/entities/booking.entity';
import { Flight } from '../flights/entities/flight.entity';

@Injectable()
export class PaymentsService {
  constructor(
    @InjectRepository(Payment)
    private readonly paymentRepo: Repository<Payment>,
    @InjectRepository(Booking)
    private readonly bookingRepo: Repository<Booking>,
    @InjectRepository(Flight)
    private readonly flightRepo: Repository<Flight>,
  ) {}

  async createPaymentIntent(
    userId: string,
    dto: {
      bookingId: string;
      method: PaymentMethod;
      gateway: PaymentGateway;
      currency?: string;
    },
  ) {
    const booking = await this.bookingRepo.findOne({
      where: { id: dto.bookingId },
      relations: { flight: true },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.userId !== userId) {
      throw new BadRequestException('Unauthorized booking payment access');
    }

    if (booking.paymentStatus === PaymentStatus.PAID) {
      throw new BadRequestException('Booking has already been paid');
    }

    const currency = (dto.currency || 'EGP').toUpperCase();
    let amountCharged = Number(booking.totalPriceEgp);

    // Approximate exchange rates
    if (currency === 'USD') {
      amountCharged = Math.round((amountCharged / 49.5) * 100) / 100;
    } else if (currency === 'EUR') {
      amountCharged = Math.round((amountCharged / 53.2) * 100) / 100;
    } else if (currency === 'GBP') {
      amountCharged = Math.round((amountCharged / 62.1) * 100) / 100;
    }

    const txnPrefix =
      dto.gateway === PaymentGateway.PAYMOB
        ? 'PM-'
        : dto.gateway === PaymentGateway.FAWRY
        ? 'FW-'
        : 'pi_stripe_';
    const gatewayTransactionId = `${txnPrefix}${Date.now()}-${Math.floor(
      1000 + Math.random() * 9000,
    )}`;

    const payment = this.paymentRepo.create({
      bookingId: booking.id,
      userId,
      amountEgp: booking.totalPriceEgp,
      currencyCharged: currency,
      amountCharged,
      method: dto.method || PaymentMethod.CARD,
      gateway: dto.gateway || PaymentGateway.PAYMOB,
      gatewayTransactionId,
      status: TransactionStatus.PENDING,
      gatewayResponse: {
        clientSecret: `sec_${gatewayTransactionId}`,
        checkoutUrl: `https://checkout.nilesky.com/pay/${gatewayTransactionId}`,
        supportedMethods: ['visa', 'mastercard', 'meeza', 'vodafone_cash'],
      },
    });

    const savedPayment = await this.paymentRepo.save(payment);

    return {
      paymentId: savedPayment.id,
      bookingRef: booking.bookingRef,
      gatewayTransactionId,
      currencyCharged: currency,
      amountCharged,
      amountEgp: booking.totalPriceEgp,
      gateway: dto.gateway,
      clientSecret: `sec_${gatewayTransactionId}`,
      checkoutUrl: `https://checkout.nilesky.com/pay/${gatewayTransactionId}`,
    };
  }

  async verifyPayment(userId: string, paymentId: string) {
    const payment = await this.paymentRepo.findOne({
      where: { id: paymentId },
      relations: { booking: true },
    });

    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    payment.status = TransactionStatus.SUCCESS;
    payment.paidAt = new Date();
    await this.paymentRepo.save(payment);

    const booking = await this.bookingRepo.findOne({
      where: { id: payment.bookingId },
    });
    if (booking) {
      booking.paymentStatus = PaymentStatus.PAID;
      booking.bookingStatus = BookingStatus.CONFIRMED;
      await this.bookingRepo.save(booking);

      // Increase booked count on flight
      await this.flightRepo.increment(
        { id: booking.flightId },
        'bookedCount',
        booking.guestCount,
      );
    }

    return {
      success: true,
      message: 'Payment verified and booking confirmed successfully',
      paymentId: payment.id,
      bookingRef: booking?.bookingRef,
      status: TransactionStatus.SUCCESS,
      paidAt: payment.paidAt,
    };
  }

  async refundPayment(paymentId: string, reason?: string) {
    const payment = await this.paymentRepo.findOne({
      where: { id: paymentId },
    });
    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    payment.status = TransactionStatus.REFUNDED;
    payment.refundedAt = new Date();
    await this.paymentRepo.save(payment);

    const booking = await this.bookingRepo.findOne({
      where: { id: payment.bookingId },
    });
    if (booking) {
      booking.paymentStatus = PaymentStatus.REFUNDED;
      booking.bookingStatus = BookingStatus.CANCELLED;
      booking.cancellationReason = reason || 'Refund issued';
      booking.cancelledAt = new Date();
      await this.bookingRepo.save(booking);

      // Decrement booked count on flight
      await this.flightRepo.decrement(
        { id: booking.flightId },
        'bookedCount',
        booking.guestCount,
      );
    }

    return {
      success: true,
      message: 'Payment refunded successfully',
      paymentId: payment.id,
      status: TransactionStatus.REFUNDED,
    };
  }

  async getPaymentsForBooking(bookingId: string): Promise<Payment[]> {
    return this.paymentRepo.find({
      where: { bookingId },
      order: { createdAt: 'DESC' },
    });
  }

  async handleWebhook(gateway: string, payload: any) {
    // Process async gateway webhooks (Paymob, Fawry, Stripe)
    const txnId =
      payload?.id ||
      payload?.transaction_id ||
      payload?.data?.object?.id ||
      payload?.ReferenceNumber;

    if (!txnId) {
      return { received: true };
    }

    const payment = await this.paymentRepo.findOne({
      where: { gatewayTransactionId: txnId },
    });
    if (payment) {
      payment.status = TransactionStatus.SUCCESS;
      payment.paidAt = new Date();
      payment.gatewayResponse = payload;
      await this.paymentRepo.save(payment);

      const booking = await this.bookingRepo.findOne({
        where: { id: payment.bookingId },
      });
      if (booking && booking.paymentStatus !== PaymentStatus.PAID) {
        booking.paymentStatus = PaymentStatus.PAID;
        booking.bookingStatus = BookingStatus.CONFIRMED;
        await this.bookingRepo.save(booking);

        await this.flightRepo.increment(
          { id: booking.flightId },
          'bookedCount',
          booking.guestCount,
        );
      }
    }

    return { received: true, status: 'processed' };
  }
}
