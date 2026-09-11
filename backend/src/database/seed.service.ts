import { Injectable, OnApplicationBootstrap } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User, UserRole } from '../users/entities/user.entity';
import { Operator, OperatorStatus } from '../operators/entities/operator.entity';
import { Package, PackageType } from '../packages/entities/package.entity';
import { Balloon, BalloonStatus } from '../balloons/entities/balloon.entity';
import { Pilot, PilotStatus } from '../pilots/entities/pilot.entity';
import { Driver, DriverStatus } from '../drivers/entities/driver.entity';
import { FlightTemplate, RecurrenceType } from '../flights/entities/flight-template.entity';
import { Flight, FlightStatus, WeatherStatus } from '../flights/entities/flight.entity';
import { Coupon, CouponType } from '../coupons/entities/coupon.entity';

@Injectable()
export class SeedService implements OnApplicationBootstrap {
  constructor(
    @InjectRepository(User) private readonly userRepo: Repository<User>,
    @InjectRepository(Operator) private readonly operatorRepo: Repository<Operator>,
    @InjectRepository(Package) private readonly packageRepo: Repository<Package>,
    @InjectRepository(Balloon) private readonly balloonRepo: Repository<Balloon>,
    @InjectRepository(Pilot) private readonly pilotRepo: Repository<Pilot>,
    @InjectRepository(Driver) private readonly driverRepo: Repository<Driver>,
    @InjectRepository(FlightTemplate) private readonly templateRepo: Repository<FlightTemplate>,
    @InjectRepository(Flight) private readonly flightRepo: Repository<Flight>,
    @InjectRepository(Coupon) private readonly couponRepo: Repository<Coupon>,
  ) {}

  async onApplicationBootstrap() {
    await this.seedData();
  }

