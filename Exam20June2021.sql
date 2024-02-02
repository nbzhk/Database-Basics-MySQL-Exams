CREATE DATABASE `stc`;
USE `stc`;

CREATE TABLE `addresses`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`name` VARCHAR(100) NOT NULL
);

CREATE TABLE `categories`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`name` VARCHAR(10) NOT NULL
);

CREATE TABLE `clients`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`full_name` VARCHAR(50) NOT NULL,
`phone_number` VARCHAR(20) NOT NULL
);

CREATE TABLE `drivers`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`first_name` VARCHAR(30) NOT NULL,
`last_name` VARCHAR(30) NOT NULL,
`age` INT NOT NULL,
`rating` FLOAT DEFAULT 5.5
);

CREATE TABLE `cars`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`make` VARCHAR(20) NOT NULL,
`model` VARCHAR(20),
`year` INT NOT NULL DEFAULT 0,
`mileage` INT DEFAULT 0,
`condition` CHAR(1) NOT NULL,
`category_id` INT NOT NULL,
CONSTRAINT fk_car_category
FOREIGN KEY (`category_id`)
REFERENCES categories(`id`)
);

CREATE TABLE `courses`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`from_address_id` INT NOT NULL,
`start` DATETIME NOT NULL,
`bill` DECIMAL(10,2) DEFAULT 10,
`car_id` INT NOT NULL,
`client_id` INT NOT NULL,
CONSTRAINT fk_course_address
FOREIGN KEY (`from_address_id`)
REFERENCES addresses(`id`),
CONSTRAINT fk_course_car
FOREIGN KEY (`car_id`)
REFERENCES cars(`id`),
CONSTRAINT fk_course_client
FOREIGN KEY (`client_id`)
REFERENCES clients(`id`)
);

CREATE TABLE `cars_drivers`(
`car_id` INT NOT NULL,
`driver_id` INT NOT NULL,
PRIMARY KEY(`car_id`, `driver_id`),
CONSTRAINT fk_car_id
FOREIGN KEY (`car_id`)
REFERENCES cars(`id`),
CONSTRAINT fk_driver_id
FOREIGN KEY (`driver_id`)
REFERENCES drivers(`id`)
);

#02.Insert
INSERT INTO `clients`(`full_name`, `phone_number`)
SELECT CONCAT_WS(' ',`first_name`, `last_name`),
CONCAT('(088) 9999', `id` * 2) FROM `drivers`
WHERE `id` BETWEEN 10 AND 20;

#03. Update
UPDATE `cars`
SET `condition` = 'C'
WHERE `mileage` >= 800000 OR `mileage` IS NULL
AND `year` <= 2010
AND `make` NOT LIKE 'Mercedes-Benz';

#04. Delete
DELETE cl FROM `clients` AS cl
	LEFT JOIN `courses` AS co ON cl.`id` = co.`client_id`
WHERE co.`id` IS NULL AND CHAR_LENGTH(cl.`full_name`) > 3;


#05. Cars
SELECT `make`, `model`, `condition` FROM `cars`
ORDER BY `id`;

#06. Drivers and Cars
SELECT d.`first_name`,
d.`last_name`,
c.`make`,
c.`model`,
c.`mileage`
FROM `drivers` AS d
	JOIN `cars_drivers` AS cd ON cd.`driver_id` = d.`id`
    JOIN `cars` AS c ON c.`id` = cd.`car_id`
WHERE c.`mileage` IS NOT NULL
ORDER BY c.`mileage` DESC, d.`first_name`;

#07. Number of courses
SELECT c.`id` AS 'car_id',
c.`make`,
c.`mileage`,
COUNT(co.`car_id`) AS 'count_of_courses',
ROUND(AVG(co.`bill`), 2) AS 'avg_bill'
FROM `cars` AS c
	LEFT JOIN `courses` AS co ON c.`id` = co.`car_id`
GROUP BY c.`id`
HAVING `count_of_courses` <> 2
ORDER BY `count_of_courses` DESC, `car_id`;

#08. Regular clients
SELECT cl.`full_name`,
COUNT(co.`car_id`) AS 'count_of_cars',
SUM(co.`bill`) AS 'total_sum'
FROM `clients` as cl
	JOIN `courses` AS co ON co.`client_id` = cl.`id`
WHERE cl.`full_name` LIKE '_a%'
GROUP BY cl.`full_name`
HAVING `count_of_cars` > 1
ORDER BY cl.`full_name`;

#09. Full info for courses
SELECT a.`name`,
	(CASE 
		WHEN HOUR(co.`start`) BETWEEN 6 AND 20 THEN 'Day'
		WHEN HOUR(co.`start`) BETWEEN 21 AND 23 
        OR HOUR(co.`start`) BETWEEN 0 AND 5 THEN 'Night'
	END
) AS 'day_time',
co.`bill`,
cl.`full_name`,
c.`make`,
c.`model`,
ca.`name` AS 'category_name'
FROM `courses` AS co
	JOIN `addresses` AS a ON a.`id` = co.`from_address_id`
    JOIN `clients` AS cl ON cl.`id` = co.`client_id`
    JOIN `cars` AS c ON c.`id` = co.`car_id`
    JOIN `categories` AS ca ON ca.`id` = c.`category_id`
ORDER BY co.`id`;

#10. Find all courses by client’s phone number
delimiter %%
CREATE FUNCTION udf_courses_by_client (phone_num VARCHAR (20))
RETURNS INT
DETERMINISTIC
BEGIN
	RETURN (SELECT COUNT(co.`client_id`) FROM `courses` AS co
		JOIN `clients` AS cl ON cl.`id` = co.`client_id`
	WHERE cl.`phone_number` = phone_num);

END%%

#expected 5
SELECT udf_courses_by_client ('(803) 6386812') as `count`; 
# expected 3
SELECT udf_courses_by_client ('(831) 1391236') as `count`;
#expected 0
SELECT udf_courses_by_client ('(704) 2502909') as `count`;


#11. Full info for address
delimiter %%
CREATE PROCEDURE udp_courses_by_address(address_name VARCHAR(100))
BEGIN
	SELECT a.`name`,
    cl.`full_name` AS 'full_names',
    (CASE
		WHEN co.`bill` <= 20 THEN 'Low'
		WHEN co.`bill` <= 30 THEN 'Medium'
		ELSE 'High'
        END
    )  AS 'level_of_bill',
    c.`make`,
    c.`condition`,
    ca.`name` AS 'cat_name'
    FROM `addresses` AS a
		JOIN `courses` AS co ON co.`from_address_id` = a.`id`
		JOIN `clients` AS cl ON cl.`id` = co.`client_id`
		JOIN `cars` AS c ON c.`id` = co.`car_id`
		JOIN `categories` AS ca ON ca.`id` = c.`category_id`
	WHERE a.`name` = address_name
	ORDER BY c.`make`, cl.`full_name`;    
    
END%% 


CALL udp_courses_by_address('66 Thompson Drive');




