import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Operator, OperatorStatus } from './entities/operator.entity';
import { CreateOperatorDto, UpdateOperatorDto } from './dto/operator.dto';

@Injectable()
export class OperatorsService {
  constructor(
    @InjectRepository(Operator)
    private readonly operatorRepo: Repository<Operator>,
  ) {}

  async findAll(status?: OperatorStatus) {
    const query = this.operatorRepo.createQueryBuilder('operator');
    if (status) {
      query.where('operator.status = :status', { status });
    }
    return query.orderBy('operator.rating', 'DESC').addOrderBy('operator.totalReviews', 'DESC').getMany();
  }

  async findOne(id: string) {
    const operator = await this.operatorRepo.findOne({ where: { id } });
    if (!operator) {
      throw new NotFoundException(`Operator with ID ${id} not found`);
    }
    return operator;
  }

  async create(dto: CreateOperatorDto, ownerUserId?: string) {
    const operator = this.operatorRepo.create({
      ...dto,
      ownerUserId,
      status: OperatorStatus.VERIFIED, // auto-verified for MVP seed or admin creation
    });
    return this.operatorRepo.save(operator);
  }

  async update(id: string, dto: UpdateOperatorDto) {
    const operator = await this.findOne(id);
    Object.assign(operator, dto);
    return this.operatorRepo.save(operator);
  }

  async verify(id: string) {
    const operator = await this.findOne(id);
    operator.status = OperatorStatus.VERIFIED;
    return this.operatorRepo.save(operator);
  }

  async remove(id: string) {
    const operator = await this.findOne(id);
    return this.operatorRepo.remove(operator);
  }
}
