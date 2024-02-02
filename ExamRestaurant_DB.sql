CREATE DATABASE `restaurant_db`;
USE `restaurant_db`;

CREATE TABLE `products`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`name` VARCHAR(30) NOT NULL UNIQUE,
`type` VARCHAR(30) NOT NULL,
`price` DECIMAL(10,2) NOT NULL
);

CREATE TABLE `clients`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`first_name` VARCHAR(50) NOT NULL,
`last_name` VARCHAR(50) NOT NULL,
`birthdate` DATE NOT NULL,
`card` VARCHAR(50),
`review` TEXT
);

CREATE TABLE `tables`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`floor` INT NOT NULL,
`reserved` TINYINT(1),
`capacity` INT NOT NULL
);

CREATE TABLE `waiters`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`first_name` VARCHAR(50) NOT NULL,
`last_name` VARCHAR(50) NOT NULL,
`email` VARCHAR(50) NOT NULL,
`phone` VARCHAR(50),
`salary` DECIMAL(10,2)
);

CREATE TABLE `orders`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`table_id` INT NOT NULL,
`waiter_id` INT NOT NULL,
`order_time` TIME NOT NULL,
`payed_status` TINYINT(1),
CONSTRAINT fk_table
FOREIGN KEY (`table_id`)
REFERENCES `tables`(`id`),
CONSTRAINT fk_waiter
FOREIGN KEY (`waiter_id`)
REFERENCES `waiters`(`id`)
);

CREATE TABLE `orders_clients`(
`order_id` INT,
`client_id` INT,
CONSTRAINT fk_order_to_client
FOREIGN KEY (`order_id`)
REFERENCES `orders`(`id`),
CONSTRAINT fk_client_to_order
FOREIGN KEY (`client_id`)
REFERENCES `clients`(`id`)
);

CREATE TABLE `orders_products`(
`order_id` INT,
`product_id` INT,
CONSTRAINT fk_order_to_product
FOREIGN KEY (`order_id`)
REFERENCES `orders`(`id`),
CONSTRAINT fk_product_to_order
FOREIGN KEY (`product_id`)
REFERENCES `products`(`id`)
);

#2.INSERT
INSERT INTO `products`(`name`, `type`, `price`)
SELECT CONCAT_WS(' ', `last_name`, 'specialty'),
'Cocktail',
CEIL(`salary` * 0.01)
FROM `waiters`
WHERE `id` > 6;

#03. Update
UPDATE `orders`
SET `table_id` = `table_id` - 1
WHERE `id` >= 12 AND `id` <= 23;

#04. Delete
DELETE w FROM `waiters` AS w
LEFT JOIN `orders` AS o ON o.`waiter_id` = w.`id`
WHERE `waiter_id` IS NULL;

#05. Clients
SELECT * FROM `clients`
ORDER BY `birthdate` DESC, `id` DESC;

#06. Birthdate
SELECT `first_name`, `last_name`, `birthdate`, `review` FROM `clients`
WHERE `card` IS NULL AND YEAR(`birthdate`) >= 1978 AND YEAR(`birthdate`) <= 1993
ORDER BY `last_name` DESC, `id`
LIMIT 5;

#07. Accounts
SELECT 
CONCAT(`last_name`,`first_name`,CHAR_LENGTH(`first_name`), 'Restaurant') AS 'username',
REVERSE(SUBSTR(`email`, 2, 12)) AS 'password'
FROM `waiters`
WHERE `salary` IS NOT NULL
ORDER BY `password` DESC;

#08. Top from menu
SELECT p.`id`, p.`name`, COUNT(op.`product_id`) AS 'count' FROM `products` AS p
JOIN `orders_products` AS op ON p.`id` = op.`product_id`
GROUP BY op.`product_id`
HAVING `count` >= 5
ORDER BY `count` DESC, `name`;

#09. Availability
SELECT o.`table_id`,
 t.`capacity`,
 COUNT(oc.`client_id`) AS 'count_clients',
	(CASE
		WHEN `capacity` > COUNT(oc.`client_id`) THEN 'Free seats'
		WHEN `capacity` = COUNT(oc.`client_id`) THEN 'Full'
		WHEN `capacity` < COUNT(oc.`client_id`) THEN 'Extra seats'
	END
	) AS 'availability'
FROM `orders` AS o
	JOIN `tables` AS t ON t.`id` = o.`table_id`
    JOIN `orders_clients` AS oc ON oc.`order_id` = o.`id`
WHERE t.`floor` = 1
GROUP BY `table_id`
ORDER BY o.`table_id` DESC;

#10. Extract bill
delimiter %%
CREATE FUNCTION udf_client_bill(full_name VARCHAR(50))
RETURNS DECIMAL(19,2)
DETERMINISTIC
BEGIN
	DECLARE first_name VARCHAR(50);
	DECLARE last_name VARCHAR(50);
    DECLARE bill DECIMAL(19,2);
	
	SET first_name = SUBSTRING_INDEX(full_name, ' ', 1);
	SET last_name = SUBSTRING_INDEX(full_name, ' ', -1);
	
    
    SET bill := (SELECT SUM(p.`price`) AS 'bill' FROM `products` AS p
					JOIN `orders_products` AS op ON op.`product_id` = p.`id`
					JOIN `orders` AS o ON o.`id` = op.`order_id`
					JOIN `orders_clients` AS oc ON oc.`order_id` = o.`id`
					JOIN `clients` AS c ON oc.`client_id` = c.`id`
				WHERE c.`first_name` = first_name AND c.`last_name` = last_name
				GROUP BY c.`id`
                    );
                    
	RETURN bill;

END %%

SELECT c.first_name,c.last_name, udf_client_bill('Silvio Blyth') as 'bill' FROM clients c
WHERE c.first_name = 'Silvio' AND c.last_name= 'Blyth';

#11. Happy hour
delimiter %%
CREATE PROCEDURE udp_happy_hour(product_type VARCHAR(50))
BEGIN
	UPDATE `products`
    SET `price` = `price` * 0.8
    WHERE `type` = product_type AND `price` >= 10;

END %% 


