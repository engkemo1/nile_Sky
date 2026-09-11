import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Flight, FlightStatus, WeatherStatus } from './entities/flight.entity';
import { FlightTemplate } from './entities/flight-template.entity';
import { Package } from '../packages/entities/package.entity';
import { CreateFlightDto, UpdateFlightDto, SearchFlightsDto } from './dto/flight.dto';

@Injectable()
export class FlightsService {
  constructor(
    @InjectRepository(Flight)
    private readonly flightRepo: Repository<Flight>,
    @InjectRepository(FlightTemplate)
    private readonly templateRepo: Repository<FlightTemplate>,
    @InjectRepository(Package)
    private readonly packageRepo: Repository<Package>,
  ) {}

  async search(dto: SearchFlightsDto) {
    const query = this.flightRepo.createQueryBuilder('flight')
      .leftJoinAndSelect('flight.operator', 'operator')
      .leftJoinAndSelect('flight.package', 'package')
      .leftJoinAndSelect('flight.balloon', 'balloon')
      .leftJoinAndSelect('flight.pilot', 'pilot')
      .where('flight.status = :status', { status: FlightStatus.SCHEDULED });

    if (dto.date) {
      query.andWhere('flight.flightDate = :date', { date: dto.date });
    }

    if (dto.operatorId) {
      query.andWhere('flight.operatorId = :operatorId', { operatorId: dto.operatorId });
    }

    if (dto.packageType) {
      query.andWhere('package.type = :packageType', { packageType: dto.packageType });
    }

    if (dto.guests) {
      query.andWhere('(flight.capacity - flight.bookedCount) >= :guests', { guests: dto.guests });
    }

    // Sorting
    const sortOrder = dto.sortOrder || 'ASC';
    if (dto.sortBy === 'price') {
      query.orderBy('flight.priceEgp', sortOrder);
    } else if (dto.sortBy === 'rating') {
      query.orderBy('operator.rating', sortOrder === 'ASC' ? 'DESC' : 'ASC');
    } else {
      query.orderBy('flight.departureTime', 'ASC').addOrderBy('flight.priceEgp', 'ASC');
    }

    const flights = await query.getMany();

    // Map and enrich with remaining seats & badges
    return flights.map((flight) => {
      const remainingSeats = flight.capacity - flight.bookedCount;
      let badge: string | null = null;
      if (flight.package?.type === 'standard' && Number(flight.priceEgp) <= 1600) {
        badge = 'Best Value';
      } else if (flight.package?.type === 'premium') {
        badge = 'Best for Couples';
      } else if (Number(flight.operator?.rating) >= 4.9) {
        badge = 'Highest Rated';
      }

      return {
        ...flight,
        remainingSeats,
        badge,
      };
    });
  }

  async findOne(id: string) {
    const flight = await this.flightRepo.findOne({
      where: { id },
      relations: {
        operator: true,
        package: true,
        balloon: true,
        pilot: true,
      },
    });
    if (!flight) {
      throw new NotFoundException(`Flight with ID ${id} not found`);
    }
    return {
      ...flight,
      remainingSeats: flight.capacity - flight.bookedCount,
    };
  }

  async create(dto: CreateFlightDto) {
    const flight = this.flightRepo.create(dto);
    return this.flightRepo.save(flight);
  }

  async update(id: string, dto: UpdateFlightDto) {
    const flight = await this.findOne(id);
    Object.assign(flight, dto);
    return this.flightRepo.save(flight);
  }

  async updateStatus(id: string, status: FlightStatus, cancellationReason?: string) {
    const flight = await this.findOne(id);
    flight.status = status;
    if (status === FlightStatus.CANCELLED) {
      flight.cancellationReason = cancellationReason || 'Weather conditions or operational reasons';
    }
    return this.flightRepo.save(flight);
  }

  async updateWeatherStatus(id: string, weatherStatus: WeatherStatus) {
    const flight = await this.findOne(id);
    flight.weatherStatus = weatherStatus;
    return this.flightRepo.save(flight);
  }

  async generateFlightsFromTemplates(targetDate: string) {
    const templates = await this.templateRepo.find({
      where: { isActive: true },
      relations: { package: true, operator: true },
    });

    const createdFlights: Flight[] = [];
    const dateObj = new Date(targetDate);
    const dayOfWeek = dateObj.toLocaleDateString('en-US', { weekday: 'long' }).toLowerCase();

    for (const tmpl of templates) {
      // Check recurrence rules
      let shouldGenerate = false;
      if (tmpl.recurrence === 'daily') {
        shouldGenerate = true;
      } else if (tmpl.recurrence === 'weekdays' && !['saturday', 'sunday'].includes(dayOfWeek)) {
        shouldGenerate = true;
      } else if (tmpl.recurrence === 'weekends' && ['saturday', 'sunday'].includes(dayOfWeek)) {
        shouldGenerate = true;
      } else if (tmpl.recurrence === 'custom' && tmpl.customDays?.includes(dayOfWeek)) {
        shouldGenerate = true;
      }

      if (!shouldGenerate) continue;

      const randomSuffix = Math.floor(1000 + Math.random() * 9000);
      const flightNumber = `FL-${dateObj.toISOString().slice(0, 10).replace(/-/g, '')}-${randomSuffix}`;

      // Check if flight already generated for this template & date
      const existing = await this.flightRepo.findOne({
        where: {
          flightTemplateId: tmpl.id,
          flightDate: dateObj,
        },
      });

      if (!existing) {
        const flight = this.flightRepo.create({
          flightNumber,
          flightTemplateId: tmpl.id,
          operatorId: tmpl.operatorId,
          packageId: tmpl.packageId,
          flightDate: dateObj,
          departureTime: tmpl.departureTime,
          capacity: tmpl.capacity,
          priceEgp: tmpl.package?.basePriceEgp || 1500,
          status: FlightStatus.SCHEDULED,
          weatherStatus: WeatherStatus.FAVORABLE,
        });
        const saved = await this.flightRepo.save(flight);
        createdFlights.push(saved);
      }
    }

    return {
      message: `Generated ${createdFlights.length} flights for ${targetDate}`,
      flights: createdFlights,
    };
  }

  async remove(id: string) {
    const flight = await this.findOne(id);
    return this.flightRepo.remove(flight as unknown as Flight);
  }
}
