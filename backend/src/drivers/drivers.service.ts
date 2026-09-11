import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Driver, DriverStatus } from './entities/driver.entity';
import { CreateDriverDto, UpdateDriverDto } from './dto/driver.dto';

@Injectable()
export class DriversService {
  constructor(
    @InjectRepository(Driver)
    private readonly driverRepo: Repository<Driver>,
  ) {}

  async findAll(operatorId?: string, status?: DriverStatus) {
    const query = this.driverRepo.createQueryBuilder('d')
      .leftJoinAndSelect('d.operator', 'operator');
    if (operatorId) {
      query.andWhere('d.operatorId = :operatorId', { operatorId });
    }
    if (status) {
      query.andWhere('d.status = :status', { status });
    }
    return query.orderBy('d.name', 'ASC').getMany();
  }

  async findOne(id: string) {
    const driver = await this.driverRepo.findOne({
      where: { id },
      relations: { operator: true },
    });
    if (!driver) {
      throw new NotFoundException(`Driver with ID ${id} not found`);
    }
    return driver;
  }

  async create(dto: CreateDriverDto) {
    const driver = this.driverRepo.create(dto);
    return this.driverRepo.save(driver);
  }

  async update(id: string, dto: UpdateDriverDto) {
    const driver = await this.findOne(id);
    Object.assign(driver, dto);
    return this.driverRepo.save(driver);
  }

  async updateLocation(id: string, lat: number, lng: number) {
    const driver = await this.findOne(id);
    driver.currentLat = lat;
    driver.currentLng = lng;
    return this.driverRepo.save(driver);
  }

  async remove(id: string) {
    const driver = await this.findOne(id);
    return this.driverRepo.remove(driver);
  }
}
