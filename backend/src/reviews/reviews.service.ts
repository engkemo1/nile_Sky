import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Review } from './entities/review.entity';
import { Booking, BookingStatus } from '../bookings/entities/booking.entity';
import { Operator } from '../operators/entities/operator.entity';

@Injectable()
export class ReviewsService {
  constructor(
    @InjectRepository(Review)
    private readonly reviewRepo: Repository<Review>,
    @InjectRepository(Booking)
    private readonly bookingRepo: Repository<Booking>,
    @InjectRepository(Operator)
    private readonly operatorRepo: Repository<Operator>,
  ) {}

  async findAll(operatorId?: string, flightId?: string, packageId?: string) {
    const query = this.reviewRepo.createQueryBuilder('r')
      .leftJoinAndSelect('r.user', 'user')
      .where('r.isVisible = :isVisible', { isVisible: true });

    if (operatorId) {
      query.andWhere('r.operatorId = :operatorId', { operatorId });
    }
    if (flightId) {
      query.andWhere('r.flightId = :flightId', { flightId });
    }
    // A passenger browsing a package wants reviews of that experience, not of
    // the one flight on one morning, which almost never has any yet.
    if (packageId) {
      query
        .innerJoin('r.flight', 'f')
        .andWhere('f.packageId = :packageId', { packageId });
    }

    return query.orderBy('r.createdAt', 'DESC').take(50).getMany();
  }

  async findAllIncludingHidden(operatorId?: string) {
    const query = this.reviewRepo.createQueryBuilder('r')
      .leftJoinAndSelect('r.user', 'user')
      .leftJoinAndSelect('r.flight', 'flight');
    if (operatorId) {
      query.where('r.operatorId = :operatorId', { operatorId });
    }
    return query.orderBy('r.createdAt', 'DESC').getMany();
  }

  async setVisibility(id: string, isVisible: boolean) {
    const review = await this.reviewRepo.findOne({ where: { id } });
    if (!review) throw new NotFoundException('Review not found');
    review.isVisible = isVisible;
    await this.reviewRepo.save(review);
    // The operator's public rating is an average of visible reviews, so it has
    // to be recomputed whenever one is hidden or restored.
    await this.recalculateOperatorRating(review.operatorId);
    return review;
  }

  async create(userId: string, data: { bookingId: string; rating: number; comment?: string; photos?: string[] }) {
    const booking = await this.bookingRepo.findOne({
      where: { id: data.bookingId },
      relations: { operator: true },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.userId !== userId) {
      throw new BadRequestException('You can only review your own booking');
    }

    const existing = await this.reviewRepo.findOne({ where: { bookingId: data.bookingId } });
    if (existing) {
      throw new BadRequestException('You have already reviewed this booking');
    }

    const review = this.reviewRepo.create({
      userId,
      bookingId: booking.id,
      operatorId: booking.operatorId,
      flightId: booking.flightId,
      rating: data.rating,
      comment: data.comment,
      photos: data.photos || [],
      isVisible: true,
    });

    const saved = await this.reviewRepo.save(review);
    await this.recalculateOperatorRating(booking.operatorId);
    return saved;
  }

  /** The operator's public rating is the average of their visible reviews. */
  private async recalculateOperatorRating(operatorId: string) {
    const stats = await this.reviewRepo
      .createQueryBuilder('r')
      .select('AVG(r.rating)', 'avgRating')
      .addSelect('COUNT(r.id)', 'totalReviews')
      .where('r.operatorId = :operatorId AND r.isVisible = true', { operatorId })
      .getRawOne();

    const operator = await this.operatorRepo.findOne({ where: { id: operatorId } });
    if (operator) {
      operator.rating = parseFloat(stats?.avgRating || '0');
      operator.totalReviews = parseInt(stats?.totalReviews || '0', 10);
      await this.operatorRepo.save(operator);
    }
  }
}
