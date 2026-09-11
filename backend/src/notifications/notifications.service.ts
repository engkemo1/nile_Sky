import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  Notification,
  NotificationType,
} from './entities/notification.entity';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(Notification)
    private readonly notificationRepo: Repository<Notification>,
  ) {}

  async getUserNotifications(userId: string): Promise<Notification[]> {
    return this.notificationRepo.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: 50,
    });
  }

  async markAsRead(userId: string, id: string): Promise<Notification> {
    const notification = await this.notificationRepo.findOne({
      where: { id, userId },
    });
    if (!notification) {
      throw new NotFoundException('Notification not found');
    }
    notification.isRead = true;
    return this.notificationRepo.save(notification);
  }

  async markAllAsRead(userId: string): Promise<{ updated: number }> {
    const result = await this.notificationRepo.update(
      { userId, isRead: false },
      { isRead: true },
    );
    return { updated: result.affected || 0 };
  }

  async create(dto: {
    userId: string;
    titleEn: string;
    titleAr?: string;
    bodyEn: string;
    bodyAr?: string;
    type: NotificationType;
    data?: any;
    scheduledAt?: Date;
  }): Promise<Notification> {
    const notification = this.notificationRepo.create({
      ...dto,
      sentAt: dto.scheduledAt ? null : new Date(),
    });
    return this.notificationRepo.save(notification);
  }

  async sendBookingConfirmation(userId: string, bookingRef: string, flightDate: string) {
    return this.create({
      userId,
      titleEn: '🎈 Booking Confirmed!',
      titleAr: '🎈 تم تأكيد حجز رحلتك!',
      bodyEn: `Your Luxor hot air balloon flight (${bookingRef}) on ${flightDate} has been confirmed. View your digital boarding pass now.`,
      bodyAr: `تم تأكيد حجز رحلة البالون الخاصة بك (${bookingRef}) بتاريخ ${flightDate}. يمكنك عرض بطاقة الصعود الآن.`,
      type: NotificationType.BOOKING_CONFIRM,
      data: { bookingRef, flightDate },
    });
  }

  async sendPickupReminder(userId: string, bookingRef: string, pickupTime: string, hotel: string) {
    return this.create({
      userId,
      titleEn: '🚐 Driver Pickup Reminder',
      titleAr: '🚐 تذكير موعد التوصيل',
      bodyEn: `Your driver will arrive at ${hotel} at approximately ${pickupTime}. Please wait at the hotel lobby.`,
      bodyAr: `سيصل السائق إلى ${hotel} في تمام الساعة ${pickupTime} تقريبًا. يرجى الانتظار في بهو الفندق.`,
      type: NotificationType.PICKUP,
      data: { bookingRef, pickupTime, hotel },
    });
  }
}
