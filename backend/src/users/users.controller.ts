import {
  Controller,
  Get,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { User, UserRole } from './entities/user.entity';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  /** Strip secrets that must never leave the API. */
  private sanitize(user: any) {
    if (!user) return user;
    const { passwordHash, refreshTokenHash, socialId, ...safe } = user;
    return safe;
  }


  @UseGuards(JwtAuthGuard)
  @Get('me')
  async getMe(@CurrentUser() user: User) {
    return this.sanitize(await this.usersService.findById(user.id));
  }

  @UseGuards(JwtAuthGuard)
  @Patch('me')
  async updateMe(
    @CurrentUser() user: User,
    @Body()
    dto: {
      name?: string;
      phone?: string;
      avatarUrl?: string;
      languagePref?: string;
      currencyPref?: string;
    },
  ) {
    return this.sanitize(await this.usersService.updateProfile(user.id, dto));
  }

  @UseGuards(JwtAuthGuard)
  @Patch('me/password')
  async changeMyPassword(
    @CurrentUser() user: User,
    @Body() dto: { currentPassword: string; newPassword: string },
  ) {
    return this.usersService.changePassword(
      user.id,
      dto?.currentPassword ?? '',
      dto?.newPassword ?? '',
    );
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN)
  @Get()
  async getAllUsers(@Query('role') role?: UserRole) {
    return (await this.usersService.findAll(role)).map((u) => this.sanitize(u));
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN)
  @Get(':id')
  async getUserById(@Param('id') id: string) {
    return this.sanitize(await this.usersService.findById(id));
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PLATFORM_ADMIN)
  @Patch(':id/status')
  async updateUserStatus(
    @Param('id') id: string,
    @Body('isActive') isActive: boolean,
  ) {
    return this.sanitize(await this.usersService.updateStatus(id, isActive));
  }
}
