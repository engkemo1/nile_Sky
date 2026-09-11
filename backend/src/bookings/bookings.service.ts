import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Booking, BookingStatus, PaymentStatus } from './entities/booking.entity';
import { Flight, FlightStatus } from '../flights/entities/flight.entity';
import { Operator } from '../operators/entities/operator.entity';
import { Coupon, CouponType } from '../coupons/entities/coupon.entity';
import { CreateBookingDto, UpdateBookingStatusDto, AssignDriverDto } from './dto/booking.dto';
import { User, UserRole } from '../users/entities/user.entity';

@Injectable()
export class BookingsService {
  constructor(
    @InjectRepository(Booking)
    private readonly bookingRepo: Repository<Booking>,
    @InjectRepository(Flight)
    private readonly flightRepo: Repository<Flight>,
    @InjectRepository(Operator)
    private readonly operatorRepo: Repository<Operator>,
    @InjectRepository(Coupon)
    private readonly couponRepo: Repository<Coupon>,
  ) {}

  async create(userId: string, dto: CreateBookingDto) {
    const flight = await this.flightRepo.findOne({
      where: { id: dto.flightId },
      relations: { operator: true, package: true },
    });

    if (!flight) {
      throw new NotFoundException('Flight not found');
    }

    if (flight.status !== FlightStatus.SCHEDULED) {
      throw new BadRequestException('Cannot book a flight that is not scheduled');
    }

    const availableSeats = flight.capacity - flight.bookedCount;
    if (availableSeats < dto.guestCount) {
      throw new BadRequestException(`Not enough available seats. Only ${availableSeats} left.`);
    }

    // Calculate total price
    const subtotal = Number(flight.priceEgp) * dto.guestCount;
    let discountAmount = 0;
    let appliedCoupon: Coupon | null = null;

    if (dto.couponCode) {
      appliedCoupon = await this.couponRepo.findOne({
        where: { code: dto.couponCode.toUpperCase(), isActive: true },
      });

      if (appliedCoupon) {
        const now = new Date();
        const validFrom = new Date(appliedCoupon.validFrom);
        const validTo = new Date(appliedCoupon.validTo);

        if (now >= validFrom && now <= validTo) {
          if (!appliedCoupon.operatorId || appliedCoupon.operatorId === flight.operatorId) {
            if (!appliedCoupon.maxUses || appliedCoupon.usedCount < appliedCoupon.maxUses) {
              if (appliedCoupon.type === CouponType.PERCENTAGE) {
                discountAmount = (subtotal * Number(appliedCoupon.value)) / 100;
                if (appliedCoupon.maxDiscountEgp && discountAmount > Number(appliedCoupon.maxDiscountEgp)) {
                  discountAmount = Number(appliedCoupon.maxDiscountEgp);
                }
              } else {
                discountAmount = Number(appliedCoupon.value);
              }
              appliedCoupon.usedCount += 1;
              await this.couponRepo.save(appliedCoupon);
            }
          }
        }
      }
    }

    const totalPriceEgp = Math.max(0, subtotal - discountAmount);

    // Calculate commission
    const commissionRate = flight.operator?.commissionRate || 10.0;
    const commissionAmount = (totalPriceEgp * Number(commissionRate)) / 100;

    // Generate Booking Ref: NLK-YYYY-MM-XXXX
    const date = new Date();
    const dateStr = date.toISOString().slice(0, 7).replace('-', '');
    const rand = Math.floor(1000 + Math.random() * 9000);
    const bookingRef = `NLK-${dateStr}-${rand}`;

    // Estimated pickup time: 2.5 hours before flight departure
    const departureParts = flight.departureTime.split(':');
    let depHour = parseInt(departureParts[0], 10);
    let depMin = parseInt(departureParts[1], 10);
    let pickupHour = depHour - 2;
    let pickupMin = depMin - 30;
    if (pickupMin < 0) {
      pickupMin += 60;
      pickupHour -= 1;
    }
    if (pickupHour < 0) pickupHour += 24;
    const pickupTime = `${String(pickupHour).padStart(2, '0')}:${String(pickupMin).padStart(2, '0')}:00`;

    // QR code payload data
    const qrPayload = JSON.stringify({
      ref: bookingRef,
      flightNumber: flight.flightNumber,
      flightDate: flight.flightDate,
      guests: dto.guestCount,
      operator: flight.operator?.nameEn,
    });

    const booking = this.bookingRepo.create({
      bookingRef,
      userId,
      flightId: flight.id,
      operatorId: flight.operatorId,
      guestCount: dto.guestCount,
      totalPriceEgp,
      commissionAmount,
      paymentStatus: PaymentStatus.PAID, // Simulated direct confirmation for MVP demo flow
      bookingStatus: BookingStatus.CONFIRMED,
      pickupLocation: dto.pickupLocation,
      pickupHotelName: dto.pickupHotelName,
      pickupLat: dto.pickupLat,
      pickupLng: dto.pickupLng,
      pickupTime,
      qrCodeData: qrPayload,
      specialRequests: dto.specialRequests,
      guestDetails: dto.guestDetails || [],
      couponId: appliedCoupon ? appliedCoupon.id : null,
      discountAmount,
    });

    const saved = await this.bookingRepo.save(booking);

    // Increment flight booked count
    flight.bookedCount += dto.guestCount;
    await this.flightRepo.save(flight);

    return this.findOne(saved.id);
  }

