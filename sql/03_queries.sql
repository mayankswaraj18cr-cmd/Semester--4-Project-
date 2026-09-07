USE hospital_db;

-- 1. Scheduled appointments with patient and doctor details.
SELECT appointment_date, appointment_time, patient_name, doctor_name,
       specialization, reason
FROM vw_doctor_schedule
WHERE status = 'Scheduled'
ORDER BY appointment_date, appointment_time;

-- 2. Currently admitted patients and their rooms.
SELECT room_number, room_type, patient_name, admission_date, diagnosis
FROM vw_room_occupancy
WHERE status = 'Occupied'
ORDER BY room_number;

-- 3. Rooms available for a new admission.
SELECT room_number, room_type, floor_number, daily_rate
FROM rooms
WHERE status = 'Available'
ORDER BY daily_rate, room_number;

-- 4. Appointment and admission activity for every patient.
SELECT patient_name, appointment_count, admission_count, last_appointment
FROM vw_patient_visits
ORDER BY appointment_count DESC, patient_name;

-- 5. Doctor workload by department for the current month.
SELECT d.department_name,
       CONCAT(doc.first_name, ' ', doc.last_name) AS doctor_name,
       COUNT(a.appointment_id) AS total_appointments,
       SUM(a.status = 'Completed') AS completed_appointments
FROM departments AS d
JOIN doctors AS doc ON doc.department_id = d.department_id
LEFT JOIN appointments AS a
    ON a.doctor_id = doc.doctor_id
   AND a.appointment_date >= '2026-09-01'
   AND a.appointment_date < '2026-10-01'
GROUP BY d.department_name, doc.doctor_id, doc.first_name, doc.last_name
ORDER BY d.department_name, total_appointments DESC;

-- 6. Medicines at or below their reorder level.
SELECT medication_name, stock_quantity, reorder_level,
       (reorder_level - stock_quantity) AS units_to_order
FROM medication
WHERE stock_quantity <= reorder_level
ORDER BY units_to_order DESC;

-- 7. Revenue by payment method and status.
SELECT payment_method, payment_status,
       COUNT(*) AS transaction_count,
       SUM(amount) AS total_amount
FROM payments
GROUP BY payment_method, payment_status
ORDER BY total_amount DESC;

-- 8. Patients with more than one clinical interaction.
SELECT patient_name, appointment_count, admission_count,
       appointment_count + admission_count AS total_interactions
FROM vw_patient_visits
WHERE appointment_count + admission_count > 1
ORDER BY total_interactions DESC;

-- 9. Latest appointment for every patient using a window function.
WITH ranked_appointments AS (
    SELECT p.patient_id,
           CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
           a.appointment_date,
           a.status,
           ROW_NUMBER() OVER (
               PARTITION BY p.patient_id
               ORDER BY a.appointment_date DESC, a.appointment_time DESC
           ) AS visit_rank
    FROM patients AS p
    LEFT JOIN appointments AS a ON a.patient_id = p.patient_id
)
SELECT patient_id, patient_name, appointment_date, status
FROM ranked_appointments
WHERE visit_rank = 1;

-- 10. Validate that room status matches active admissions.
SELECT r.room_number,
       r.status AS recorded_room_status,
       CASE WHEN a.admission_id IS NULL THEN 'Available' ELSE 'Occupied' END AS calculated_status
FROM rooms AS r
LEFT JOIN admissions AS a
    ON a.room_id = r.room_id AND a.status = 'Admitted'
WHERE r.status IN ('Available', 'Occupied')
  AND r.status <> CASE WHEN a.admission_id IS NULL THEN 'Available' ELSE 'Occupied' END;