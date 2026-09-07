-- Hospital DBMS schema for MySQL 8.0+
CREATE DATABASE IF NOT EXISTS hospital_db;
USE hospital_db;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS medication_stock_audit;
DROP VIEW IF EXISTS vw_patient_visits;
DROP VIEW IF EXISTS vw_room_occupancy;
DROP VIEW IF EXISTS vw_doctor_schedule;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS prescriptions;
DROP TABLE IF EXISTS medication;
DROP TABLE IF EXISTS admissions;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS rooms;
DROP TABLE IF EXISTS doctors;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS patients;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(80) NOT NULL UNIQUE,
    floor_number TINYINT UNSIGNED NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE patients (
    patient_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('Female', 'Male', 'Non-binary', 'Prefer not to say') NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(120) UNIQUE,
    address VARCHAR(255),
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    blood_group ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE doctors (
    doctor_id INT PRIMARY KEY AUTO_INCREMENT,
    department_id INT NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    specialization VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(120) NOT NULL UNIQUE,
    years_experience TINYINT UNSIGNED NOT NULL,
    consultation_fee DECIMAL(10, 2) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_doctor_department
        FOREIGN KEY (department_id) REFERENCES departments(department_id),
    CONSTRAINT chk_doctor_experience CHECK (years_experience <= 60),
    CONSTRAINT chk_doctor_fee CHECK (consultation_fee >= 0)
);

CREATE TABLE rooms (
    room_id INT PRIMARY KEY AUTO_INCREMENT,
    department_id INT NOT NULL,
    room_number VARCHAR(10) NOT NULL UNIQUE,
    room_type ENUM('General', 'Private', 'Semi-Private', 'ICU', 'Emergency') NOT NULL,
    floor_number TINYINT UNSIGNED NOT NULL,
    daily_rate DECIMAL(10, 2) NOT NULL,
    status ENUM('Available', 'Occupied', 'Cleaning', 'Maintenance') NOT NULL DEFAULT 'Available',
    CONSTRAINT fk_room_department
        FOREIGN KEY (department_id) REFERENCES departments(department_id),
    CONSTRAINT chk_room_rate CHECK (daily_rate >= 0)
);

CREATE TABLE appointments (
    appointment_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    reason VARCHAR(255) NOT NULL,
    status ENUM('Scheduled', 'Completed', 'Cancelled', 'No-show') NOT NULL DEFAULT 'Scheduled',
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_appointment_patient
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    CONSTRAINT fk_appointment_doctor
        FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id),
    CONSTRAINT uq_doctor_appointment UNIQUE (doctor_id, appointment_date, appointment_time)
);

CREATE TABLE admissions (
    admission_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    room_id INT NOT NULL,
    admitting_doctor_id INT NOT NULL,
    admission_date DATETIME NOT NULL,
    discharge_date DATETIME,
    diagnosis VARCHAR(255) NOT NULL,
    status ENUM('Admitted', 'Discharged', 'Transferred') NOT NULL DEFAULT 'Admitted',
    CONSTRAINT fk_admission_patient
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    CONSTRAINT fk_admission_room
        FOREIGN KEY (room_id) REFERENCES rooms(room_id),
    CONSTRAINT fk_admission_doctor
        FOREIGN KEY (admitting_doctor_id) REFERENCES doctors(doctor_id),
    CONSTRAINT chk_admission_dates CHECK (discharge_date IS NULL OR discharge_date >= admission_date)
);

CREATE TABLE medication (
    medication_id INT PRIMARY KEY AUTO_INCREMENT,
    medication_name VARCHAR(120) NOT NULL UNIQUE,
    category VARCHAR(80) NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    stock_quantity INT UNSIGNED NOT NULL DEFAULT 0,
    reorder_level INT UNSIGNED NOT NULL DEFAULT 10,
    CONSTRAINT chk_medication_price CHECK (unit_price >= 0)
);

CREATE TABLE prescriptions (
    prescription_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    medication_id INT NOT NULL,
    prescribed_on DATE NOT NULL,
    dosage VARCHAR(100) NOT NULL,
    duration_days SMALLINT UNSIGNED NOT NULL,
    instructions VARCHAR(255),
    CONSTRAINT fk_prescription_patient
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    CONSTRAINT fk_prescription_doctor
        FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id),
    CONSTRAINT fk_prescription_medication
        FOREIGN KEY (medication_id) REFERENCES medication(medication_id),
    CONSTRAINT chk_prescription_duration CHECK (duration_days > 0)
);

CREATE TABLE payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    admission_id INT,
    appointment_id INT,
    amount DECIMAL(10, 2) NOT NULL,
    payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_method ENUM('Cash', 'Card', 'UPI', 'Insurance') NOT NULL,
    payment_status ENUM('Pending', 'Paid', 'Refunded') NOT NULL DEFAULT 'Paid',
    reference_number VARCHAR(40) UNIQUE,
    CONSTRAINT fk_payment_patient
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    CONSTRAINT fk_payment_admission
        FOREIGN KEY (admission_id) REFERENCES admissions(admission_id),
    CONSTRAINT fk_payment_appointment
        FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id),
    CONSTRAINT chk_payment_amount CHECK (amount > 0),
    CONSTRAINT chk_payment_source CHECK (admission_id IS NOT NULL OR appointment_id IS NOT NULL)
);

CREATE INDEX idx_appointments_date ON appointments(appointment_date, status);
CREATE INDEX idx_admissions_status ON admissions(status, admission_date);
CREATE INDEX idx_prescriptions_patient ON prescriptions(patient_id, prescribed_on);
CREATE INDEX idx_payments_date ON payments(payment_date, payment_status);

CREATE VIEW vw_doctor_schedule AS
SELECT a.appointment_id, a.appointment_date, a.appointment_time,
       CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
       d.specialization,
       CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
       a.reason, a.status
FROM appointments AS a
JOIN doctors AS d ON d.doctor_id = a.doctor_id
JOIN patients AS p ON p.patient_id = a.patient_id;

CREATE VIEW vw_room_occupancy AS
SELECT r.room_id, r.room_number, r.room_type, r.status,
       CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
       a.admission_date, a.diagnosis
FROM rooms AS r
LEFT JOIN admissions AS a
    ON a.room_id = r.room_id AND a.status = 'Admitted'
LEFT JOIN patients AS p ON p.patient_id = a.patient_id;

CREATE VIEW vw_patient_visits AS
SELECT p.patient_id,
       CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
       COUNT(DISTINCT a.appointment_id) AS appointment_count,
       COUNT(DISTINCT ad.admission_id) AS admission_count,
       MAX(a.appointment_date) AS last_appointment
FROM patients AS p
LEFT JOIN appointments AS a ON a.patient_id = p.patient_id
LEFT JOIN admissions AS ad ON ad.patient_id = p.patient_id
GROUP BY p.patient_id, p.first_name, p.last_name;