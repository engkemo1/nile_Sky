import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ReviewsService } from './reviews.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserRole } from '../users/entities/user.entity';

@Controller('reviews')
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  /** Public: only reviews an admin has left visible. */
  @Get()
  async findAll(
    @Query('operatorId') operatorId?: string,
    @Query('flightId') flightId?: string,
    @Query('packageId') packageId?: string,
  ) {
    return this.reviewsService.findAll(operatorId, flightId, packageId);
  }

  /** Staff: everything, hidden ones included, so they can be moderated. */
  @Get('all')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async findAllForAdmin(@Query('operatorId') operatorId?: string) {
    return this.reviewsService.findAllIncludingHidden(operatorId);
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  async create(
    @CurrentUser() user: any,
    @Body()
    body: { bookingId: string; rating: number; comment?: string; photos?: string[] },
  ) {
    return this.reviewsService.create(user.id, body);
  }

  /**
   * Hides or restores a review. An operator had no way to deal with a
   * defamatory or mistaken review other than asking someone to edit the
   * database; hiding keeps the row and takes it off the app.
   */
  @Patch(':id/visibility')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN, UserRole.OPERATOR_ADMIN)
  async setVisibility(
    @Param('id') id: string,
    @Body('isVisible') isVisible: boolean,
  ) {
    return this.reviewsService.setVisibility(id, isVisible !== false);
  }
}
