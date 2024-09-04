-- reset tables if exists
DROP TABLE IF EXISTS `packages`;
DROP TABLE IF EXISTS `signed_packages`;
DROP TABLE IF EXISTS `appointments`;
DROP TABLE IF EXISTS `workers`;
DROP TABLE IF EXISTS `patients`;

-- reset procedures if exists
DROP PROCEDURE IF EXISTS `insert_worker`;
DROP PROCEDURE IF EXISTS `insert_patient`;
DROP PROCEDURE IF EXISTS `insert_appointment`;
DROP PROCEDURE IF EXISTS `get_package_details`;
DROP PROCEDURE IF EXISTS `get_package_data`;

-- reset views if exists
DROP VIEW IF EXISTS `upcoming_appointments`;
DROP VIEW IF EXISTS `patient_packages`;

-- reset function if exists
DROP FUNCTION IF EXISTS `get_package_limit`;

-- create table to insert all worker details (staff, doctors)
CREATE TABLE `workers` (
    `id` INT UNSIGNED AUTO_INCREMENT,
    `first_name` VARCHAR(255) NOT NULL,
    `last_name` VARCHAR(255) NOT NULL,
    `identification_number` VARCHAR(255) NOT NULL UNIQUE,
    `gender` ENUM('male', 'female', 'others') NOT NULL,
    `birthday` DATE NOT NULL,
    `email` VARCHAR(255),
    `contact_number` VARCHAR(255) NOT NULL,
    `emergency_person` TEXT NOT NULL,
    `emergency_number` VARCHAR(255) NOT NULL,
    `relationship` VARCHAR(255) NOT NULL,
    `join_date` DATE NOT NULL,
    `leave_date` DATE,
    `role` ENUM('Doctor', 'Staff') NOT NULL,
    PRIMARY KEY(`id`)
);

-- create table to insert patient details (only patients with valid visitations)
CREATE TABLE `patients` (
    `id` INT UNSIGNED AUTO_INCREMENT,
    `first_name` VARCHAR(255) NOT NULL,
    `last_name` VARCHAR(255) NOT NULL,
    `identification_number` VARCHAR(255) NOT NULL UNIQUE,
    `gender` ENUM('male', 'female', 'others') NOT NULL,
    `birthday` DATE NOT NULL,
    `email` VARCHAR(255),
    `contact_number` VARCHAR(255) NOT NULL,
    `emergency_person` TEXT NOT NULL,
    `emergency_number` VARCHAR(255) NOT NULL,
    `relationship` VARCHAR(255) NOT NULL,
    PRIMARY KEY(`id`)
);


-- create table to show what are the available packages
CREATE TABLE `packages` (
    `id` INT UNSIGNED AUTO_INCREMENT,
    `name` VARCHAR(50) NOT NULL,
    `frequency` TINYINT UNSIGNED NOT NULL,
    `cost(RM)` INT NOT NULL,
    PRIMARY KEY(`id`)
);


-- create table to handle each appointments of the patient with a doctor
-- patients may optionally undergo 1 treatment as selected from the "packages" table
CREATE TABLE `appointments` (
    `id` INT UNSIGNED AUTO_INCREMENT,
    `patient_id` INT UNSIGNED,
    `doctor_id` INT UNSIGNED,
    `appointment_date` DATETIME NOT NULL,
    `next_appointment_date` DATETIME,
    `amount_paid` DECIMAL(7,2) NOT NULL,
    `diagnosis` TEXT NOT NULL,
    `remark` TEXT NOT NULL,
    `package_id` INT UNSIGNED DEFAULT NULL,
    `package_payment_date` DATE DEFAULT NULL,
    PRIMARY KEY(`id`),
    UNIQUE (`patient_id`, `appointment_date`),
    FOREIGN KEY(`patient_id`) REFERENCES `patients`(`id`) ON DELETE CASCADE,
    FOREIGN KEY(`doctor_id`) REFERENCES `workers`(`id`) ON DELETE CASCADE,
    FOREIGN KEY(`package_id`) REFERENCES `packages`(`id`) ON DELETE CASCADE
);



