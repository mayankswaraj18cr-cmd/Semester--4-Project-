-- MySQL 8.0 routines, triggers, and audit support for hospital_db.
USE hospital_db;

DROP TRIGGER IF EXISTS trg_admissions_before_insert;
DROP TRIGGER IF EXISTS trg_admissions_after_insert;
DROP TRIGGER IF EXISTS trg_admissions_after_update;
DROP TRIGGER IF EXISTS trg_payments_before_insert;
DROP TRIGGER IF EXISTS trg_medication_after_update;
DROP PROCEDURE IF EXISTS sp_book_appointment;
DROP PROCEDURE IF EXISTS sp_admit_patient;
DROP PROCEDURE IF EXISTS sp_discharge_patient;
DROP PROCEDURE IF EXISTS sp_restock_medication;
DROP PROCEDURE IF EXISTS sp_patient_summary;
DROP FUNCTION IF EXISTS fn_patient_age;
DROP FUNCTION IF EXISTS fn_patient_balance;

CREATE TABLE IF NOT EXISTS medication_stock_audit (
    audit_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    medication_id INT NOT NULL,
    old_quantity INT UNSIGNED NOT NULL,
    new_quantity INT UNSIGNED NOT NULL,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    change_reason VARCHAR(255) NOT NULL,
    CONSTRAINT fk_stock_audit_medication
        FOREIGN KEY (medication_id) REFERENCES medication(medication_id)
);

DELIMITER $$

CREATE FUNCTION fn_patient_age(
    p_patient_id INT,
    p_as_of_date DATE
)
RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_birth_date DATE;

    SELECT date_of_birth
    INTO v_birth_date
    FROM patients
    WHERE patient_id = p_patient_id;

    RETURN IF(v_birth_date IS NULL, NULL, TIMESTAMPDIFF(YEAR, v_birth_date, p_as_of_date));
END$$

CREATE FUNCTION fn_patient_balance(p_patient_id INT)
RETURNS DECIMAL(12, 2)
READS SQL DATA
DETERMINISTIC
BEGIN
    RETURN (
        SELECT COALESCE(SUM(
            CASE
                WHEN payment_status = 'Paid' THEN 0
                WHEN payment_status = 'Refunded' THEN -amount
                ELSE amount
            END
        ), 0.00)
        FROM payments
        WHERE patient_id = p_patient_id
    );
END$$

CREATE PROCEDURE sp_book_appointment(
    IN p_patient_id INT,
    IN p_doctor_id INT,
    IN p_date DATE,
    IN p_time TIME,
    IN p_reason VARCHAR(255),
    OUT p_appointment_id INT
)
MODIFIES SQL DATA
BEGIN
    DECLARE v_doctor_active BOOLEAN DEFAULT FALSE;
    DECLARE v_patient_exists INT DEFAULT 0;
    DECLARE v_conflict INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_patient_exists
    FROM patients
    WHERE patient_id = p_patient_id;

    IF v_patient_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient does not exist';
    END IF;

    SELECT active INTO v_doctor_active
    FROM doctors
    WHERE doctor_id = p_doctor_id;

    IF v_doctor_active = FALSE OR v_doctor_active IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Doctor is not active';
    END IF;

    SELECT COUNT(*) INTO v_conflict
    FROM appointments
    WHERE doctor_id = p_doctor_id
      AND appointment_date = p_date
      AND appointment_time = p_time
      AND status IN ('Scheduled', 'Completed');

    IF v_conflict > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Doctor already has an appointment at this time';
    END IF;

    INSERT INTO appointments
        (patient_id, doctor_id, appointment_date, appointment_time, reason)
    VALUES
        (p_patient_id, p_doctor_id, p_date, p_time, p_reason);

    SET p_appointment_id = LAST_INSERT_ID();
    COMMIT;
END$$

CREATE PROCEDURE sp_admit_patient(
    IN p_patient_id INT,
    IN p_room_id INT,
    IN p_doctor_id INT,
    IN p_diagnosis VARCHAR(255),
    OUT p_admission_id INT
)
MODIFIES SQL DATA
BEGIN
    DECLARE v_room_status VARCHAR(20);
    DECLARE v_patient_exists INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_patient_exists
    FROM patients
    WHERE patient_id = p_patient_id;

    IF v_patient_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient does not exist';
    END IF;

    SELECT status INTO v_room_status
    FROM rooms
    WHERE room_id = p_room_id
    FOR UPDATE;

    IF v_room_status IS NULL OR v_room_status <> 'Available' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room is not available';
    END IF;

    INSERT INTO admissions
        (patient_id, room_id, admitting_doctor_id, admission_date, diagnosis)
    VALUES
        (p_patient_id, p_room_id, p_doctor_id, CURRENT_TIMESTAMP, p_diagnosis);

    SET p_admission_id = LAST_INSERT_ID();
    COMMIT;
