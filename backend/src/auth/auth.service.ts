import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User, UserRole } from '../users/entities/user.entity';
import { RegisterDto, LoginDto } from './dto/auth.dto';
import {
  jwtSecret,
  jwtRefreshSecret,
  accessTokenTtl,
  refreshTokenTtl,
} from '../common/security';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly jwtService: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    const existing = await this.userRepo.findOne({ where: { email: dto.email } });
    if (existing) {
      throw new ConflictException('Email already registered');
    }

    const passwordHash = await bcrypt.hash(dto.password, 12);
    const user = this.userRepo.create({
      name: dto.name,
      email: dto.email,
      phone: dto.phone,
      passwordHash,
      role: UserRole.CUSTOMER,
      languagePref: dto.languagePref || 'en',
    });

    const saved = await this.userRepo.save(user);
    const tokens = await this.generateTokens(saved);

    return {
      user: this.sanitizeUser(saved),
      ...tokens,
    };
  }

  async login(dto: LoginDto) {
    const user = await this.userRepo.findOne({ where: { email: dto.email } });
    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const isPasswordValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const tokens = await this.generateTokens(user);
    return {
      user: this.sanitizeUser(user),
      ...tokens,
    };
  }

  async refreshToken(refreshToken: string) {
    try {
      const payload = this.jwtService.verify(refreshToken, {
        secret: jwtRefreshSecret(),
      });

      const user = await this.userRepo.findOne({ where: { id: payload.sub } });
      if (!user || !user.isActive) {
        throw new UnauthorizedException('Invalid refresh token');
      }

      const tokens = await this.generateTokens(user);
      return tokens;
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  async validateUserById(userId: string): Promise<User> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user || !user.isActive) {
      throw new UnauthorizedException('User not found or inactive');
    }
    return user;
  }

  private async generateTokens(user: User) {
    const payload = { sub: user.id, email: user.email, role: user.role };

    const accessToken = this.jwtService.sign(payload, {
      secret: jwtSecret(),
      expiresIn: accessTokenTtl() as any,
    });

    // Signed with a different key, so a refresh token cannot be replayed as an
    // access token by JwtStrategy.
    const refreshToken = this.jwtService.sign(payload, {
      secret: jwtRefreshSecret(),
      expiresIn: refreshTokenTtl() as any,
    });

    // Store hashed refresh token
    const refreshHash = await bcrypt.hash(refreshToken, 10);
    await this.userRepo.update(user.id, { refreshTokenHash: refreshHash });

    return { accessToken, refreshToken };
  }

  private sanitizeUser(user: User) {
    const { passwordHash, refreshTokenHash, ...sanitized } = user;
    return sanitized;
  }
}