-- create view to show each patient's package details
-- details include patient's current package usage balance. including package payment date
-- serves as a main table to determine if patient has paid for the package before starting a new cycle after the limit has reached
CREATE VIEW `patient_packages` AS
WITH `CTE` AS (
	SELECT `appointments`.`patient_id`,
            `appointments`.`package_id`,
            `appointments`.`package_payment_date`,
	        RANK() OVER(PARTITION BY `patient_id`, `package_id` ORDER BY `appointment_date` ASC) AS 'ranking',
	        ROW_NUMBER() OVER (PARTITION BY `patient_id`, `package_id` ORDER BY `appointment_date`) AS 'row_num',
            `packages`.`frequency`
	FROM `appointments`
    JOIN `packages` ON `appointments`.`package_id` = `packages`.`id`
)
SELECT `patient_id`,
        `package_id`,
        `frequency` AS `package_limit`,
        COUNT(`package_id`) AS 'current_package_count',
        `frequency` - COUNT(`package_id`) AS `remaining_count`,
        MIN(`package_payment_date`) AS 'package_payment_date',
        FLOOR((`row_num` -1) / `frequency`) + 1 AS 'grouping'
FROM `CTE`
GROUP BY `patient_id`, `package_id`, FLOOR((`row_num` -1) / `frequency`) + 1;

-- create view to view all upcoming appointments based on the "next_appointment_date" from the "appointments" table
-- user may find all upcoming appointments N days from today. Where N >= 0
-- clinic staff can use this table to find all appointments for the day
CREATE VIEW `upcoming_appointments` AS
SELECT
    `patients`.`id` AS 'patient_id',
    `patients`.`last_name` AS 'patient_last_name',
    `patients`.`first_name` AS 'patient_first_name',
    `patients`.`contact_number` AS 'patient_contact_number',
    `patients`.`email` AS 'patient_email',
    `appointments`.`next_appointment_date`,
    DATEDIFF(`appointments`.`next_appointment_date`, NOW()) AS 'days_to_appointment',
    `workers`.`id` AS `doctor_id`,
    `workers`.`last_name` AS 'doctor_last_name',
    `workers`.`first_name` AS 'doctor_first_name'
FROM `appointments`
JOIN `patients` ON `patients`.`id` = `appointments`.`patient_id`
JOIN `workers` on `workers`.`id` = `appointments`.`doctor_id`
WHERE `next_appointment_date` > NOW()
ORDER BY `days_to_appointment`;


-- create function to get treatment frequency limit from packages table
DELIMITER //
CREATE FUNCTION get_package_limit(
    `package_id` INT
)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE package_limit INT;

    SELECT frequency INTO package_limit
    FROM packages WHERE id = package_id;

    RETURN package_limit;
END //
DELIMITER ;

-- procedure to get what is the package count that has been utilized by patient
-- used to determine if new entry is allowed to be inserted into the appointments table
delimiter //
CREATE PROCEDURE get_package_details(
    IN `p_patient_id` INT,
    IN `p_package_id` INT,
    OUT `p_package_count` INT,
    OUT `p_last_package_payment_date` DATE
)
BEGIN
    SELECT `current_package_count`, `package_payment_date` INTO `p_package_count`, `p_last_package_payment_date`
    FROM `patient_packages`
    WHERE `grouping` =
        (
            SELECT MAX(`grouping`)
            FROM `patient_packages`
            WHERE `package_id` = `p_package_id` AND `patient_id` = `p_patient_id`
            GROUP BY `patient_id`, `package_id`
        )
        AND `patient_id` = `p_patient_id` AND `package_id` = `p_package_id`
    ;
END //
delimiter ;


