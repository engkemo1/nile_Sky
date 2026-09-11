import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Pilot, PilotStatus } from './entities/pilot.entity';
import { CreatePilotDto, UpdatePilotDto } from './dto/pilot.dto';

@Injectable()
export class PilotsService {
  constructor(
    @InjectRepository(Pilot)
    private readonly pilotRepo: Repository<Pilot>,
  ) {}

  async findAll(operatorId?: string, status?: PilotStatus) {
    const query = this.pilotRepo.createQueryBuilder('p')
      .leftJoinAndSelect('p.operator', 'operator');
    if (operatorId) {
      query.andWhere('p.operatorId = :operatorId', { operatorId });
    }
    if (status) {
      query.andWhere('p.status = :status', { status });
    }
    return query.orderBy('p.experienceYears', 'DESC').addOrderBy('p.rating', 'DESC').getMany();
  }

  async findOne(id: string) {
    const pilot = await this.pilotRepo.findOne({
      where: { id },
      relations: { operator: true },
    });
    if (!pilot) {
      throw new NotFoundException(`Pilot with ID ${id} not found`);
    }
    return pilot;
  }

  async create(dto: CreatePilotDto) {
    const pilot = this.pilotRepo.create(dto);
    return this.pilotRepo.save(pilot);
  }

  async update(id: string, dto: UpdatePilotDto) {
    const pilot = await this.findOne(id);
    Object.assign(pilot, dto);
    return this.pilotRepo.save(pilot);
  }

  async remove(id: string) {
    const pilot = await this.findOne(id);
    return this.pilotRepo.remove(pilot);
  }
}
