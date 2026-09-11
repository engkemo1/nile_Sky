import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Coupon, CouponType } from './entities/coupon.entity';

@Injectable()
export class CouponsService {
  constructor(
    @InjectRepository(Coupon)
    private readonly couponRepo: Repository<Coupon>,
  ) {}

  async findAll() {
    return this.couponRepo.find({ relations: { operator: true }, order: { createdAt: 'DESC' } });
  }

  async validate(code: string, operatorId?: string) {
    const coupon = await this.couponRepo.findOne({
      where: { code: code.toUpperCase(), isActive: true },
    });

    if (!coupon) {
      throw new NotFoundException('Invalid coupon code');
    }

    const now = new Date();
    if (now < new Date(coupon.validFrom) || now > new Date(coupon.validTo)) {
      throw new BadRequestException('Coupon has expired');
    }

    if (coupon.maxUses && coupon.usedCount >= coupon.maxUses) {
      throw new BadRequestException('Coupon usage limit reached');
    }

    if (coupon.operatorId && operatorId && coupon.operatorId !== operatorId) {
      throw new BadRequestException('Coupon not applicable to this operator');
    }

    return coupon;
  }

  async create(data: Partial<Coupon>) {
    const coupon = this.couponRepo.create({
      ...data,
      code: data.code?.toUpperCase(),
    });
    return this.couponRepo.save(coupon);
  }

  async remove(id: string) {
    const coupon = await this.couponRepo.findOne({ where: { id } });
    if (!coupon) throw new NotFoundException('Coupon not found');
    return this.couponRepo.remove(coupon);
  }
}