  async seedData() {
    const usersCount = await this.userRepo.count();
    if (usersCount > 0) return; // already seeded

    console.log('🌱 Seeding initial NileSky data for Luxor...');

    // 1. Users
    // Seed password comes from the environment so it is never committed to git.
    // Set SEED_PASSWORD in the Render dashboard. Falls back only outside production.
    const seedPassword = process.env.SEED_PASSWORD;
    if (!seedPassword && process.env.NODE_ENV === 'production') {
      throw new Error(
        'SEED_PASSWORD must be set in production. Refusing to seed accounts with a default password.',
      );
    }
    const passwordHash = await bcrypt.hash(seedPassword || 'DevOnly@123456', 10);
    const adminUser = await this.userRepo.save(
      this.userRepo.create({
        name: 'NileSky Platform Admin',
        email: 'admin@nilesky.com',
        passwordHash,
        role: UserRole.PLATFORM_ADMIN,
        isVerified: true,
      }),
    );

    const customerUser = await this.userRepo.save(
      this.userRepo.create({
        name: 'John Smith',
        email: 'john@gmail.com',
        phone: '+201012345678',
        passwordHash,
        role: UserRole.CUSTOMER,
        isVerified: true,
        languagePref: 'en',
        currencyPref: 'USD',
      }),
    );

    // 2. Operators with photo galleries & promo videos
    const kingTut = await this.operatorRepo.save(
      this.operatorRepo.create({
        nameEn: 'King Tut Balloons',
        nameAr: 'كنج تت بالونز',
        descriptionEn: 'Operating since 2005. One of Luxor’s most experienced hot air balloon operators offering sunrise panoramic flights over the Valley of the Kings.',
        descriptionAr: 'من أقدم وأعرق شركات البالون الطائر في الأقصر، رحلات شروق الشمس فوق وادي الملوك ومعابد الفراعنة.',
        logoUrl: 'https://images.unsplash.com/photo-1507608869274-d3177c8bb4c7?w=150',
        coverPhotoUrl: 'https://images.unsplash.com/photo-1507608869274-d3177c8bb4c7?w=800',
        photos: [
          'https://images.unsplash.com/photo-1507608869274-d3177c8bb4c7?w=800',
          'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800',
          'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=sample_kingtut',
        phone: '01281824995',
        whatsapp: '01281824995',
        email: 'info@kingtutballoons.com',
        website: 'https://kingtutballoons.com',
        rating: 4.9,
        totalReviews: 312,
        totalFlights: 12450,
        status: OperatorStatus.VERIFIED,
        address: 'West Bank, Luxor, Egypt',
        latitude: 25.7201,
        longitude: 32.6105,
        commissionRate: 10.0,
      }),
    );

    const sindbad = await this.operatorRepo.save(
      this.operatorRepo.create({
        nameEn: 'Sindbad Hot Air Balloons',
        nameAr: 'سندباد بالونز',
        descriptionEn: 'Luxury balloon rides with hotel pickup and traditional Egyptian breakfast upon landing.',
        descriptionAr: 'رحلات بالون مميزة تشمل الانتقالات وإفطار مصري تقليدي بعد الهبوط.',
        logoUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=150',
        coverPhotoUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800',
        photos: [
          'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800',
          'https://images.unsplash.com/photo-1507608869274-d3177c8bb4c7?w=800',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=sample_sindbad',
        phone: '01005385533',
        whatsapp: '01005385533',
        email: 'info@sindbadballoons.com',
        rating: 4.9,
        totalReviews: 287,
        totalFlights: 9800,
        status: OperatorStatus.VERIFIED,
        address: 'West Bank, Luxor, Egypt',
        latitude: 25.7215,
        longitude: 32.612,
        commissionRate: 10.0,
      }),
    );

    const skyScape = await this.operatorRepo.save(
      this.operatorRepo.create({
        nameEn: 'SkyScape Hot Air Balloon',
        nameAr: 'سكاي سكيب بالون',
        descriptionEn: 'Specialized in VIP and private couple/family balloon flights over Luxor monuments.',
        descriptionAr: 'متخصصون في الرحلات الخاصة والـ VIP للعائلات والأزواج في الأقصر.',
        logoUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=150',
        coverPhotoUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800',
        photos: [
          'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800',
        ],
        phone: '01091999526',
        rating: 5.0,
        totalReviews: 156,
        totalFlights: 4200,
        status: OperatorStatus.VERIFIED,
        address: 'West Bank, Luxor, Egypt',
        latitude: 25.723,
        longitude: 32.614,
        commissionRate: 12.0,
      }),
    );

    // 3. Packages / Trip Experiences
    const ktStandard = await this.packageRepo.save(
      this.packageRepo.create({
        operatorId: kingTut.id,
        nameEn: 'Sunrise Standard Flight',
        nameAr: 'رحلة شروق الشمس الأساسية',
        descriptionEn: '45-minute flight across Luxor West Bank with hotel pickup and landing certificate.',
        type: PackageType.STANDARD,
        durationMinutes: 45,
        hasPickup: true,
        hasBreakfast: false,
        isPrivate: false,
        basePriceEgp: 1500,
        priceUsd: 30,
        priceEur: 28,
        priceGbp: 24,
        coverPhotoUrl: 'https://images.unsplash.com/photo-1507608869274-d3177c8bb4c7?w=800',
        photos: [
          'https://images.unsplash.com/photo-1507608869274-d3177c8bb4c7?w=800',
          'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=sample_standard',
      }),
    );

    const sbPremium = await this.packageRepo.save(
      this.packageRepo.create({
        operatorId: sindbad.id,
        nameEn: 'Sunrise Premium Experience',
        nameAr: 'تجربة شروق الشمس المميزة',
        descriptionEn: '60-minute flight with hotel pickup, Nile crossing, and full breakfast buffet.',
        type: PackageType.PREMIUM,
        durationMinutes: 60,
        hasPickup: true,
        hasBreakfast: true,
        isPrivate: false,
        basePriceEgp: 2200,
        priceUsd: 44,
        priceEur: 41,
        priceGbp: 35,
        coverPhotoUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800',
        photos: [
          'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=sample_premium',
      }),
    );

    const ssPrivate = await this.packageRepo.save(
      this.packageRepo.create({
        operatorId: skyScape.id,
        nameEn: 'Private VIP Flight for Couples/Groups',
        nameAr: 'رحلة VIP خاصة للأزواج والمجموعات',
        descriptionEn: '90-minute exclusive balloon basket for up to 4 guests with champagne breakfast.',
        type: PackageType.PRIVATE,
        durationMinutes: 90,
        hasPickup: true,
        hasBreakfast: true,
        isPrivate: true,
        maxGuestsIfPrivate: 4,
        basePriceEgp: 9000,
        priceUsd: 180,
        priceEur: 170,
        priceGbp: 145,
        coverPhotoUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800',
        photos: [
          'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=sample_private',
      }),
    );

    // 4. Balloons
    const balloon1 = await this.balloonRepo.save(
      this.balloonRepo.create({
        operatorId: kingTut.id,
        registrationCode: 'KT-101',
        name: 'Horus Golden Sun',
        capacity: 16,
        status: BalloonStatus.AVAILABLE,
        photoUrl: 'https://images.unsplash.com/photo-1507608869274-d3177c8bb4c7?w=600',
        photos: [
          'https://images.unsplash.com/photo-1507608869274-d3177c8bb4c7?w=800',
          'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=sample_balloon1',
      }),
    );

    const balloon2 = await this.balloonRepo.save(
      this.balloonRepo.create({
        operatorId: sindbad.id,
        registrationCode: 'SB-201',
        name: 'Sindbad Royal Blue',
        capacity: 20,
        status: BalloonStatus.AVAILABLE,
        photoUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600',
        photos: [
          'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800',
        ],
      }),
    );

    // 5. Pilots
    const pilot1 = await this.pilotRepo.save(
      this.pilotRepo.create({
        operatorId: kingTut.id,
        nameEn: 'Capt. Ahmed Hassan',
        nameAr: 'كابتن أحمد حسن',
        photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
        licenseNumber: 'EGY-CA-8921',
        totalFlights: 1248,
        experienceYears: 12,
        rating: 4.9,
        status: PilotStatus.ACTIVE,
      }),
    );

    const pilot2 = await this.pilotRepo.save(
      this.pilotRepo.create({
        operatorId: sindbad.id,
        nameEn: 'Capt. Mohamed Khalil',
        nameAr: 'كابتن محمد خليل',
        photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
        licenseNumber: 'EGY-CA-6712',
        totalFlights: 892,
        experienceYears: 9,
        rating: 4.8,
        status: PilotStatus.ACTIVE,
      }),
    );

    // 6. Drivers
    await this.driverRepo.save(
      this.driverRepo.create({
        operatorId: kingTut.id,
        name: 'Ahmed Mahmoud',
        phone: '01012345678',
        carModel: 'Toyota HiAce (White Air-Conditioned Van)',
        carPlate: 'ل م ط ١٢٣٤',
        status: DriverStatus.AVAILABLE,
        currentLat: 25.6872,
        currentLng: 32.6396,
      }),
    );

    // 7. Flight Templates
    await this.templateRepo.save([
      this.templateRepo.create({
        operatorId: kingTut.id,
        packageId: ktStandard.id,
        departureTime: '06:15:00',
        capacity: 16,
        recurrence: RecurrenceType.DAILY,
      }),
      this.templateRepo.create({
        operatorId: sindbad.id,
        packageId: sbPremium.id,
        departureTime: '06:15:00',
        capacity: 20,
        recurrence: RecurrenceType.DAILY,
      }),
      this.templateRepo.create({
        operatorId: skyScape.id,
        packageId: ssPrivate.id,
        departureTime: '06:00:00',
        capacity: 4,
        recurrence: RecurrenceType.DAILY,
      }),
    ]);

    // 8. Generate Active Flights for Today and Tomorrow
    const today = new Date();
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    for (const date of [today, tomorrow]) {
      const dateStr = date.toISOString().slice(0, 10);

      await this.flightRepo.save([
        this.flightRepo.create({
          flightNumber: `FL-${dateStr.replace(/-/g, '')}-101`,
          operatorId: kingTut.id,
          packageId: ktStandard.id,
          balloonId: balloon1.id,
          pilotId: pilot1.id,
          flightDate: date,
          departureTime: '06:15:00',
          capacity: 16,
          bookedCount: 8,
          priceEgp: 1500,
          status: FlightStatus.SCHEDULED,
          weatherStatus: WeatherStatus.FAVORABLE,
          photos: [
            'https://images.unsplash.com/photo-1507608869274-d3177c8bb4c7?w=800',
          ],
        }),
        this.flightRepo.create({
          flightNumber: `FL-${dateStr.replace(/-/g, '')}-202`,
          operatorId: sindbad.id,
          packageId: sbPremium.id,
          balloonId: balloon2.id,
          pilotId: pilot2.id,
          flightDate: date,
          departureTime: '06:15:00',
          capacity: 20,
          bookedCount: 16,
          priceEgp: 2200,
          status: FlightStatus.SCHEDULED,
          weatherStatus: WeatherStatus.FAVORABLE,
          photos: [
            'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800',
          ],
        }),
        this.flightRepo.create({
          flightNumber: `FL-${dateStr.replace(/-/g, '')}-303`,
          operatorId: skyScape.id,
          packageId: ssPrivate.id,
          flightDate: date,
          departureTime: '06:00:00',
          capacity: 4,
          bookedCount: 0,
          priceEgp: 9000,
          status: FlightStatus.SCHEDULED,
          weatherStatus: WeatherStatus.FAVORABLE,
        }),
      ]);
    }

    // 9. Coupons
    const nextYear = new Date();
    nextYear.setFullYear(nextYear.getFullYear() + 1);

    await this.couponRepo.save([
      this.couponRepo.create({
        code: 'WELCOME10',
        type: CouponType.PERCENTAGE,
        value: 10,
        maxDiscountEgp: 500,
        validFrom: today,
        validTo: nextYear,
        maxUses: 1000,
      }),
      this.couponRepo.create({
        code: 'LUXOR200',
        type: CouponType.FIXED,
        value: 200,
        validFrom: today,
        validTo: nextYear,
        maxUses: 500,
      }),
    ]);

    console.log('✅ NileSky database successfully seeded with realistic Luxor balloon data!');
  }
}
