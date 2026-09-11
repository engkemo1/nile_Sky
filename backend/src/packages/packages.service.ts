import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Package } from './entities/package.entity';
import { CreatePackageDto, UpdatePackageDto } from './dto/package.dto';

@Injectable()
export class PackagesService {
  constructor(
    @InjectRepository(Package)
    private readonly packageRepo: Repository<Package>,
  ) {}

  async findAll(operatorId?: string) {
    const query = this.packageRepo.createQueryBuilder('pkg')
      .leftJoinAndSelect('pkg.operator', 'operator')
      .where('pkg.isActive = :isActive', { isActive: true });
    if (operatorId) {
      query.andWhere('pkg.operatorId = :operatorId', { operatorId });
    }
    return query.orderBy('pkg.sortOrder', 'ASC').addOrderBy('pkg.basePriceEgp', 'ASC').getMany();
  }

  async findOne(id: string) {
    const pkg = await this.packageRepo.findOne({
      where: { id },
      relations: { operator: true },
    });
    if (!pkg) {
      throw new NotFoundException(`Package with ID ${id} not found`);
    }
    return pkg;
  }

  async create(dto: CreatePackageDto) {
    const pkg = this.packageRepo.create(dto);
    return this.packageRepo.save(pkg);
  }

  async update(id: string, dto: UpdatePackageDto) {
    const pkg = await this.findOne(id);
    Object.assign(pkg, dto);
    return this.packageRepo.save(pkg);
  }

  async remove(id: string) {
    const pkg = await this.findOne(id);
    pkg.isActive = false;
    return this.packageRepo.save(pkg);
  }
}
