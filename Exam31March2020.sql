CREATE DATABASE `instd`;
USE `instd`;

CREATE TABLE `users`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`username` VARCHAR(30) NOT NULL UNIQUE,
`password` VARCHAR(30) NOT NULL, 
`email` VARCHAR(50) NOT NULL, 
`gender` CHAR(1) NOT NULL,
`age` INT NOT NULL,
`job_title` VARCHAR(40) NOT NULL,
`ip` VARCHAR(30) NOT NULL
);

CREATE TABLE `addresses`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`address` VARCHAR(30) NOT NULL,
`town` VARCHAR(30) NOT NULL,
`country` VARCHAR(30) NOT NULL,
`user_id` INT NOT NULL,
CONSTRAINT fk_user_address
FOREIGN KEY (`user_id`)
REFERENCES `users`(`id`)
);

CREATE TABLE `photos`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`description` TEXT NOT NULL,
`date` DATETIME NOT NULL,
`views` INT NOT NULL DEFAULT 0
);

CREATE TABLE `comments`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`comment` VARCHAR(255) NOT NULL,
`date` DATETIME NOT NULL,
`photo_id` INT NOT NULL,
CONSTRAINT fk_comment_photo
FOREIGN KEY (`photo_id`)
REFERENCES `photos`(`id`)
);

CREATE TABLE `users_photos`(
`user_id` INT NOT NULL,
`photo_id` INT NOT NULL,
CONSTRAINT fk_user_id
FOREIGN KEY (`user_id`)
REFERENCES `users`(`id`),
CONSTRAINT fk_photo_id
FOREIGN KEY (`photo_id`)
REFERENCES `photos`(`id`)
);

CREATE TABLE `likes`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`photo_id` INT,
`user_id` INT,
CONSTRAINT fk_like_photo
FOREIGN KEY (`photo_id`)
REFERENCES `photos`(`id`),
CONSTRAINT fk_like_user
FOREIGN KEY (`user_id`)
REFERENCES `users`(`id`)
);

#02. Insert
INSERT INTO `addresses`(`address`, `town`, `country`, `user_id`)
SELECT `username`, `password`, `ip`, `age` FROM `users` AS u
WHERE u.`gender` = 'M';

#03.UPDATE
UPDATE `addresses`
SET `country` = (CASE 
				WHEN LEFT(`country`, 1) = 'B' THEN 'Blocked'
				WHEN LEFT(`country`, 1) = 'T' THEN 'Test'
				WHEN LEFT(`country`, 1) = 'P' THEN 'In Progress'
                END
)
WHERE LEFT(`country`, 1) IN ('B', 'T', 'P');

#04. Delete
DELETE a FROM `addresses` AS a
WHERE a.`id` % 3 = 0;

#05. Users
SELECT `username`, `gender`, `age` FROM `users`
ORDER BY `age` DESC, `username`;

#06. Extract 5 most commented photos
SELECT p.`id`,
 p.`date` AS 'date_and_time', 
 p.`description`,
 COUNT(c.`photo_id`) AS 'commentsCount'
 FROM `photos` AS p
 JOIN `comments` AS c ON c.`photo_id` = p.`id`
 GROUP BY p.`id`
 ORDER BY `commentsCount` DESC, p.`id`
 LIMIT 5;

#07. Lucky users
SELECT CONCAT(u.`id`, ' ', u.`username`) AS 'id_username',
u.`email` 
FROM `users` AS u
	JOIN `users_photos` AS up ON up.`user_id` = u.`id`
WHERE up.`photo_id` = u.`id`
ORDER BY u.`id`;

#08. Count likes and comments
SELECT p.`id` AS 'photo_id',
COUNT(DISTINCT l.`user_id`) AS 'likes_count',
COUNT(DISTINCT c.`id`) AS 'comments_count'
FROM `photos` AS p
	LEFT JOIN `likes` AS l ON p.`id` = l.`photo_id`
	LEFT JOIN `comments` AS c ON p.`id` = c.`photo_id`
GROUP BY `photo_id`
ORDER BY `likes_count` DESC, `comments_count` DESC, p.`id`;

#08.1
SELECT p.`id` AS 'photo_id',
COUNT(DISTINCT l.`id`) AS 'likes_count',
COUNT(DISTINCT c.`comment`) AS 'comments_count'
FROM `photos` AS p
	LEFT JOIN `likes` AS l ON l.`photo_id` = p.`id`
	LEFT JOIN `comments` AS c ON c.`photo_id` = p.`id`
GROUP BY p.`id`
ORDER BY `likes_count` DESC, `comments_count` DESC, p.`id`;



#09. The photo on the tenth day of the month
SELECT CONCAT(SUBSTR(`description`, 1, 30), '...') AS 'summary',
`date`
FROM `photos`
WHERE DAY(`date`) = 10
ORDER BY `date` DESC;

#10. Get user’s photos count
delimiter %%
CREATE FUNCTION udf_users_photos_count(username VARCHAR(30))
RETURNS INT
DETERMINISTIC
BEGIN
	DECLARE photosCount INT;
    SET photosCount := (SELECT COUNT(up.`user_id`) FROM `users_photos` AS up
		JOIN `users` AS u ON u.`id` = up.`user_id`
	WHERE u.`username` = username);
    
    RETURN photosCount;
END%%

#11. Increase user age
delimiter %%
CREATE PROCEDURE udp_modify_user(address VARCHAR(30), town VARCHAR(30))
BEGIN
	UPDATE `users` AS u
    JOIN `addresses` AS a
    SET `age` = `age` + 10
    WHERE a.`address` = address 
    AND a.`town` = town 
    AND a.`user_id` = u.`id`;
END%%
