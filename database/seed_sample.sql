USE kisanflow_ai;

INSERT INTO procurement_centres (name, location, total_counters, active_counters, daily_capacity) VALUES
('Mandya Procurement Centre', 'Mandya, Karnataka', 6, 4, 240),
('Mysuru Procurement Centre', 'Mysuru, Karnataka', 5, 3, 180);

INSERT INTO crops (name, unit) VALUES
('Paddy', 'kg'),
('Ragi', 'kg'),
('Maize', 'kg'),
('Tur Dal', 'kg'),
('Groundnut', 'kg');

INSERT INTO users (email, password_hash, role) VALUES
('admin@example.com', '$2b$10$KeMvxMHoJyESdjt0PfDOZOgdhY9hflLW3wFLU9r5dg3.R1mWtgJXi', 'admin'),
('farmer1@example.com', '$2b$10$KeMvxMHoJyESdjt0PfDOZOgdhY9hflLW3wFLU9r5dg3.R1mWtgJXi', 'farmer'),
('farmer2@example.com', '$2b$10$KeMvxMHoJyESdjt0PfDOZOgdhY9hflLW3wFLU9r5dg3.R1mWtgJXi', 'farmer'),
('farmer3@example.com', '$2b$10$KeMvxMHoJyESdjt0PfDOZOgdhY9hflLW3wFLU9r5dg3.R1mWtgJXi', 'farmer');

INSERT INTO farmers (user_id, farmer_id, name, phone, village, district) VALUES
(2, 'FARM001', 'Ramesh Gowda', '9000000001', 'Nagamangala', 'Mandya'),
(3, 'FARM002', 'Lakshmi Devi', '9000000002', 'Srirangapatna', 'Mandya'),
(4, 'FARM003', 'Mahesh Kumar', '9000000003', 'Nanjangud', 'Mysuru');

INSERT INTO slots (centre_id, slot_date, slot_start, slot_end, max_capacity, booked_count, status) VALUES
(1, CURDATE(), '08:00:00', '08:30:00', 25, 12, 'open'),
(1, CURDATE(), '09:00:00', '09:30:00', 25, 18, 'open'),
(1, CURDATE(), '10:00:00', '10:30:00', 25, 22, 'open'),
(1, CURDATE(), '14:00:00', '14:30:00', 25, 9, 'open'),
(2, CURDATE(), '08:30:00', '09:00:00', 20, 10, 'open'),
(2, CURDATE(), '11:00:00', '11:30:00', 20, 17, 'open'),
(2, CURDATE(), '13:30:00', '14:00:00', 20, 7, 'open');

-- For stronger demo predictions, expand this seed to 30+ farmers and at least 100+ rows in historical_queue_data.
-- Include multiple days, fluctuating processing times, and mixed load windows to improve AI recommendations.
