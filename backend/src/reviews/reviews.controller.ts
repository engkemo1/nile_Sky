import { Controller, Get, Post, Param, Body, Query, UseGuards } from '@nestjs/common';
import { ReviewsService } from './reviews.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@Controller('reviews')
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Get()
  async findAll(@Query('operatorId') operatorId?: string, @Query('flightId') flightId?: string) {
    return this.reviewsService.findAll(operatorId, flightId);
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  async create(
    @CurrentUser() user: any,
    @Body() body: { bookingId: string; rating: number; comment?: string; photos?: string[] },
  ) {
    return this.reviewsService.create(user.id, body);
  }
}
