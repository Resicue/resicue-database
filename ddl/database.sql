
-- Set the timezone to Nicaragua
SET TIME ZONE 'America/Managua';


-- PostgreSQL Schema with UUIDs, ENUMs, automatic timestamps, and triggers
-- Generated on 2025-03-21 03:07:42

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ENUM types
CREATE TYPE user_role AS ENUM ('resident', 'admin', 'guard');
CREATE TYPE status_type AS ENUM ('pending', 'approved', 'cancelled', 'rejected');
CREATE TYPE transaction_status AS ENUM ('SUCCESS', 'ERROR');
CREATE TYPE access_event AS ENUM ('check-in', 'check-out');
CREATE TYPE action_type AS ENUM ('CREATE', 'UPDATE', 'DELETE');

-- Trigger function to update 'updated_at'
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- USERS
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  public_id SERIAL UNIQUE,
  first_name VARCHAR,
  last_name VARCHAR,
  email VARCHAR UNIQUE NOT NULL,
  phone VARCHAR,
  password VARCHAR NOT NULL,
  role user_role NOT NULL DEFAULT 'resident',
  profile_image_url TEXT,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

CREATE TRIGGER trg_users_updated
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- RESIDENTIALS
CREATE TABLE residentials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR NOT NULL,
  address TEXT,
  city VARCHAR,
  state VARCHAR,
  country VARCHAR,
  admin_id UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

CREATE TRIGGER trg_residentials_updated
BEFORE UPDATE ON residentials
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- USER ↔ RESIDENTIAL
CREATE TABLE user_residentials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  residential_id UUID REFERENCES residentials(id),
  is_owner BOOLEAN DEFAULT TRUE,
  unit_name VARCHAR,
  unit_image_url TEXT,
  created_at TIMESTAMP DEFAULT now()
);

-- COMMON AREAS
CREATE TABLE common_areas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  residential_id UUID REFERENCES residentials(id),
  name VARCHAR,
  description TEXT,
  image_url TEXT,
  capacity INT,
  created_at TIMESTAMP DEFAULT now()
);

-- RESERVATIONS
CREATE TABLE reservations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  common_area_id UUID REFERENCES common_areas(id),
  description TEXT,
  reservation_date DATE,
  start_time TIME,
  end_time TIME,
  status status_type DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT now()
);

-- PAYMENTS
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  residential_id UUID REFERENCES residentials(id),
  amount DECIMAL(10,2),
  payment_method VARCHAR,
  description TEXT,
  payment_date DATE,
  status status_type DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT now()
);

-- PAYMENT HISTORY
CREATE TABLE payment_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id UUID REFERENCES payments(id),
  previous_status status_type,
  new_status status_type,
  changed_at TIMESTAMP DEFAULT now(),
  notes TEXT
);

-- ACCESS CONTROLS
CREATE TABLE access_controls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  visitor_name VARCHAR,
  visitor_id_document VARCHAR,
  visit_reason TEXT,
  destination_unit VARCHAR,
  residential_id UUID REFERENCES residentials(id),
  registered_by UUID REFERENCES users(id),
  check_in TIMESTAMP,
  check_out TIMESTAMP,
  authorized_by UUID REFERENCES users(id),
  notes TEXT,
  qr_code_data TEXT
);

-- ACCESS LOGS
CREATE TABLE access_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  access_control_id UUID REFERENCES access_controls(id),
  event_type access_event,
  timestamp TIMESTAMP DEFAULT now(),
  recorded_by UUID REFERENCES users(id)
);

-- ANNOUNCEMENTS
CREATE TABLE announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR,
  content TEXT,
  residential_id UUID REFERENCES residentials(id),
  created_by UUID REFERENCES users(id),
  published_at TIMESTAMP,
  expires_at TIMESTAMP
);

-- FILE ATTACHMENTS
CREATE TABLE file_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type VARCHAR,
  entity_id UUID,
  file_name VARCHAR,
  file_url TEXT,
  uploaded_at TIMESTAMP DEFAULT now()
);

-- NOTIFICATIONS
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  title VARCHAR,
  message TEXT,
  type VARCHAR,
  is_read BOOLEAN DEFAULT FALSE,
  sent_at TIMESTAMP DEFAULT now()
);

-- CHATS
CREATE TABLE chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID REFERENCES users(id),
  receiver_id UUID REFERENCES users(id),
  message TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  sent_at TIMESTAMP DEFAULT now()
);

-- GUARD MOVEMENTS
CREATE TABLE guard_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  guard_id UUID REFERENCES users(id),
  movement_type access_event,
  timestamp TIMESTAMP DEFAULT now(),
  residential_id UUID REFERENCES residentials(id),
  notes TEXT
);

-- SURVEYS
CREATE TABLE surveys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR,
  description TEXT,
  created_by UUID REFERENCES users(id),
  residential_id UUID REFERENCES residentials(id),
  start_date TIMESTAMP,
  end_date TIMESTAMP
);

-- SURVEY OPTIONS
CREATE TABLE survey_options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  survey_id UUID REFERENCES surveys(id),
  option_text VARCHAR
);

-- SURVEY VOTES
CREATE TABLE survey_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  survey_id UUID REFERENCES surveys(id),
  option_id UUID REFERENCES survey_options(id),
  user_id UUID REFERENCES users(id),
  voted_at TIMESTAMP DEFAULT now()
);

-- DOCUMENTS
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR,
  description TEXT,
  file_url TEXT,
  residential_id UUID REFERENCES residentials(id),
  created_by UUID REFERENCES users(id),
  document_type VARCHAR,
  created_at TIMESTAMP DEFAULT now()
);

-- OWNERSHIP TRANSFERS
CREATE TABLE ownership_transfers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  current_owner_id UUID REFERENCES users(id),
  new_owner_id UUID REFERENCES users(id),
  residential_id UUID REFERENCES residentials(id),
  unit_name VARCHAR,
  reason TEXT,
  status status_type DEFAULT 'pending',
  requested_at TIMESTAMP DEFAULT now(),
  resolved_at TIMESTAMP,
  resolved_by UUID REFERENCES users(id)
);

-- TRANSACTION LOGS
CREATE TABLE transaction_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  entity_type VARCHAR,
  entity_id UUID,
  action action_type,
  status transaction_status,
  message TEXT,
  created_at TIMESTAMP DEFAULT now()
);