-- procedure to insert new worker details through CALL insert_worker()
delimiter //
CREATE PROCEDURE `insert_worker`(
    IN `first_name` VARCHAR(255),
    IN `last_name` VARCHAR(255),
    IN `identification_number` VARCHAR(255),
    IN `gender` ENUM('male', 'female', 'others'),
    IN `birthday` DATE,
    IN `email` VARCHAR(255),
    IN `contact_number` VARCHAR(255),
    IN `emergency_person` VARCHAR(255),
    IN `emergency_number` VARCHAR(255),
    IN `relationship` VARCHAR(255) ,
    IN `join_date` DATE,
    IN `leave_date` DATE,
    IN `role` ENUM('Doctor', 'Staff')
)
BEGIN

    SET @first_name = `first_name`;
    SET @last_name = `last_name`;
    SET @identification_number = `identification_number`;
    SET @gender = `gender`;
    SET @birthday = `birthday`;
    SET @email = `email`;
    SET @contact_number = `contact_number`;
    SET @emergency_person = `emergency_person`;
    SET @emergency_number = `emergency_number`;
    SET @relationship = `relationship`;
    SET @join_date = `join_date`;
    SET @leave_date = `leave_date`;
    SET @role = `role`;

    SET @query = 'INSERT INTO `workers` (`first_name`, `last_name`, `identification_number`, `gender`, `birthday`,
                        `email`, `contact_number`,
                        `emergency_person`, `emergency_number`, `relationship`,
                        `join_date`, `leave_date`, `role`)
                VALUES(?, ?, ?, ?, ?,
                        ?, ?,
                        ?, ?, ?,
                        ?, ?, ?)';

    PREPARE stmt FROM @query;
    EXECUTE stmt USING @first_name, @last_name, @identification_number, @gender, @birthday,
                        @email, @contact_number,
                        @emergency_person, @emergency_number, @relationship,
                        @join_date, @leave_date, @role;

END //
delimiter ;

-- procedure to insert new patients' details through CALL insert_patient()
delimiter //
CREATE PROCEDURE `insert_patient` (
    IN `first_name` VARCHAR(255),
    IN `last_name` VARCHAR(255),
    IN `identification_number` VARCHAR(255),
    IN `gender` ENUM('male', 'female', 'others'),
    IN `birthday` DATE,
    IN `email` VARCHAR(255),
    IN `contact_number` VARCHAR(255),
    IN `emergency_person` VARCHAR(255),
    IN `emergency_number` VARCHAR(255),
    IN `relationship` VARCHAR(255)
)
BEGIN

    SET @first_name = `first_name`;
    SET @last_name = `last_name`;
    SET @identification_number = `identification_number`;
    SET @gender = `gender`;
    SET @birthday = `birthday`;
    SET @email = `email`;
    SET @contact_number = `contact_number`;
    SET @emergency_person = `emergency_person`;
    SET @emergency_number = `emergency_number`;
    SET @relationship = `relationship`;

    SET @query = 'INSERT INTO `patients` (`first_name`, `last_name`, `identification_number`, `gender`, `birthday`,
                        `email`, `contact_number`,
                        `emergency_person`, `emergency_number`, `relationship`)
                VALUES(?, ?, ?, ?, ?,
                        ?, ?,
                        ?, ?, ?)';

    PREPARE stmt FROM @query;
    EXECUTE stmt USING @first_name, @last_name, @identification_number, @gender, @birthday,
                        @email, @contact_number,
                        @emergency_person, @emergency_number, @relationship;

END //
delimiter ;


