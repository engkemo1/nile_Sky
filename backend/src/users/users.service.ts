import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
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
