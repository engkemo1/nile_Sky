import { Injectable } from '@nestjs/common';

@Injectable()
export class I18nService {
  private readonly translations: Record<string, Record<string, string>> = {
    en: {
      appName: 'NileSky',
      tagline: 'Experience Luxor from the Sky',
      sunriseFlight: 'Sunrise Flight',
      standardPackage: 'Standard Sunrise Ride',
      premiumPackage: 'Premium Sunrise Experience',
      privatePackage: 'Private VIP Flight',
      weatherFavorable: 'Weather conditions optimal for flight',
      weatherUncertain: 'Weather conditions under assessment',
      weatherUnfavorable: 'Flights cancelled due to wind speed',
      pickupNotice: 'Hotel pickup starts 2 hours before sunrise',
      boardingPass: 'Digital Boarding Pass',
      bookNow: 'Book Now',
      checkIn: 'Check In',
    },
    ar: {
      appName: 'نايل سكاي',
      tagline: 'عش سحر الأقصر من السماء',
      sunriseFlight: 'رحلة شروق الشمس',
      standardPackage: 'رحلة الشروق الأساسية',
      premiumPackage: 'تجربة الشروق المميزة',
      privatePackage: 'رحلة خاصة VIP',
      weatherFavorable: 'الظروف الجوية مثالية ومناسبة للطيران',
      weatherUncertain: 'الطقس قيد التقييم من هيئة الطيران المدني',
      weatherUnfavorable: 'تم تعليق الرحلات بسبب سرعة الرياح',
      pickupNotice: 'تبدأ انتقالات الفنادق قبل شروق الشمس بساعتين',
      boardingPass: 'بطاقة الصعود الرقمية',
      bookNow: 'احجز الآن',
      checkIn: 'تسجيل الوصول',
    },
    de: {
      appName: 'NileSky',
      tagline: 'Erleben Sie Luxor aus der Luft',
      sunriseFlight: 'Sonnenaufgangsflug',
      standardPackage: 'Standard-Sonnenaufgangsflug',
      premiumPackage: 'Premium-Sonnenaufgangs-Erlebnis',
      privatePackage: 'Privater VIP-Flug',
      weatherFavorable: 'Wetterbedingungen optimal für den Flug',
      weatherUncertain: 'Wetterbedingungen werden geprüft',
      weatherUnfavorable: 'Flüge wegen Windgeschwindigkeit abgesagt',
      pickupNotice: 'Hotelabholung beginnt 2 Stunden vor Sonnenaufgang',
      boardingPass: 'Digitaler Boarding-Pass',
      bookNow: 'Jetzt buchen',
      checkIn: 'Check-in',
    },
    fr: {
      appName: 'NileSky',
      tagline: 'Découvrez Louxor depuis le ciel',
      sunriseFlight: 'Vol au lever du soleil',
      standardPackage: 'Vol Standard au lever du soleil',
      premiumPackage: 'Expérience Premium au lever du soleil',
      privatePackage: 'Vol VIP Privé',
      weatherFavorable: 'Conditions météorologiques optimales pour le vol',
      weatherUncertain: 'Conditions météorologiques en cours d’évaluation',
      weatherUnfavorable: 'Vols annulés en raison de la vitesse du vent',
      pickupNotice: 'La prise en charge débute 2 heures avant le lever du soleil',
      boardingPass: 'Carte d’embarquement numérique',
      bookNow: 'Réserver',
      checkIn: 'Enregistrement',
    },
    es: {
      appName: 'NileSky',
      tagline: 'Experimente Lúxor desde el cielo',
      sunriseFlight: 'Vuelo de amanecer',
      standardPackage: 'Paseo estándar al amanecer',
      premiumPackage: 'Experiencia prémium al amanecer',
      privatePackage: 'Vuelo VIP privado',
      weatherFavorable: 'Condiciones climáticas óptimas para volar',
      weatherUncertain: 'Condiciones climáticas en evaluación',
      weatherUnfavorable: 'Vuelos cancelados por velocidad del viento',
      pickupNotice: 'La recogida comienza 2 horas antes del amanecer',
      boardingPass: 'Tarjeta de embarque digital',
      bookNow: 'Reservar ahora',
      checkIn: 'Registrarse',
    },
  };

  getTranslations(lang: string = 'en') {
    const code = lang.toLowerCase();
    const selected = this.translations[code] ? code : 'en';
    return {
      lang: selected,
      strings: this.translations[selected],
    };
  }
}
