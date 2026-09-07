USE hospital_db;

INSERT INTO departments (department_name, floor_number, phone) VALUES
    ('Cardiology', 2, '011-4001001'),
    ('Orthopedics', 3, '011-4001002'),
    ('Pediatrics', 4, '011-4001003'),
    ('Emergency', 1, '011-4001004'),
    ('Pharmacy', 1, '011-4001005');

INSERT INTO patients
    (first_name, last_name, date_of_birth, gender, phone, email, address,
     emergency_contact_name, emergency_contact_phone, blood_group)
VALUES
    ('Mayank', 'Swaraj', '2007-04-12', 'Male', '9876543210', 'mayank@example.com', 'New Delhi', 'Anita Swaraj', '9876500001', 'B+'),
    ('Isha', 'Kapoor', '1992-09-21', 'Female', '9123456780', 'isha@example.com', 'Noida', 'Ravi Kapoor', '9123400001', 'O+'),
    ('Rohan', 'Mehta', '1979-02-05', 'Male', '9988776655', 'rohan@example.com', 'Gurugram', 'Neha Mehta', '9988700001', 'A+'),
    ('Aanya', 'Sharma', '2015-06-30', 'Female', '9012345678', 'aanya@example.com', 'Delhi', 'Karan Sharma', '9012300001', 'AB+'),
    ('Vikram', 'Singh', '1968-12-17', 'Male', '9345678901', 'vikram@example.com', 'Faridabad', 'Pooja Singh', '9345600001', 'O-');

INSERT INTO doctors
    (department_id, first_name, last_name, specialization, phone, email,
     years_experience, consultation_fee)
VALUES
    (1, 'Aarav', 'Sharma', 'Cardiology', '8800000101', 'aarav.sharma@hospital.test', 12, 900.00),
    (2, 'Nisha', 'Verma', 'Orthopedics', '8800000102', 'nisha.verma@hospital.test', 8, 700.00),
    (3, 'Arjun', 'Nair', 'Pediatrics', '8800000103', 'arjun.nair@hospital.test', 15, 650.00),
    (4, 'Meera', 'Joshi', 'Emergency Medicine', '8800000104', 'meera.joshi@hospital.test', 10, 800.00),
    (1, 'Kabir', 'Malhotra', 'Interventional Cardiology', '8800000105', 'kabir.malhotra@hospital.test', 18, 1200.00);

INSERT INTO rooms
    (department_id, room_number, room_type, floor_number, daily_rate, status)
VALUES
    (1, '201A', 'Private', 2, 4500.00, 'Available'),
    (1, '201B', 'ICU', 2, 9000.00, 'Occupied'),
    (2, '301A', 'General', 3, 1800.00, 'Available'),
    (2, '301B', 'Semi-Private', 3, 2800.00, 'Cleaning'),
    (3, '401A', 'Private', 4, 4500.00, 'Available'),
    (4, '101A', 'Emergency', 1, 3500.00, 'Occupied');

INSERT INTO appointments
    (patient_id, doctor_id, appointment_date, appointment_time, reason, status, notes)
VALUES
    (1, 1, '2026-09-10', '09:00:00', 'Routine cardiac screening', 'Scheduled', NULL),
    (2, 2, '2026-09-10', '10:30:00', 'Knee pain evaluation', 'Scheduled', NULL),
    (3, 5, '2026-09-11', '11:00:00', 'Follow-up consultation', 'Completed', 'Review ECG results'),
    (4, 3, '2026-09-11', '14:00:00', 'Annual child wellness check', 'Scheduled', NULL),
    (5, 4, '2026-09-12', '16:30:00', 'Shortness of breath', 'Completed', 'Referred from emergency desk');

INSERT INTO admissions
    (patient_id, room_id, admitting_doctor_id, admission_date, discharge_date, diagnosis, status)
VALUES
    (3, 2, 5, '2026-09-06 18:20:00', NULL, 'Acute chest pain observation', 'Admitted'),
    (5, 6, 4, '2026-09-04 09:10:00', '2026-09-06 11:00:00', 'Respiratory infection', 'Discharged');

INSERT INTO medication
    (medication_name, category, unit_price, stock_quantity, reorder_level)
VALUES
    ('Aspirin 75mg', 'Antiplatelet', 2.50, 250, 40),
    ('Amoxicillin 500mg', 'Antibiotic', 8.00, 120, 30),
    ('Paracetamol 500mg', 'Analgesic', 1.50, 500, 60),
    ('Atorvastatin 20mg', 'Statin', 4.25, 80, 20),
    ('Salbutamol Inhaler', 'Respiratory', 120.00, 18, 10);

INSERT INTO prescriptions
    (patient_id, doctor_id, medication_id, prescribed_on, dosage, duration_days, instructions)
VALUES
    (3, 5, 1, '2026-09-06', '1 tablet daily', 30, 'Take after breakfast'),
    (3, 5, 4, '2026-09-06', '1 tablet at night', 30, 'Avoid grapefruit juice'),
    (5, 4, 5, '2026-09-04', '2 puffs as needed', 14, 'Use with spacer');

INSERT INTO payments
    (patient_id, admission_id, appointment_id, amount, payment_method, payment_status, reference_number)
VALUES
    (1, NULL, 1, 900.00, 'UPI', 'Paid', 'UPI-20260910-001'),
    (2, NULL, 2, 700.00, 'Card', 'Paid', 'CARD-20260910-002'),
    (3, 1, NULL, 18000.00, 'Insurance', 'Pending', 'INS-20260906-003'),
    (5, 2, NULL, 7200.00, 'Cash', 'Paid', 'CASH-20260904-004');