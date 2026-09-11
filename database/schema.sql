CREATE DATABASE IF NOT EXISTS kisanflow_ai CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE kisanflow_ai;

CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  email VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('farmer', 'admin') NOT NULL DEFAULT 'farmer',
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_users_email (email),
  KEY idx_users_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS farmers (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  farmer_id VARCHAR(50) NOT NULL,
  name VARCHAR(120) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  village VARCHAR(120) NOT NULL,
  district VARCHAR(120) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_farmers_user_id (user_id),
  UNIQUE KEY uk_farmers_farmer_id (farmer_id),
  KEY idx_farmers_phone (phone),
  CONSTRAINT fk_farmers_user_id FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS procurement_centres (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(150) NOT NULL,
  location VARCHAR(255) NOT NULL,
  total_counters INT UNSIGNED NOT NULL DEFAULT 1,
  active_counters INT UNSIGNED NOT NULL DEFAULT 1,
  daily_capacity INT UNSIGNED NOT NULL DEFAULT 100,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_centres_location (location)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS crops (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(120) NOT NULL,
  unit VARCHAR(20) NOT NULL DEFAULT 'kg',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_crops_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS slots (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  centre_id BIGINT UNSIGNED NOT NULL,
  slot_date DATE NOT NULL,
  slot_start TIME NOT NULL,
  slot_end TIME NOT NULL,
  max_capacity INT UNSIGNED NOT NULL,
  booked_count INT UNSIGNED NOT NULL DEFAULT 0,
  status ENUM('open', 'full', 'closed') NOT NULL DEFAULT 'open',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_slot_unique (centre_id, slot_date, slot_start, slot_end),
  KEY idx_slots_date (slot_date),
  KEY idx_slots_status (status),
  CONSTRAINT fk_slots_centre_id FOREIGN KEY (centre_id) REFERENCES procurement_centres (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS bookings (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  farmer_id BIGINT UNSIGNED NOT NULL,
  centre_id BIGINT UNSIGNED NOT NULL,
  crop_id BIGINT UNSIGNED NOT NULL,
  slot_id BIGINT UNSIGNED NULL,
  quantity DECIMAL(10,2) NOT NULL,
  booking_date DATE NOT NULL,
  slot_start TIME NOT NULL,
  slot_end TIME NOT NULL,
  token_number VARCHAR(20) NOT NULL,
  status ENUM('booked', 'cancelled', 'completed', 'no_show') NOT NULL DEFAULT 'booked',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_bookings_token (token_number),
  KEY idx_bookings_farmer (farmer_id),
  KEY idx_bookings_centre_date (centre_id, booking_date),
  KEY idx_bookings_status (status),
  CONSTRAINT fk_bookings_farmer_id FOREIGN KEY (farmer_id) REFERENCES farmers (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_bookings_centre_id FOREIGN KEY (centre_id) REFERENCES procurement_centres (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_bookings_crop_id FOREIGN KEY (crop_id) REFERENCES crops (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_bookings_slot_id FOREIGN KEY (slot_id) REFERENCES slots (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS queue_entries (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  booking_id BIGINT UNSIGNED NOT NULL,
  token_number VARCHAR(20) NOT NULL,
  queue_position INT UNSIGNED NOT NULL,
  status ENUM('waiting', 'called', 'processing', 'completed', 'skipped', 'no_show') NOT NULL DEFAULT 'waiting',
  estimated_wait_minutes INT UNSIGNED NOT NULL DEFAULT 0,
  joined_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  called_at DATETIME NULL,
  completed_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_queue_booking_id (booking_id),
  KEY idx_queue_status (status),
  KEY idx_queue_position (queue_position),
  CONSTRAINT fk_queue_booking_id FOREIGN KEY (booking_id) REFERENCES bookings (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS counters (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  centre_id BIGINT UNSIGNED NOT NULL,
  counter_name VARCHAR(100) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  status ENUM('idle', 'busy', 'offline') NOT NULL DEFAULT 'idle',
  current_queue_entry_id BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_counters_name (centre_id, counter_name),
  KEY idx_counters_status (status),
  CONSTRAINT fk_counters_centre_id FOREIGN KEY (centre_id) REFERENCES procurement_centres (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_counters_queue_entry FOREIGN KEY (current_queue_entry_id) REFERENCES queue_entries (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notifications (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(150) NOT NULL,
  message TEXT NOT NULL,
  type ENUM('info', 'success', 'warning', 'alert') NOT NULL DEFAULT 'info',
  is_read TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_notifications_user_read (user_id, is_read),
  CONSTRAINT fk_notifications_user_id FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS procurement_records (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  booking_id BIGINT UNSIGNED NOT NULL,
  centre_id BIGINT UNSIGNED NOT NULL,
  farmer_id BIGINT UNSIGNED NOT NULL,
  crop_id BIGINT UNSIGNED NOT NULL,
  quantity_procured DECIMAL(10,2) NOT NULL,
  quality_grade VARCHAR(20) NULL,
  processing_started_at DATETIME NULL,
  processing_completed_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_procurement_booking_id (booking_id),
  KEY idx_procurement_centre (centre_id),
  KEY idx_procurement_completed_at (processing_completed_at),
  CONSTRAINT fk_procurement_booking_id FOREIGN KEY (booking_id) REFERENCES bookings (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_procurement_centre_id FOREIGN KEY (centre_id) REFERENCES procurement_centres (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_procurement_farmer_id FOREIGN KEY (farmer_id) REFERENCES farmers (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_procurement_crop_id FOREIGN KEY (crop_id) REFERENCES crops (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS historical_queue_data (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  centre_id BIGINT UNSIGNED NOT NULL,
  queue_date DATE NOT NULL,
  slot_start TIME NOT NULL,
  slot_end TIME NOT NULL,
  num_farmers INT UNSIGNED NOT NULL DEFAULT 0,
  avg_processing_time_seconds INT UNSIGNED NOT NULL DEFAULT 0,
  total_quantity DECIMAL(12,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_historical_centre_date (centre_id, queue_date),
  KEY idx_historical_slot (slot_start, slot_end),
  CONSTRAINT fk_historical_centre_id FOREIGN KEY (centre_id) REFERENCES procurement_centres (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