-- procedure to insert new apppointment details through CALL insert_appointment()
-- whenever a new entry is being inserted AND a package_id is provided,
-- the get_package_details() will be called to return what is the current status of the patient's package
-- before determining if this new entry is allowed to be inserted into the table
delimiter //
CREATE PROCEDURE `insert_appointment` (
    IN `patient_id` INT UNSIGNED,
    IN `doctor_id` INT UNSIGNED,
    IN `appointment_date` DATETIME,
    IN `next_appointment_date` DATETIME,
    IN `amount_paid` DECIMAL(7,2),
    IN `diagnosis` TEXT,
    IN `remark` TEXT,
    IN `package_id` INT UNSIGNED,
    IN `package_payment_date` DATE
)
BEGIN
    DECLARE package_limit INT;
    DECLARE current_package_count INT;
    DECLARE last_package_payment_date DATE;

    -- based on provided package id, find the limit from "packages" table
    SET package_limit = get_package_limit(package_id);

    -- check from "patient_packages" views and get the count of the package
    CALL get_package_details(patient_id, package_id, current_package_count, last_package_payment_date);

    -- conditions to check whether a new appointment entry is allowed to be inserted
    -- stop the execution if condition is not met
    IF current_package_count >= package_limit AND package_payment_date IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Package limit exceeded. Remind customer to renew package';

    ELSEIF current_package_count IS NULL AND package_payment_date IS NULL AND package_id IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'New package detected. Remind customer to pay before proceeding';

    ELSEIF current_package_count < package_limit AND package_payment_date IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Customer paid for existing package. Ensure no double-charged';

    ELSE
        SET @patient_id = `patient_id`;
        SET @doctor_id = `doctor_id`;
        SET @appointment_date = `appointment_date`;
        SET @next_appointment_date = `next_appointment_date`;
        SET @amount_paid = `amount_paid`;
        SET @diagnosis = `diagnosis`;
        SET @remark = `remark`;
        SET @package_id = `package_id`;
        SET @package_payment_date = `package_payment_date`;
        SET @query = '
                    INSERT INTO `appointments` (`patient_id`, `doctor_id`, `appointment_date`, `next_appointment_date`,
                                                    `amount_paid`, `diagnosis`, `remark`, `package_id`, `package_payment_date`)
                    VALUES (?, ?, ?, ?,
                            ?, ?, ?, ?, ?)
                    ';

        PREPARE stmt FROM @query;
        EXECUTE stmt USING @patient_id, @doctor_id, @appointment_date, @next_appointment_date,
                            @amount_paid, @diagnosis, @remark, @package_id, @package_payment_date;
    END IF;

END //
delimiter ;


-- insert sample data
-- workers
INSERT INTO `workers` (
    `first_name`, `last_name`, `identification_number`, `gender`, `email`, `birthday`, `contact_number`, `emergency_person`, `emergency_number`, `relationship`, `join_date`, `leave_date`, `role`
) VALUES
    ('Ahmad', 'Ismail', 'ID1001', 'male', 'ahmad.ismail@example.com', '1979-04-14', '555-1111', 'Siti Ismail', '555-2111', 'Sister', '2010-01-10', NULL, 'Doctor'),
    ('Siti', 'Aminah', 'ID1002', 'female', 'siti.aminah@example.com', '1986-03-21', '555-2222', 'Ahmad Aminah', '555-3222', 'Brother', '2012-05-15', NULL, 'Staff'),
    ('Lim', 'Wei', 'ID1003', 'male', 'lim.wei@example.com', '1973-06-10', '555-3333', 'Ching Wei', '555-4333', 'Wife', '2008-09-25', NULL, 'Doctor'),
    ('Tan', 'Mei Ling', 'ID1004', 'female', 'tan.meiling@example.com', '1982-09-05', '555-4444', 'Tan Boon Ling', '555-5444', 'Husband', '2015-03-18', NULL, 'Staff'),
    ('Ravi', 'Kumar', 'ID1005', 'male', 'ravi.kumar@example.com', '1986-12-15', '555-5555', 'Lakshmi Kumar', '555-6555', 'Wife', '2011-11-11', NULL, 'Doctor'),
    ('Anjali', 'Devi', 'ID1006', 'female', 'anjali.devi@example.com', '1994-01-19', '555-6666', 'Ravi Devi', '555-7666', 'Husband', '2017-07-07', NULL, 'Staff'),
    ('Hassan', 'Ali', 'ID1007', 'male', 'hassan.ali@example.com', '1989-08-11', '555-7777', 'Aishah Ali', '555-8777', 'Mother', '2013-05-20', '2022-12-31', 'Doctor'),
    ('Farah', 'Hussein', 'ID1008', 'female', 'farah.hussein@example.com', '1995-11-08', '555-8888', 'Hassan Hussein', '555-9888', 'Father', '2018-06-15', NULL, 'Staff'),
    ('Chen', 'Wei', 'ID1009', 'male', 'chen.wei@example.com', '1976-05-25', '555-9999', 'Liu Wei', '555-1099', 'Wife', '2009-04-10', NULL, 'Doctor'),
    ('Liu', 'Ming', 'ID1010', 'female', 'liu.ming@example.com', '1990-02-18', '555-1010', 'Chen Ming', '555-1110', 'Husband', '2020-01-01', NULL, 'Staff');