END$$

CREATE PROCEDURE sp_discharge_patient(
    IN p_admission_id INT,
    IN p_discharge_date DATETIME
)
MODIFIES SQL DATA
BEGIN
    DECLARE v_room_id INT;
    DECLARE v_status VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT room_id, status
    INTO v_room_id, v_status
    FROM admissions
    WHERE admission_id = p_admission_id
    FOR UPDATE;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Admission does not exist';
    END IF;

    IF v_status <> 'Admitted' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient is not currently admitted';
    END IF;

    UPDATE admissions
    SET discharge_date = COALESCE(p_discharge_date, CURRENT_TIMESTAMP),
        status = 'Discharged'
    WHERE admission_id = p_admission_id;

    UPDATE rooms
    SET status = 'Cleaning'
    WHERE room_id = v_room_id;

    COMMIT;
END$$

CREATE PROCEDURE sp_restock_medication(
    IN p_medication_id INT,
    IN p_units INT,
    IN p_reason VARCHAR(255)
)
MODIFIES SQL DATA
BEGIN
    IF p_units <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Restock quantity must be positive';
    END IF;

    UPDATE medication
    SET stock_quantity = stock_quantity + p_units
    WHERE medication_id = p_medication_id;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Medication does not exist';
    END IF;

    INSERT INTO medication_stock_audit
        (medication_id, old_quantity, new_quantity, change_reason)
    SELECT medication_id, stock_quantity - p_units, stock_quantity, p_reason
    FROM medication
    WHERE medication_id = p_medication_id;
END$$

CREATE PROCEDURE sp_patient_summary(IN p_patient_id INT)
READS SQL DATA
BEGIN
    SELECT
        p.patient_id,
        CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
        fn_patient_age(p.patient_id, CURRENT_DATE) AS age,
        p.blood_group,
        fn_patient_balance(p.patient_id) AS outstanding_balance,
        COUNT(DISTINCT a.appointment_id) AS appointment_count,
        COUNT(DISTINCT ad.admission_id) AS admission_count,
        MAX(a.appointment_date) AS last_appointment
    FROM patients AS p
    LEFT JOIN appointments AS a ON a.patient_id = p.patient_id
    LEFT JOIN admissions AS ad ON ad.patient_id = p.patient_id
    WHERE p.patient_id = p_patient_id
    GROUP BY p.patient_id, p.first_name, p.last_name, p.date_of_birth, p.blood_group;
END$$

CREATE TRIGGER trg_admissions_before_insert
BEFORE INSERT ON admissions
FOR EACH ROW
BEGIN
    DECLARE v_room_status VARCHAR(20);

    SELECT status INTO v_room_status
    FROM rooms
    WHERE room_id = NEW.room_id
    FOR UPDATE;

    IF v_room_status IS NULL OR v_room_status NOT IN ('Available', 'Cleaning') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Admission room is unavailable';
    END IF;
END$$

CREATE TRIGGER trg_admissions_after_insert
AFTER INSERT ON admissions
FOR EACH ROW
BEGIN
    UPDATE rooms
    SET status = 'Occupied'
    WHERE room_id = NEW.room_id;
END$$

CREATE TRIGGER trg_admissions_after_update
AFTER UPDATE ON admissions
FOR EACH ROW
BEGIN
    IF NEW.status IN ('Discharged', 'Transferred') AND OLD.status = 'Admitted' THEN
        UPDATE rooms
        SET status = 'Cleaning'
        WHERE room_id = NEW.room_id;
    END IF;
END$$

CREATE TRIGGER trg_payments_before_insert
BEFORE INSERT ON payments
FOR EACH ROW
BEGIN
    IF (NEW.admission_id IS NULL AND NEW.appointment_id IS NULL)
       OR (NEW.admission_id IS NOT NULL AND NEW.appointment_id IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payment must reference exactly one billable event';
    END IF;
END$$

CREATE TRIGGER trg_medication_after_update
AFTER UPDATE ON medication
FOR EACH ROW
BEGIN
    IF NEW.stock_quantity <> OLD.stock_quantity THEN
        INSERT INTO medication_stock_audit
            (medication_id, old_quantity, new_quantity, change_reason)
        VALUES
            (NEW.medication_id, OLD.stock_quantity, NEW.stock_quantity, 'Medication stock updated');
    END IF;
END$$

DELIMITER ;

-- Routine examples:
-- CALL sp_patient_summary(3);
-- CALL sp_restock_medication(5, 25, 'Monthly pharmacy delivery');