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