  async findAll(user: { id: string; role: UserRole }, operatorId?: string, flightId?: string) {
    const query = this.bookingRepo.createQueryBuilder('b')
      .leftJoinAndSelect('b.user', 'user')
      .leftJoinAndSelect('b.flight', 'flight')
      .leftJoinAndSelect('flight.package', 'package')
      .leftJoinAndSelect('b.operator', 'operator')
      .leftJoinAndSelect('b.driver', 'driver');

    if (user.role === UserRole.CUSTOMER) {
      query.andWhere('b.userId = :userId', { userId: user.id });
    } else if (user.role === UserRole.OPERATOR_ADMIN) {
      if (operatorId) {
        query.andWhere('b.operatorId = :operatorId', { operatorId });
      }
    }

    if (flightId) {
      query.andWhere('b.flightId = :flightId', { flightId });
    }

    return query.orderBy('b.createdAt', 'DESC').getMany();
  }

  async findOne(id: string) {
    const booking = await this.bookingRepo.findOne({
      where: { id },
      relations: {
        user: true,
        flight: {
          package: true,
          balloon: true,
          pilot: true,
        },
        operator: true,
        driver: true,
      },
    });

    if (!booking) {
      throw new NotFoundException(`Booking with ID ${id} not found`);
    }

    return booking;
  }

  async findByRef(ref: string) {
    const booking = await this.bookingRepo.findOne({
      where: { bookingRef: ref },
      relations: {
        user: true,
        flight: {
          package: true,
        },
        operator: true,
        driver: true,
      },
    });
    if (!booking) {
      throw new NotFoundException(`Booking ref ${ref} not found`);
    }
    return booking;
  }

  async cancelBooking(id: string, userId: string, userRole: UserRole, reason?: string) {
    const booking = await this.findOne(id);

    if (userRole === UserRole.CUSTOMER && booking.userId !== userId) {
      throw new ForbiddenException('You cannot cancel another user booking');
    }

    if (booking.bookingStatus === BookingStatus.CANCELLED) {
      throw new BadRequestException('Booking is already cancelled');
    }

    // Calculate refund policy
    const flightDate = new Date(booking.flight.flightDate);
    const now = new Date();
    const diffHours = (flightDate.getTime() - now.getTime()) / (1000 * 60 * 60);

    let refundPercent = 0;
    if (userRole === UserRole.PLATFORM_ADMIN || userRole === UserRole.OPERATOR_ADMIN) {
      refundPercent = 100; // full refund if operator/admin cancels
    } else {
      if (diffHours >= 24) {
        refundPercent = 100;
      } else if (diffHours >= 12) {
        refundPercent = 50;
      } else {
        refundPercent = 0;
      }
    }

    booking.bookingStatus = BookingStatus.CANCELLED;
    booking.cancellationReason = reason || 'Cancelled by user';
    booking.cancelledAt = new Date();

    if (refundPercent === 100) {
      booking.paymentStatus = PaymentStatus.REFUNDED;
    } else if (refundPercent > 0) {
      booking.paymentStatus = PaymentStatus.PARTIAL_REFUND;
    }

    // Decrement flight booked count
    const flight = await this.flightRepo.findOne({ where: { id: booking.flightId } });
    if (flight) {
      flight.bookedCount = Math.max(0, flight.bookedCount - booking.guestCount);
      await this.flightRepo.save(flight);
    }

    const updated = await this.bookingRepo.save(booking);

    return {
      booking: updated,
      refundPercent,
      refundAmountEgp: (Number(booking.totalPriceEgp) * refundPercent) / 100,
    };
  }

  async checkIn(bookingRef: string) {
    const booking = await this.findByRef(bookingRef);
    if (booking.bookingStatus === BookingStatus.CANCELLED) {
      throw new BadRequestException('Cannot check in a cancelled booking');
    }
    booking.bookingStatus = BookingStatus.CHECKED_IN;
    return this.bookingRepo.save(booking);
  }

  async assignDriver(id: string, dto: AssignDriverDto) {
    const booking = await this.findOne(id);
    booking.driverId = dto.driverId;
    if (dto.pickupTime) {
      booking.pickupTime = dto.pickupTime;
    }
    return this.bookingRepo.save(booking);
  }
}
