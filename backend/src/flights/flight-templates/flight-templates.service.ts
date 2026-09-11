import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { FlightTemplate } from '../entities/flight-template.entity';
import { CreateFlightTemplateDto, UpdateFlightTemplateDto } from '../dto/flight-template.dto';

@Injectable()
export class FlightTemplatesService {
  constructor(
    @InjectRepository(FlightTemplate)
    private readonly templateRepo: Repository<FlightTemplate>,
  ) {}

  async findAll(operatorId?: string) {
    const query = this.templateRepo.createQueryBuilder('ft')
      .leftJoinAndSelect('ft.operator', 'operator')
      .leftJoinAndSelect('ft.package', 'package');
    if (operatorId) {
      query.andWhere('ft.operatorId = :operatorId', { operatorId });
    }
    return query.getMany();
  }

  async findOne(id: string) {
    const template = await this.templateRepo.findOne({
      where: { id },
      relations: { operator: true, package: true },
    });
    if (!template) {
      throw new NotFoundException(`Flight template with ID ${id} not found`);
    }
    return template;
  }

  async create(dto: CreateFlightTemplateDto) {
    const template = this.templateRepo.create(dto);
    return this.templateRepo.save(template);
  }

  async update(id: string, dto: UpdateFlightTemplateDto) {
    const template = await this.findOne(id);
    Object.assign(template, dto);
    return this.templateRepo.save(template);
  }

  async remove(id: string) {
    const template = await this.findOne(id);
    return this.templateRepo.remove(template);
  }
}
