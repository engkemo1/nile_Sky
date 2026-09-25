import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Flight } from '../flights/entities/flight.entity';
import { Booking, BookingStatus } from '../bookings/entities/booking.entity';
import { Operator } from '../operators/entities/operator.entity';

@Injectable()
export class AnalyticsService {
  constructor(
    @InjectRepository(Flight)
    private readonly flightRepo: Repository<Flight>,
    @InjectRepository(Booking)
    private readonly bookingRepo: Repository<Booking>,
    @InjectRepository(Operator)
    private readonly operatorRepo: Repository<Operator>,
  ) {}

  /**
   * What each operator is owed for a period.
   *
   * Money actually collected is the paid, non-cancelled bookings. The platform
   * keeps commissionRate percent of that; the rest is the operator's. Nothing
   * here was computed anywhere before, so settling up meant exporting bookings
   * and doing it in a spreadsheet.
   */
  async getPayouts(from?: string, to?: string, operatorId?: string) {
    const query = this.bookingRepo
      .createQueryBuilder('b')
      .leftJoin('b.flight', 'flight')
      .select('b.operatorId', 'operatorId')
      .addSelect('COUNT(b.id)', 'bookings')
      .addSelect('SUM(b.guestCount)', 'passengers')
      .addSelect('SUM(b.totalPriceEgp)', 'grossEgp')
      .where('b.paymentStatus = :paid', { paid: 'paid' })
      .andWhere('b.bookingStatus != :cancelled', { cancelled: BookingStatus.CANCELLED });

    if (from) query.andWhere('flight.flightDate >= :from', { from });
    if (to) query.andWhere('flight.flightDate <= :to', { to });
    if (operatorId) query.andWhere('b.operatorId = :operatorId', { operatorId });

    const rows = await query.groupBy('b.operatorId').getRawMany();
    const operators = await this.operatorRepo.find();
    const byId = new Map(operators.map((o) => [o.id, o]));

    const lines = rows.map((r) => {
      const op = byId.get(r.operatorId);
      // Postgres returns SUM() of a numeric column as a string.
      const gross = parseFloat(r.grossEgp || '0');
      const rate = parseFloat(String(op?.commissionRate ?? 0));
      const commission = Math.round(gross * rate) / 100;
      return {
        operatorId: r.operatorId,
        operatorName: op?.nameEn ?? 'Unknown operator',
        bookings: parseInt(r.bookings || '0', 10),
        passengers: parseInt(r.passengers || '0', 10),
        grossEgp: gross,
        commissionRate: rate,
        commissionEgp: commission,
        netPayableEgp: Math.round((gross - commission) * 100) / 100,
      };
    });

    lines.sort((a, b) => b.netPayableEgp - a.netPayableEgp);

    return {
      from: from ?? null,
      to: to ?? null,
      lines,
      totals: {
        grossEgp: lines.reduce((t, l) => t + l.grossEgp, 0),
        commissionEgp: lines.reduce((t, l) => t + l.commissionEgp, 0),
        netPayableEgp: lines.reduce((t, l) => t + l.netPayableEgp, 0),
      },
    };
  }

  async getDashboardOverview(operatorId?: string) {
    const today = new Date().toISOString().slice(0, 10);

    const flightQuery = this.flightRepo.createQueryBuilder('f')
      .where('f.flightDate = :today', { today });
    if (operatorId) flightQuery.andWhere('f.operatorId = :operatorId', { operatorId });
    const todayFlights = await flightQuery.getMany();

    const bookingQuery = this.bookingRepo.createQueryBuilder('b')
      .leftJoinAndSelect('b.flight', 'flight')
      .where('flight.flightDate = :today', { today })
      .andWhere('b.bookingStatus != :cancelled', { cancelled: BookingStatus.CANCELLED });
    if (operatorId) bookingQuery.andWhere('b.operatorId = :operatorId', { operatorId });
    const todayBookings = await bookingQuery.getMany();

    const totalRevenueEgp = todayBookings.reduce((sum, b) => sum + Number(b.totalPriceEgp), 0);
    const totalPassengers = todayBookings.reduce((sum, b) => sum + b.guestCount, 0);

    // Operator stats
    const totalOperators = await this.operatorRepo.count();

    // All-time bookings summary
    const allBookingsQuery = this.bookingRepo.createQueryBuilder('b');
    if (operatorId) allBookingsQuery.where('b.operatorId = :operatorId', { operatorId });
    const allBookings = await allBookingsQuery.getMany();
    const allTimeRevenueEgp = allBookings
      .filter((b) => b.bookingStatus !== BookingStatus.CANCELLED)
      .reduce((sum, b) => sum + Number(b.totalPriceEgp), 0);

    return {
      today: {
        flightsCount: todayFlights.length,
        bookingsCount: todayBookings.length,
        passengersCount: totalPassengers,
        revenueEgp: totalRevenueEgp,
      },
      allTime: {
        totalOperators,
        totalBookings: allBookings.length,
        revenueEgp: allTimeRevenueEgp,
      },
      todayFlightsSummary: todayFlights.map((f) => ({
        id: f.id,
        flightNumber: f.flightNumber,
        departureTime: f.departureTime,
        status: f.status,
        capacity: f.capacity,
        bookedCount: f.bookedCount,
      })),
    };
  }
}