-- patients
INSERT INTO `patients` (
    `first_name`, `last_name`, `identification_number`, `gender`, `email`, `birthday`, `contact_number`, `emergency_person`, `emergency_number`, `relationship`
) VALUES
    ('Ahmad', 'Ismail', 'ID998877001', 'male', 'ahmad.ismail@example.com', '1990-04-14', '555-1111', 'Siti Ismail', '555-2111', 'Sister'),
    ('Siti', 'Aminah', 'ID998877002', 'female', 'siti.aminah@example.com', '1994-03-21', '555-2222', 'Ahmad Aminah', '555-3222', 'Brother'),
    ('Lim', 'Wei', 'ID998877003', 'male', 'lim.wei@example.com', '1983-06-10', '555-3333', 'Ching Wei', '555-4333', 'Wife'),
    ('Tan', 'Mei Ling', 'ID998877004', 'female', 'tan.meiling@example.com', '1988-09-05', '555-4444', 'Tan Boon Ling', '555-5444', 'Husband'),
    ('Ravi', 'Kumar', 'ID998877005', 'male', 'ravi.kumar@example.com', '1981-12-15', '555-5555', 'Lakshmi Kumar', '555-6555', 'Wife'),
    ('Anjali', 'Devi', 'ID998877006', 'female', 'anjali.devi@example.com', '1993-01-19', '555-6666', 'Ravi Devi', '555-7666', 'Husband'),
    ('Hassan', 'Ali', 'ID998877007', 'male', 'hassan.ali@example.com', '1995-08-11', '555-7777', 'Aishah Ali', '555-8777', 'Mother'),
    ('Farah', 'Hussein', 'ID998877008', 'female', 'farah.hussein@example.com', '1997-11-08', '555-8888', 'Hassan Hussein', '555-9888', 'Father'),
    ('Chen', 'Wei', 'ID998877009', 'male', 'chen.wei@example.com', '1973-05-25', '555-9999', 'Liu Wei', '555-1099', 'Wife'),
    ('Liu', 'Ming', 'ID998877010', 'female', 'liu.ming@example.com', '1978-02-18', '555-1010', 'Chen Ming', '555-1110', 'Husband'),
    ('Suresh', 'Nair', 'ID998877011', 'male', 'suresh.nair@example.com', '1989-04-22', '555-1212', 'Priya Nair', '555-1312', 'Wife'),
    ('Priya', 'Nair', 'ID998877012', 'female', 'priya.nair@example.com', '1991-07-11', '555-1414', 'Suresh Nair', '555-1514', 'Husband'),
    ('Abu', 'Bakar', 'ID998877013', 'male', 'abu.bakar@example.com', '1992-03-30', '555-1616', 'Fatimah Bakar', '555-1716', 'Wife'),
    ('Fatimah', 'Bakar', 'ID998877014', 'female', 'fatimah.bakar@example.com', '1994-06-27', '555-1818', 'Abu Bakar', '555-1918', 'Husband'),
    ('Wong', 'Li', 'ID998877015', 'male', 'wong.li@example.com', '1985-01-09', '555-2020', 'Cheng Li', '555-2120', 'Wife'),
    ('Cheng', 'Ying', 'ID998877016', 'female', 'cheng.ying@example.com', '1987-03-03', '555-2222', 'Wong Ying', '555-2322', 'Husband'),
    ('Rajesh', 'Patel', 'ID998877017', 'male', 'rajesh.patel@example.com', '1986-08-24', '555-2424', 'Anita Patel', '555-2524', 'Wife'),
    ('Anita', 'Patel', 'ID998877018', 'female', 'anita.patel@example.com', '1988-02-07', '555-2626', 'Rajesh Patel', '555-2726', 'Husband'),
    ('Yusof', 'Ishak', 'ID998877019', 'male', 'yusof.ishak@example.com', '1991-04-20', '555-2828', 'Nur Ishak', '555-2928', 'Wife'),
    ('Nur', 'Aisha', 'ID998877020', 'female', 'nur.aisha@example.com', '1993-12-15', '555-3030', 'Yusof Aisha', '555-3130', 'Husband'),
    ('Kumar', 'Raj', 'ID998877021', 'male', 'kumar.raj@example.com', '1979-08-25', '555-3131', 'Priya Raj', '555-3231', 'Wife'),
    ('Aishah', 'Abdullah', 'ID998877022', 'female', 'aishah.abdullah@example.com', '1986-05-12', '555-3333', 'Abdullah Ahmad', '555-3433', 'Husband'),
    ('Li', 'Xiao', 'ID998877023', 'male', 'li.xiao@example.com', '1994-02-18', '555-3535', 'Wang Xiao', '555-3635', 'Wife'),
    ('Suresh', 'Menon', 'ID998877024', 'male', 'suresh.menon@example.com', '1982-11-30', '555-3737', 'Priya Menon', '555-3837', 'Wife'),
    ('Jasbir', 'Kaur', 'ID998877025', 'female', 'jasbir.kaur@example.com', '1973-04-15', '555-3939', 'Gurmeet Kaur', '555-4039', 'Husband'),
    ('Wei', 'Jie', 'ID998877026', 'male', 'wei.jie@example.com', '1992-09-10', '555-4141', 'Zhang Jie', '555-4241', 'Wife'),
    ('Vijay', 'Patel', 'ID998877027', 'male', 'vijay.patel@example.com', '1996-03-22', '555-4343', 'Neha Patel', '555-4443', 'Wife'),
    ('Jenny', 'Tan', 'ID998877028', 'female', 'jenny.tan@example.com', '1988-07-07', '555-4545', 'Steven Tan', '555-4645', 'Husband'),
    ('Rahim', 'Salleh', 'ID998877029', 'male', 'rahim.salleh@example.com', '1991-12-18', '555-4747', 'Nor Salleh', '555-4847', 'Wife'),
    ('Xiao', 'Yun', 'ID998877030', 'female', 'xiao.yun@example.com', '1993-10-05', '555-4949', 'Wang Yun', '555-5050', 'Husband');


INSERT INTO `packages` (`name`, `frequency`, `cost(RM)`)
VALUES
    ('acupuncture', 10, 1000),
    ('cupping', 10, 800),
    ('bone setting', 8, 1200),
    ('beauty', 5, 600),
    ('massage', 7, 450),
    ('guasha', 3, 750);


-- index created to optimize searching with names and appointment dates
CREATE INDEX `patient_names` ON
`patients` (`first_name`, `last_name`);

CREATE INDEX `worker_names` ON
`workers` (`first_name`, `last_name`);

CREATE INDEX `appointment_dates` ON
`appointments` (`appointment_date`);

CREATE INDEX `next_appointment_dates` ON
`appointments` (`next_appointment_date`);
