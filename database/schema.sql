-- ============================================
-- NileSky Database Schema
-- Luxor Balloon Booking MVP
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- ENUMS
-- ============================================

CREATE TYPE user_role AS ENUM ('customer', 'operator_admin', 'platform_admin');
CREATE TYPE operator_status AS ENUM ('pending', 'verified', 'suspended');
CREATE TYPE balloon_status AS ENUM ('available', 'in_flight', 'maintenance', 'retired');
CREATE TYPE pilot_status AS ENUM ('active', 'on_leave', 'inactive');
CREATE TYPE driver_status AS ENUM ('available', 'on_trip', 'off_duty');
CREATE TYPE package_type AS ENUM ('standard', 'premium', 'private');
CREATE TYPE recurrence_type AS ENUM ('daily', 'weekdays', 'weekends', 'custom');
CREATE TYPE flight_status AS ENUM ('scheduled', 'boarding', 'in_flight', 'landed', 'completed', 'cancelled');
CREATE TYPE weather_status AS ENUM ('favorable', 'uncertain', 'unfavorable');
CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'checked_in', 'completed', 'cancelled', 'no_show');
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'refunded', 'partial_refund');
CREATE TYPE payment_method AS ENUM ('card', 'wallet', 'cash', 'bank_transfer');
CREATE TYPE payment_gateway AS ENUM ('paymob', 'fawry', 'stripe');
CREATE TYPE transaction_status AS ENUM ('pending', 'success', 'failed', 'refunded');
CREATE TYPE coupon_type AS ENUM ('percentage', 'fixed');
CREATE TYPE notification_type AS ENUM (
  'booking_confirm', 'reminder', 'pickup', 'flight_update',
  'weather', 'review_request', 'promo'
);

-- ============================================
-- TABLES
-- ============================================

-- 1. Users
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  phone VARCHAR(20),
  password_hash VARCHAR(255),
  name VARCHAR(255) NOT NULL,
  avatar_url VARCHAR(512),
  role user_role NOT NULL DEFAULT 'customer',
  language_pref VARCHAR(5) DEFAULT 'en',
  currency_pref VARCHAR(3) DEFAULT 'EGP',
  is_verified BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  social_provider VARCHAR(20),
  social_id VARCHAR(255),
  refresh_token_hash VARCHAR(255),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_social ON users(social_provider, social_id);

