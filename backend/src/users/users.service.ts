import {
  Injectable,
  NotFoundException,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserRole } from './entities/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {}

  async findAll(role?: UserRole): Promise<User[]> {
    const query = this.userRepo.createQueryBuilder('user');
    if (role) {
      query.where('user.role = :role', { role });
    }
    return query.orderBy('user.createdAt', 'DESC').getMany();
  }

  async findById(id: string): Promise<User> {
    const user = await this.userRepo.findOne({ where: { id } });
    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
    return user;
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.userRepo.findOne({ where: { email: email.toLowerCase() } });
  }

  /**
   * Lets a signed-in user rotate their own password. Needed because the
   * seeded admin password ended up in a public repository and the only other
   * way to change it was to edit the database by hand.
   */
  async changePassword(userId: string, currentPassword: string, newPassword: string) {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    if (!user.passwordHash) {
      throw new BadRequestException('This account has no password to change');
    }
    const matches = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!matches) throw new UnauthorizedException('Current password is incorrect');
    if (newPassword.length < 10) {
      throw new BadRequestException('The new password must be at least 10 characters');
    }
    user.passwordHash = await bcrypt.hash(newPassword, 10);
    // Any refresh token issued against the old password stops working.
    user.refreshTokenHash = null;
    await this.userRepo.save(user);
    return { changed: true };
  }

  async updateProfile(
    id: string,
    updates: {
      name?: string;
      phone?: string;
      avatarUrl?: string;
      languagePref?: string;
      currencyPref?: string;
    },
  ): Promise<User> {
    const user = await this.findById(id);
    if (updates.name !== undefined) user.name = updates.name;
    if (updates.phone !== undefined) user.phone = updates.phone;
    if (updates.avatarUrl !== undefined) user.avatarUrl = updates.avatarUrl;
    if (updates.languagePref !== undefined) user.languagePref = updates.languagePref;
    if (updates.currencyPref !== undefined) user.currencyPref = updates.currencyPref;

    return this.userRepo.save(user);
  }

  async updateStatus(id: string, isActive: boolean): Promise<User> {
    const user = await this.findById(id);
    user.isActive = isActive;
    return this.userRepo.save(user);
  }

  async setVerified(id: string, isVerified: boolean): Promise<User> {
    const user = await this.findById(id);
    user.isVerified = isVerified;
    return this.userRepo.save(user);
  }
}
