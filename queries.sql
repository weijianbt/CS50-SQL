-- In this SQL file, write (and comment!) the typical SQL queries users will run on your database


-- find the date of Doctor Ismail Ahmad's upcoming appointment dates for the next 7 days
SELECT `next_appointment_date` FROM `upcoming_appointments`
WHERE `doctor_first_name` = 'Ahmad' AND `doctor_last_name` = 'Ismail' AND `days_to_appointment` <= 7
ORDER BY `next_appointment_date`;

-- find all history of diagnose for patient Raj Kumar
SELECT * FROM `appointments` WHERE `patient_id` = (
    SELECT `id` FROM `patients`
    WHERE `first_name` = 'Kumar' AND `last_name` = 'Raj'
);

-- get upcoming appointments to send reminder
SELECT * FROM `upcoming_appointments`
WHERE `days_to_appointment` = 1;

-- find how long the worker has stayed with the company
SELECT `id`, `first_name`, `last_name`, TIMESTAMPDIFF(YEAR, `join_date`, NOW()) AS 'years_with_company', `role`
FROM `workers`
ORDER BY `role`, `years_with_company` DESC;

-- find how much was charged to each patient
WITH `fees` AS (
    SELECT
        `patient_id`,
        SUM(`amount_paid`) AS 'total_fee',
        AVG(`amount_paid`) AS 'average_fee',
        COUNT(`patient_id`) AS 'visit_count'
    FROM `appointments`
    GROUP BY `patient_id`
)
SELECT
    `patients`.`id`,
    `patients`.`first_name`,
    `patients`.`last_name`,
    `fees`.`total_fee`,
    `fees`.`average_fee`,
    `fees`.`visit_count`
FROM `patients`
JOIN `fees` ON `fees`.`patient_id` = `patients`.`id`
ORDER BY `fees`.`total_fee`；



-- as the owner of the clinic, you want to view metrics
SELECT * FROM `upcoming_appointments`;

-- check all doctor's appointment count for the next 7 days
-- check how many appointments per day for doctor_id = 1
WITH `weekly_date` AS (
    SELECT CURDATE() + INTERVAL n DAY as `date`
    FROM (
        SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6
    ) AS `7_days`
),
`doctor_ids` AS (
    SELECT DISTINCT `id`, `first_name`, `last_name`
    FROM `workers`
    WHERE `role` = 'Doctor'
), `doctor_appointments` AS (
    SELECT
        DATE(`next_appointment_date`) AS `appointment_date`,
        DATE_FORMAT(`next_appointment_date`, "%W") AS `appointment_day`,
        `upcoming_appointments`.`doctor_id`,
        `upcoming_appointments`.`doctor_last_name`,
        `upcoming_appointments`.`doctor_first_name`,
        COUNT(*) AS `appointment_count`
    FROM `upcoming_appointments`
    WHERE `days_to_appointment` <= 7
    GROUP BY `doctor_id`, `appointment_date`, `appointment_day`
    ORDER BY `appointment_date`, `doctor_id`
)
SELECT
    `weekly_date`.`date`,
    DATE_FORMAT(`weekly_date`.`date`, "%W") AS `day`,
    -- `doctor_appointments`.`doctor_id`,
    `doctor_ids`.`id` AS `doctor_id`,
    `doctor_ids`.`first_name` AS `doctor_first_name`,
    `doctor_ids`.`last_name` AS `doctor_last_name`,
    COALESCE(`doctor_appointments`.`appointment_count`, 0) AS `appointment_count`
FROM `weekly_date`
CROSS JOIN `doctor_ids`
LEFT JOIN `doctor_appointments`
    ON `doctor_appointments`.`appointment_date` = `weekly_date`.`date`
    AND `doctor_appointments`.`doctor_id` = `doctor_ids`.`id`
ORDER BY `weekly_date`.`date`, `doctor_ids`.`id`;

-- what are the appointments for doctor_id = 1 on 2034-09-04?
SELECT *
FROM `appointments`
WHERE
    `doctor_id` = 1 AND
    DATE_FORMAT(`next_appointment_date`, "%Y-%m-%d") = "2024-09-04";


-- insert new treatment into packages
INSERT INTO `packages` (`name`, `frequency`, `cost`)
VALUES ('moxibustion', 5, 400);

-- delete added package
DELETE FROM `packages`
WHERE `name` = 'moxibustion';


-- patient 1
CALL insert_appointment('1', '1', '2024-08-15', NULL, '400.35', 'broken nose', 'rest', 6, '2024-08-15');

-- patient 30
CALL insert_appointment('30', '1', '2024-08-15', NULL, '400.35', 'broken nose', 'rest', 6, NULL);


-- insert workers
-- duplicate identification id
CALL insert_worker('Andrew', 'Tan', 'ID1001', 'male', '1995-04-05', 'andrew@gmail.com',
                        '555-1111', 'Daniel Tan', '555-1234', 'Father', '2024-08-31', NULL, 'Doctor');

-- unique identification id
CALL insert_worker('Andrew', 'Tan', 'ID6666', 'male', '1995-04-05', 'andrew@gmail.com',
                        '555-1111', 'Daniel Tan', '555-1234', 'Father', '2024-08-31', NULL, 'Doctor');

SELECT * FROM workers WHERE `identification_number` = 'ID6666';