-- 2. Operators
CREATE TABLE operators (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name_en VARCHAR(255) NOT NULL,
  name_ar VARCHAR(255),
  description_en TEXT,
  description_ar TEXT,
  logo_url VARCHAR(512),
  phone VARCHAR(20),
  email VARCHAR(255),
  website VARCHAR(512),
  whatsapp VARCHAR(20),
  rating DECIMAL(2,1) DEFAULT 0.0,
  total_reviews INT DEFAULT 0,
  total_flights INT DEFAULT 0,
  status operator_status NOT NULL DEFAULT 'pending',
  license_number VARCHAR(100),
  license_doc_url VARCHAR(512),
  license_expiry DATE,
  insurance_doc_url VARCHAR(512),
  insurance_expiry DATE,
  address TEXT,
  latitude DECIMAL(10, 7),
  longitude DECIMAL(10, 7),
  commission_rate DECIMAL(4,2) DEFAULT 10.00,
  owner_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_operators_status ON operators(status);
CREATE INDEX idx_operators_owner ON operators(owner_user_id);

-- 3. Balloons
CREATE TABLE balloons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  operator_id UUID NOT NULL REFERENCES operators(id) ON DELETE CASCADE,
  registration_code VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(100),
  capacity INT NOT NULL CHECK (capacity > 0),
  status balloon_status NOT NULL DEFAULT 'available',
  last_inspection DATE,
  inspection_doc_url VARCHAR(512),
  insurance_doc_url VARCHAR(512),
  insurance_expiry DATE,
  photo_url VARCHAR(512),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_balloons_operator ON balloons(operator_id);
CREATE INDEX idx_balloons_status ON balloons(status);

-- 4. Pilots
CREATE TABLE pilots (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  operator_id UUID NOT NULL REFERENCES operators(id) ON DELETE CASCADE,
  name_en VARCHAR(255) NOT NULL,
  name_ar VARCHAR(255),
  photo_url VARCHAR(512),
  license_number VARCHAR(100),
  license_expiry DATE,
  total_flights INT DEFAULT 0,
  experience_years INT DEFAULT 0,
  rating DECIMAL(2,1) DEFAULT 0.0,
  status pilot_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_pilots_operator ON pilots(operator_id);
CREATE INDEX idx_pilots_status ON pilots(status);

-- 5. Drivers
CREATE TABLE drivers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  operator_id UUID NOT NULL REFERENCES operators(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  car_model VARCHAR(100),
  car_plate VARCHAR(50),
  photo_url VARCHAR(512),
  status driver_status NOT NULL DEFAULT 'available',
  current_lat DECIMAL(10, 7),
  current_lng DECIMAL(10, 7),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_drivers_operator ON drivers(operator_id);
CREATE INDEX idx_drivers_status ON drivers(status);

-- 6. Packages
CREATE TABLE packages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  operator_id UUID NOT NULL REFERENCES operators(id) ON DELETE CASCADE,
  name_en VARCHAR(255) NOT NULL,
  name_ar VARCHAR(255),
  description_en TEXT,
  description_ar TEXT,
  type package_type NOT NULL DEFAULT 'standard',
  duration_minutes INT NOT NULL CHECK (duration_minutes > 0),
  has_pickup BOOLEAN DEFAULT TRUE,
  has_breakfast BOOLEAN DEFAULT FALSE,
  is_private BOOLEAN DEFAULT FALSE,
  max_guests_if_private INT,
  base_price_egp DECIMAL(10,2) NOT NULL CHECK (base_price_egp > 0),
  price_usd DECIMAL(10,2),
  price_eur DECIMAL(10,2),
  price_gbp DECIMAL(10,2),
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_packages_operator ON packages(operator_id);
CREATE INDEX idx_packages_type ON packages(type);
CREATE INDEX idx_packages_active ON packages(is_active);

-- 7. Flight Templates
CREATE TABLE flight_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  operator_id UUID NOT NULL REFERENCES operators(id) ON DELETE CASCADE,
  package_id UUID NOT NULL REFERENCES packages(id) ON DELETE CASCADE,
  departure_time TIME NOT NULL,
  capacity INT NOT NULL CHECK (capacity > 0),
  recurrence recurrence_type NOT NULL DEFAULT 'daily',
  custom_days JSONB, -- e.g., ["monday", "wednesday", "friday"]
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_flight_templates_operator ON flight_templates(operator_id);
CREATE INDEX idx_flight_templates_active ON flight_templates(is_active);

-- 8. Flights
CREATE TABLE flights (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  flight_number VARCHAR(20) UNIQUE NOT NULL,
  flight_template_id UUID REFERENCES flight_templates(id) ON DELETE SET NULL,
  operator_id UUID NOT NULL REFERENCES operators(id) ON DELETE CASCADE,
  package_id UUID NOT NULL REFERENCES packages(id) ON DELETE CASCADE,
  balloon_id UUID REFERENCES balloons(id) ON DELETE SET NULL,
  pilot_id UUID REFERENCES pilots(id) ON DELETE SET NULL,
  flight_date DATE NOT NULL,
  departure_time TIME NOT NULL,
  capacity INT NOT NULL CHECK (capacity > 0),
  booked_count INT DEFAULT 0 CHECK (booked_count >= 0),
  price_egp DECIMAL(10,2) NOT NULL CHECK (price_egp > 0),
  status flight_status NOT NULL DEFAULT 'scheduled',
  weather_status weather_status DEFAULT 'favorable',
  cancellation_reason TEXT,
  confirmed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT chk_booked_capacity CHECK (booked_count <= capacity)
);

CREATE INDEX idx_flights_date ON flights(flight_date);
CREATE INDEX idx_flights_operator ON flights(operator_id);
CREATE INDEX idx_flights_status ON flights(status);
CREATE INDEX idx_flights_date_status ON flights(flight_date, status);
CREATE UNIQUE INDEX idx_flights_number ON flights(flight_number);

-- 9. Bookings
CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_ref VARCHAR(20) UNIQUE NOT NULL,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  flight_id UUID NOT NULL REFERENCES flights(id) ON DELETE CASCADE,
  operator_id UUID NOT NULL REFERENCES operators(id) ON DELETE CASCADE,
  guest_count INT NOT NULL CHECK (guest_count > 0),
  total_price_egp DECIMAL(10,2) NOT NULL CHECK (total_price_egp > 0),
  commission_amount DECIMAL(10,2) DEFAULT 0,
  payment_status payment_status NOT NULL DEFAULT 'pending',
  booking_status booking_status NOT NULL DEFAULT 'pending',
  pickup_location VARCHAR(255),
  pickup_hotel_name VARCHAR(255),
  pickup_lat DECIMAL(10, 7),
  pickup_lng DECIMAL(10, 7),
  driver_id UUID REFERENCES drivers(id) ON DELETE SET NULL,
  pickup_time TIME,
  qr_code_data TEXT,
  special_requests TEXT,
  guest_details JSONB, -- [{ name, phone, email }]
  coupon_id UUID REFERENCES coupons(id) ON DELETE SET NULL,
  discount_amount DECIMAL(10,2) DEFAULT 0,
  cancellation_reason TEXT,
  cancelled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_bookings_user ON bookings(user_id);
CREATE INDEX idx_bookings_flight ON bookings(flight_id);
CREATE INDEX idx_bookings_operator ON bookings(operator_id);
CREATE INDEX idx_bookings_status ON bookings(booking_status);
CREATE INDEX idx_bookings_ref ON bookings(booking_ref);
CREATE INDEX idx_bookings_date ON bookings(created_at);

-- 10. Payments
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount_egp DECIMAL(10,2) NOT NULL,
  currency_charged VARCHAR(3) DEFAULT 'EGP',
  amount_charged DECIMAL(10,2),
  method payment_method,
  gateway payment_gateway,
  gateway_transaction_id VARCHAR(255),
  status transaction_status NOT NULL DEFAULT 'pending',
  gateway_response JSONB,
  paid_at TIMESTAMPTZ,
  refunded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_payments_booking ON payments(booking_id);
CREATE INDEX idx_payments_user ON payments(user_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_gateway_txn ON payments(gateway_transaction_id);

-- 11. Reviews
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  booking_id UUID UNIQUE NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  operator_id UUID NOT NULL REFERENCES operators(id) ON DELETE CASCADE,
  flight_id UUID NOT NULL REFERENCES flights(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  photos JSONB, -- ["url1", "url2"]
  is_visible BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_reviews_operator ON reviews(operator_id);
CREATE INDEX idx_reviews_user ON reviews(user_id);
CREATE INDEX idx_reviews_rating ON reviews(rating);

-- 12. Notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title_en VARCHAR(255),
  title_ar VARCHAR(255),
  body_en TEXT,
  body_ar TEXT,
  type notification_type NOT NULL,
  data JSONB, -- { booking_id, flight_id, etc. }
  is_read BOOLEAN DEFAULT FALSE,
  scheduled_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(user_id, is_read);
CREATE INDEX idx_notifications_scheduled ON notifications(scheduled_at);

-- 13. Coupons
CREATE TABLE coupons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code VARCHAR(50) UNIQUE NOT NULL,
  type coupon_type NOT NULL,
  value DECIMAL(10,2) NOT NULL CHECK (value > 0),
  max_discount_egp DECIMAL(10,2),
  valid_from DATE NOT NULL,
  valid_to DATE NOT NULL,
  max_uses INT,
  used_count INT DEFAULT 0,
  operator_id UUID REFERENCES operators(id) ON DELETE SET NULL, -- NULL = all operators
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT chk_coupon_dates CHECK (valid_to >= valid_from)
);

CREATE INDEX idx_coupons_code ON coupons(code);
CREATE INDEX idx_coupons_active ON coupons(is_active, valid_from, valid_to);

-- 14. Platform Settings (key-value store)
CREATE TABLE platform_settings (
  key VARCHAR(100) PRIMARY KEY,
  value JSONB NOT NULL,
  description TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TRIGGERS
-- ============================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_operators_updated_at BEFORE UPDATE ON operators FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_balloons_updated_at BEFORE UPDATE ON balloons FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_pilots_updated_at BEFORE UPDATE ON pilots FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_drivers_updated_at BEFORE UPDATE ON drivers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_packages_updated_at BEFORE UPDATE ON packages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_flight_templates_updated_at BEFORE UPDATE ON flight_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_flights_updated_at BEFORE UPDATE ON flights FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_bookings_updated_at BEFORE UPDATE ON bookings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_reviews_updated_at BEFORE UPDATE ON reviews FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_coupons_updated_at BEFORE UPDATE ON coupons FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Update operator rating when a review is inserted/updated
CREATE OR REPLACE FUNCTION update_operator_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE operators
  SET 
    rating = (SELECT COALESCE(AVG(rating), 0) FROM reviews WHERE operator_id = NEW.operator_id AND is_visible = TRUE),
    total_reviews = (SELECT COUNT(*) FROM reviews WHERE operator_id = NEW.operator_id AND is_visible = TRUE),
    updated_at = NOW()
  WHERE id = NEW.operator_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_review_update_rating
AFTER INSERT OR UPDATE ON reviews
FOR EACH ROW EXECUTE FUNCTION update_operator_rating();

-- Update flight booked_count when booking status changes
CREATE OR REPLACE FUNCTION update_flight_booked_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.booking_status IN ('pending', 'confirmed') THEN
    UPDATE flights SET booked_count = booked_count + NEW.guest_count WHERE id = NEW.flight_id;
  ELSIF TG_OP = 'UPDATE' THEN
    -- If booking was active and is now cancelled/no_show, decrease count
    IF OLD.booking_status IN ('pending', 'confirmed', 'checked_in') 
       AND NEW.booking_status IN ('cancelled', 'no_show') THEN
      UPDATE flights SET booked_count = GREATEST(0, booked_count - OLD.guest_count) WHERE id = NEW.flight_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_booking_update_flight_count
AFTER INSERT OR UPDATE ON bookings
FOR EACH ROW EXECUTE FUNCTION update_flight_booked_count();

-- ============================================
-- SEED DATA: Default Platform Settings
-- ============================================

INSERT INTO platform_settings (key, value, description) VALUES
  ('commission_default_rate', '10', 'Default commission percentage'),
  ('currency_usd_rate', '49.50', 'USD to EGP exchange rate'),
  ('currency_eur_rate', '53.20', 'EUR to EGP exchange rate'),
  ('currency_gbp_rate', '62.10', 'GBP to EGP exchange rate'),
  ('currency_auto_update', 'true', 'Auto-update exchange rates'),
  ('notification_reminder_hours', '24', 'Hours before flight for reminder'),
  ('notification_pickup_hours', '3', 'Hours before flight for pickup reminder'),
  ('notification_review_hours', '2', 'Hours after flight for review request'),
  ('cancellation_full_refund_hours', '24', 'Hours before flight for full refund'),
  ('cancellation_partial_refund_hours', '12', 'Hours before flight for 50% refund'),
  ('flight_auto_generate', 'true', 'Auto-generate flights from templates'),
  ('flight_generate_ahead_days', '30', 'Days ahead to generate flights');
