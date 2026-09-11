import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Balloon, BalloonStatus } from './entities/balloon.entity';
import { CreateBalloonDto, UpdateBalloonDto } from './dto/balloon.dto';

@Injectable()
export class BalloonsService {
  constructor(
    @InjectRepository(Balloon)
    private readonly balloonRepo: Repository<Balloon>,
  ) {}

  async findAll(operatorId?: string, status?: BalloonStatus) {
    const query = this.balloonRepo.createQueryBuilder('b')
      .leftJoinAndSelect('b.operator', 'operator');
    if (operatorId) {
      query.andWhere('b.operatorId = :operatorId', { operatorId });
    }
    if (status) {
      query.andWhere('b.status = :status', { status });
    }
    return query.orderBy('b.registrationCode', 'ASC').getMany();
  }

  async findOne(id: string) {
    const balloon = await this.balloonRepo.findOne({
      where: { id },
      relations: { operator: true },
    });
    if (!balloon) {
      throw new NotFoundException(`Balloon with ID ${id} not found`);
    }
    return balloon;
  }

  async create(dto: CreateBalloonDto) {
    const balloon = this.balloonRepo.create(dto);
    return this.balloonRepo.save(balloon);
  }

  async update(id: string, dto: UpdateBalloonDto) {
    const balloon = await this.findOne(id);
    Object.assign(balloon, dto);
    return this.balloonRepo.save(balloon);
  }

  async remove(id: string) {
    const balloon = await this.findOne(id);
    return this.balloonRepo.remove(balloon);
  }
}
