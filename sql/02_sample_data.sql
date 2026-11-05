-- Hospital Management System: sample data
-- All people, phone numbers and medical records here are fictional.

USE hospital_db;

INSERT INTO departments (department_name) VALUES
('Cardiology'),
('Orthopedics'),
('Pediatrics'),
('General Medicine');

INSERT INTO doctors (first_name, last_name, phone, consultation_fee, department_id) VALUES
('Prasad', 'Rao', '9000000001', 800.00, 1),
('Swathi', 'Menon', '9000000002', 600.00, 2),
('Nikhil', 'Verma', '9000000003', 500.00, 3),
('Farah', 'Khan', '9000000004', 300.00, 4),
('Vamsi', 'Krishna', '9000000005', 300.00, 4);

INSERT INTO patients (first_name, last_name, gender, date_of_birth, phone, city) VALUES
('Ramesh', 'Gupta', 'Male', '1968-04-12', '9100000001', 'Srikakulam'),
('Sunita', 'Devi', 'Female', '1975-09-03', '9100000002', 'Vizianagaram'),
('Aarav', 'Mishra', 'Male', '2018-12-25', '9100000003', 'Srikakulam'),
('Priya', 'Nair', 'Female', '1992-06-17', '9100000004', 'Visakhapatnam'),
('Joseph', 'Thomas', 'Male', '1985-02-28', '9100000005', 'Srikakulam'),
('Ishita', 'Sen', 'Female', '2020-08-08', '9100000006', 'Visakhapatnam');

INSERT INTO medicines (medicine_name, unit_price, stock_qty) VALUES
('Paracetamol 500mg', 2.00, 500),
('Amoxicillin 250mg', 8.50, 200),
('Atorvastatin 10mg', 12.00, 150),
('Calcium Tablets', 5.00, 300),
('Cough Syrup 100ml', 75.00, 40);

INSERT INTO appointments (patient_id, doctor_id, appointment_time, status, diagnosis) VALUES
(1, 1, '2026-01-10 10:00:00', 'Completed', 'High cholesterol'),
(2, 2, '2026-01-12 11:00:00', 'Completed', 'Knee pain'),
(3, 3, '2026-01-15 09:30:00', 'Completed', 'Viral fever'),
(4, 4, '2026-01-20 12:00:00', 'Completed', 'Throat infection'),
(1, 1, '2026-02-10 10:00:00', 'Completed', 'Cholesterol follow-up'),
(5, 4, '2026-02-14 16:00:00', 'Cancelled', NULL),
(6, 3, '2026-03-02 10:30:00', 'Completed', 'Common cold'),
(2, 2, '2026-04-05 11:00:00', 'Scheduled', NULL);

-- The trigger reduces medicine stock as these rows are inserted.
INSERT INTO prescription_items (appointment_id, medicine_id, quantity) VALUES
(1, 3, 30),
(2, 4, 30),
(2, 1, 10),
(3, 1, 6),
(3, 5, 1),
(4, 2, 15),
(5, 3, 30),
(7, 5, 1);

CALL generate_bill(1);
CALL generate_bill(2);
CALL generate_bill(3);
CALL generate_bill(4);
CALL generate_bill(5);
CALL generate_bill(7);

UPDATE bills SET payment_status = 'Paid' WHERE appointment_id IN (1, 2, 3, 5);
