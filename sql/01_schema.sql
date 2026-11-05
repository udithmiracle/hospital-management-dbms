-- Hospital Management System: database schema (MySQL 8+)

DROP DATABASE IF EXISTS hospital_db;
CREATE DATABASE hospital_db;
USE hospital_db;

CREATE TABLE departments (
    department_id   INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE doctors (
    doctor_id        INT AUTO_INCREMENT PRIMARY KEY,
    first_name       VARCHAR(50)   NOT NULL,
    last_name        VARCHAR(50)   NOT NULL,
    phone            VARCHAR(15)   NOT NULL UNIQUE,
    consultation_fee DECIMAL(10,2) NOT NULL CHECK (consultation_fee >= 0),
    department_id    INT           NOT NULL,
    FOREIGN KEY (department_id) REFERENCES departments (department_id)
);

CREATE TABLE patients (
    patient_id    INT AUTO_INCREMENT PRIMARY KEY,
    first_name    VARCHAR(50)                   NOT NULL,
    last_name     VARCHAR(50)                   NOT NULL,
    gender        ENUM('Male','Female','Other') NOT NULL,
    date_of_birth DATE                          NOT NULL,
    phone         VARCHAR(15)                   NOT NULL,
    city          VARCHAR(50)                   NOT NULL
);

CREATE TABLE appointments (
    appointment_id   INT AUTO_INCREMENT PRIMARY KEY,
    patient_id       INT      NOT NULL,
    doctor_id        INT      NOT NULL,
    appointment_time DATETIME NOT NULL,
    status           ENUM('Scheduled','Completed','Cancelled') NOT NULL DEFAULT 'Scheduled',
    diagnosis        VARCHAR(200) NULL,
    UNIQUE (doctor_id, appointment_time),   -- a doctor cannot be double-booked
    FOREIGN KEY (patient_id) REFERENCES patients (patient_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors (doctor_id)
);

CREATE TABLE medicines (
    medicine_id   INT AUTO_INCREMENT PRIMARY KEY,
    medicine_name VARCHAR(100)  NOT NULL UNIQUE,
    unit_price    DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    stock_qty     INT           NOT NULL CHECK (stock_qty >= 0)
);

-- Resolves the many-to-many relationship between appointments and medicines.
CREATE TABLE prescription_items (
    appointment_id INT NOT NULL,
    medicine_id    INT NOT NULL,
    quantity       INT NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (appointment_id, medicine_id),
    FOREIGN KEY (appointment_id) REFERENCES appointments (appointment_id),
    FOREIGN KEY (medicine_id) REFERENCES medicines (medicine_id)
);

CREATE TABLE bills (
    bill_id             INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id      INT           NOT NULL UNIQUE,   -- one bill per appointment
    consultation_amount DECIMAL(10,2) NOT NULL,
    medicine_amount     DECIMAL(10,2) NOT NULL,
    total_amount        DECIMAL(10,2) GENERATED ALWAYS AS (consultation_amount + medicine_amount) STORED,
    bill_date           DATE          NOT NULL,
    payment_status      ENUM('Unpaid','Paid') NOT NULL DEFAULT 'Unpaid',
    FOREIGN KEY (appointment_id) REFERENCES appointments (appointment_id)
);

CREATE INDEX idx_patients_phone ON patients (phone);
CREATE INDEX idx_appointments_time ON appointments (appointment_time);

-- View: appointments with readable patient, doctor and department names.
CREATE VIEW appointment_details AS
SELECT a.appointment_id,
       a.appointment_time,
       a.status,
       a.diagnosis,
       CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
       CONCAT('Dr. ', d.first_name, ' ', d.last_name) AS doctor_name,
       dep.department_name
FROM appointments a
JOIN patients p ON p.patient_id = a.patient_id
JOIN doctors d ON d.doctor_id = a.doctor_id
JOIN departments dep ON dep.department_id = d.department_id;

DELIMITER $$

-- Trigger: check stock and reduce it when a medicine is prescribed.
CREATE TRIGGER trg_reduce_stock
BEFORE INSERT ON prescription_items
FOR EACH ROW
BEGIN
    DECLARE v_stock INT;

    SELECT stock_qty INTO v_stock
    FROM medicines
    WHERE medicine_id = NEW.medicine_id;

    IF v_stock < NEW.quantity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not enough stock for this medicine';
    END IF;

    UPDATE medicines
    SET stock_qty = stock_qty - NEW.quantity
    WHERE medicine_id = NEW.medicine_id;
END$$

-- Procedure: create the bill for a completed appointment.
CREATE PROCEDURE generate_bill(IN p_appointment_id INT)
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_fee DECIMAL(10,2);
    DECLARE v_date DATE;
    DECLARE v_medicine DECIMAL(10,2);

    SELECT a.status, d.consultation_fee, DATE(a.appointment_time)
    INTO v_status, v_fee, v_date
    FROM appointments a
    JOIN doctors d ON d.doctor_id = a.doctor_id
    WHERE a.appointment_id = p_appointment_id;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Appointment not found';
    END IF;

    IF v_status <> 'Completed' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only completed appointments can be billed';
    END IF;

    SELECT COALESCE(SUM(pi.quantity * m.unit_price), 0)
    INTO v_medicine
    FROM prescription_items pi
    JOIN medicines m ON m.medicine_id = pi.medicine_id
    WHERE pi.appointment_id = p_appointment_id;

    INSERT INTO bills (appointment_id, consultation_amount, medicine_amount, bill_date)
    VALUES (p_appointment_id, v_fee, v_medicine, v_date);
END$$

DELIMITER ;
