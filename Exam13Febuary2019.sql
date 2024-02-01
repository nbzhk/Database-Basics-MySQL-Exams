CREATE DATABASE `online_store`;
USE `online_store`;

CREATE TABLE `brands` (
`id` INT PRIMARY KEY AUTO_INCREMENT,
`name` VARCHAR(40) NOT NULL UNIQUE
);

CREATE TABLE `categories` (
`id` INT PRIMARY KEY AUTO_INCREMENT,
`name` VARCHAR(40) NOT NULL UNIQUE
);

CREATE TABLE `reviews` (
`id` INT PRIMARY KEY AUTO_INCREMENT,
`content` TEXT,
`rating` DECIMAL(10,2) NOT NULL,
`picture_url` VARCHAR(80) NOT NULL,
`published_at` DATETIME NOT NULL
);

CREATE TABLE `products` (
`id` INT PRIMARY KEY AUTO_INCREMENT,
`name` VARCHAR(40) NOT NULL,
`price` DECIMAL(19,2) NOT NULL,
`quantity_in_stock` INT,
`description` TEXT,
`brand_id` INT NOT NULL,
`category_id` INT NOT NULL,
`review_id` INT,
CONSTRAINT fk_product_brand
FOREIGN KEY (`brand_id`)
REFERENCES `brands`(`id`),
CONSTRAINT fk_product_category
FOREIGN KEY (`category_id`)
REFERENCES `categories`(`id`),
CONSTRAINT fk_product_review
FOREIGN KEY (`review_id`)
REFERENCES `reviews`(`id`)
);

CREATE TABLE `customers` (
`id` INT PRIMARY KEY AUTO_INCREMENT,
`first_name` VARCHAR(20) NOT NULL,
`last_name` VARCHAR(20) NOT NULL,
`phone` VARCHAR(30) NOT NULL UNIQUE,
`address` VARCHAR(60) NOT NULL,
`discount_card` BIT(1) NOT NULL DEFAULT 0
);

CREATE TABLE `orders` (
`id` INT PRIMARY KEY AUTO_INCREMENT,
`order_datetime` DATETIME NOT NULL,
`customer_id` INT NOT NULL,
CONSTRAINT fk_order_customer
FOREIGN KEY (`customer_id`)
REFERENCES `customers`(`id`)
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


#01.Insert
INSERT INTO `reviews`(`content`, `picture_url`, `published_at`, `rating`)
SELECT 
SUBSTRING(`description`, 1, 15),
REVERSE(`name`),
'2010-10-10',
`price` / 8
FROM `products`
WHERE `id` >= 5;

#03. Update
UPDATE `products`
SET `quantity_in_stock` = `quantity_in_stock` - 5
WHERE `quantity_in_stock` BETWEEN 60 AND 70;

#04. Delete
DELETE c FROM `customers` AS c
	LEFT JOIN `orders` AS o ON  o.`customer_id` = c.`id`
WHERE o.`customer_id` IS NULL;

#05. Categories
SELECT * FROM `categories`
ORDER BY `name` DESC;

#06. Quantity
SELECT `id`, `brand_id`, `name`, `quantity_in_stock` FROM `products`
WHERE `price` > 1000 AND `quantity_in_stock` < 30
ORDER BY `quantity_in_stock`, `id`;

#07. Review
SELECT * FROM `reviews`
WHERE `content` LIKE 'My%' AND CHAR_LENGTH(`content`) > 61
ORDER BY `rating` DESC;

#08. First customers
SELECT CONCAT_WS(' ', c.`first_name`, c.`last_name`) AS 'full_name',
c.`address`, o.`order_datetime` FROM `customers` AS c
	JOIN `orders` AS o ON o.`customer_id` = c.`id`
WHERE YEAR(o.`order_datetime`) <= 2018
ORDER BY `full_name` DESC;

#09. Best categories
SELECT COUNT(p.`id`) AS 'items_count',
c.`name`,
SUM(p.`quantity_in_stock`) AS 'total_quantity'
FROM `products` AS p
	JOIN `categories` AS c ON c.`id` = p.`category_id`
GROUP BY c.`name`
ORDER BY `items_count` DESC, `total_quantity`
LIMIT 5;

#10. Extract client cards count
delimiter %%
CREATE FUNCTION udf_customer_products_count(name VARCHAR(30))
RETURNS INT
DETERMINISTIC
BEGIN
	RETURN (SELECT COUNT(op.`order_id`) FROM `orders_products` AS op
		JOIN `orders` AS o ON o.`id` = op.`order_id`
        JOIN `customers` AS c ON c.`id` = o.`customer_id`
	WHERE c.`first_name` = name);
END%% 

SELECT c.first_name,c.last_name, udf_customer_products_count('Shirley') as `total_products` FROM customers c
WHERE c.first_name = 'Shirley';

#11. Reduce price
delimiter %%
CREATE PROCEDURE udp_reduce_price(category_name VARCHAR(50))
BEGIN
	
	UPDATE `products` AS p
		JOIN `reviews` AS r ON r.`id` = p.`review_id`
		JOIN `categories` AS c ON c.`name` = category_name
    SET `price` = `price` * 0.7
    WHERE r.`rating` < 4;
    
END%%




