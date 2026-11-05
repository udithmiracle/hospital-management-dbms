-- Hospital Management System: example queries

USE hospital_db;

-- 1. All upcoming appointments.
SELECT appointment_time, patient_name, doctor_name, department_name
FROM appointment_details
WHERE status = 'Scheduled'
ORDER BY appointment_time;

-- 2. Completed appointments per doctor (LEFT JOIN keeps doctors with none).
SELECT CONCAT('Dr. ', d.first_name, ' ', d.last_name) AS doctor_name,
       COUNT(a.appointment_id) AS completed_appointments
FROM doctors d
LEFT JOIN appointments a
       ON a.doctor_id = d.doctor_id AND a.status = 'Completed'
GROUP BY d.doctor_id, d.first_name, d.last_name
ORDER BY completed_appointments DESC;

-- 3. Revenue by department.
SELECT dep.department_name, SUM(b.total_amount) AS revenue
FROM bills b
JOIN appointments a ON a.appointment_id = b.appointment_id
JOIN doctors d ON d.doctor_id = a.doctor_id
JOIN departments dep ON dep.department_id = d.department_id
GROUP BY dep.department_id, dep.department_name
ORDER BY revenue DESC;

-- 4. Revenue by month.
SELECT DATE_FORMAT(bill_date, '%Y-%m') AS bill_month,
       COUNT(*) AS bills,
       SUM(total_amount) AS revenue
FROM bills
GROUP BY bill_month
ORDER BY bill_month;

-- 5. Unpaid bills with patient contact details.
SELECT b.bill_id, CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
       p.phone, b.total_amount
FROM bills b
JOIN appointments a ON a.appointment_id = b.appointment_id
JOIN patients p ON p.patient_id = a.patient_id
WHERE b.payment_status = 'Unpaid';

-- 6. Patients who visited more than once.
SELECT CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
       COUNT(*) AS completed_visits
FROM patients p
JOIN appointments a ON a.patient_id = p.patient_id
WHERE a.status = 'Completed'
GROUP BY p.patient_id, p.first_name, p.last_name
HAVING COUNT(*) > 1;

-- 7. Most prescribed medicines.
SELECT m.medicine_name, SUM(pi.quantity) AS total_prescribed
FROM prescription_items pi
JOIN medicines m ON m.medicine_id = pi.medicine_id
GROUP BY m.medicine_id, m.medicine_name
ORDER BY total_prescribed DESC;

-- 8. Medicines running low (under 50 units).
SELECT medicine_name, stock_qty
FROM medicines
WHERE stock_qty < 50
ORDER BY stock_qty;

-- 9. Highest bill in each department (window function).
SELECT department_name, bill_id, total_amount
FROM (
    SELECT dep.department_name, b.bill_id, b.total_amount,
           RANK() OVER (PARTITION BY dep.department_id ORDER BY b.total_amount DESC) AS bill_rank
    FROM bills b
    JOIN appointments a ON a.appointment_id = b.appointment_id
    JOIN doctors d ON d.doctor_id = a.doctor_id
    JOIN departments dep ON dep.department_id = d.department_id
) ranked
WHERE bill_rank = 1;

-- 10. Patients with no completed appointment (subquery).
SELECT first_name, last_name
FROM patients
WHERE patient_id NOT IN (
    SELECT patient_id FROM appointments WHERE status = 'Completed'
);

-- 11. These two commands are rejected on purpose. Remove the -- to try them.
-- CALL generate_bill(8);   -- appointment 8 is not completed yet
-- INSERT INTO prescription_items VALUES (1, 5, 1000);   -- more than the stock
