CREATE DATABASE `fsd`;
USE `fsd`;

CREATE TABLE `countries`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`name` VARCHAR(45) NOT NULL
);

CREATE TABLE `towns`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`name` VARCHAR(45) NOT NULL,
`country_id` INT NOT NULL,
CONSTRAINT fk_town_country
FOREIGN KEY (`country_id`)
REFERENCES `countries`(`id`)
);

CREATE TABLE `stadiums`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`name` VARCHAR(45) NOT NULL,
`capacity` INT NOT NULL,
`town_id` INT NOT NULL,
CONSTRAINT fk_stadium_town
FOREIGN KEY (`town_id`)
REFERENCES `towns`(`id`)
);

CREATE TABLE `teams`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`name` VARCHAR(45) NOT NULL,
`established` DATE NOT NULL,
`fan_base` BIGINT NOT NULL,
`stadium_id` INT NOT NULL,
CONSTRAINT fk_team_stadium
FOREIGN KEY (`stadium_id`)
REFERENCES `stadiums`(`id`)
);

CREATE TABLE `skills_data`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`dribbling` INT DEFAULT 0,
`pace` INT DEFAULT 0,
`passing` INT DEFAULT 0,
`shooting` INT DEFAULT 0,
`speed` INT DEFAULT 0,
`strength` INT DEFAULT 0
);

CREATE TABLE `coaches`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`first_name` VARCHAR(10) NOT NULL,
`last_name` VARCHAR(20) NOT NULL,
`salary` DECIMAL(10,2) NOT NULL DEFAULT 0,
`coach_level` INT NOT NULL DEFAULT 0
);

CREATE TABLE `players`(
`id` INT PRIMARY KEY AUTO_INCREMENT,
`first_name` VARCHAR(10) NOT NULL,
`last_name` VARCHAR(20) NOT NULL,
`age` INT NOT NULL DEFAULT 0,
`position` CHAR(1) NOT NULL,
`salary` DECIMAL(10,2) NOT NULL DEFAULT 0,
`hire_date` DATETIME,
`skills_data_id` INT NOT NULL,
`team_id` INT,
CONSTRAINT fk_player_skills
FOREIGN KEY (`skills_data_id`)
REFERENCES `skills_data`(`id`),
CONSTRAINT fk_player_team
FOREIGN KEY (`team_id`)
REFERENCES `teams`(`id`) 
);

CREATE TABLE `players_coaches`(
`player_id` INT,
`coach_id` INT,
CONSTRAINT fk_player_coach
FOREIGN KEY (`player_id`)
REFERENCES `players`(`id`),
CONSTRAINT fk_coach_player
FOREIGN KEY (`coach_id`)
REFERENCES `coaches`(`id`)
);

#02. Insert
INSERT INTO `coaches` (`first_name`, `last_name`, `salary`, `coach_level`)
SELECT `first_name`, `last_name`, `salary` * 2, CHAR_LENGTH(`first_name`)
FROM `players`
WHERE `age` >= 45;

#03. Update
UPDATE `coaches` AS c
SET `coach_level` = `coach_level` + 1
WHERE (
	SELECT COUNT(pc.`player_id`)
	FROM `players_coaches` AS pc
	WHERE pc.`coach_id` = c.`id`) >= 1 
AND c.`first_name` LIKE 'A%';

#04. Delete
DELETE p FROM `players` AS p
WHERE p.`age` >= 45;

#05. Players
SELECT `first_name`, `age`, `salary` FROM `players`
ORDER BY `salary` DESC;

#06. Young offense players without contract
SELECT p.`id`,
CONCAT_WS(' ', p.`first_name`, p.`last_name`) AS 'full_name',
p.`age`,
p.`position`,
p.`hire_date`
FROM `players` AS p
	JOIN `skills_data` AS sd ON p.`skills_data_id` = sd.`id`
WHERE p.`age` < 23 
AND p.`hire_date` IS NULL
AND sd.`strength` > 50
ORDER BY p.`salary`, p.`age`;

#07. Detail info for all teams
SELECT t.`name` AS 'team_name',
t.`established`,
t.`fan_base`,
COUNT(p.`team_id`) AS 'players_count'
FROM `teams` AS t
	LEFT JOIN `players` AS p ON p.`team_id` = t.`id`
GROUP BY t.`name`, t.`established`, t.`fan_base`
ORDER BY `players_count` DESC, t.`fan_base` DESC;

#08. The fastest player by towns
SELECT MAX(sd.`speed`) AS 'max_speed',
t.`name` AS 'town_name'
FROM `towns` AS t
	LEFT JOIN `stadiums` AS s ON t.`id` = s.`town_id`
	JOIN `teams` AS te ON te.`stadium_id` = s.`id`
    AND te.`name` NOT LIKE 'Devify'
	LEFT JOIN `players` AS p ON p.`team_id` = te.`id`
	LEFT JOIN `skills_data` AS sd ON sd.`id` = p.`skills_data_id`
GROUP BY `town_name`
ORDER BY `max_speed` DESC, `town_name`;

#09. Total salaries and players by country
SELECT c.`name`,
COUNT(p.`id`) AS 'total_count_of_players',
	IF (SUM(p.`id`) <> 0,
	SUM(p.`salary`),
	NULL) AS 'total_sum_of_salaries'
FROM `countries` AS c
	LEFT JOIN `towns` AS t ON c.`id` = t.`country_id`
	LEFT JOIN `stadiums` AS s ON t.`id` = s.`town_id`
	LEFT JOIN `teams` AS te ON te.`stadium_id` = s.`id`
	LEFT JOIN `players` AS p ON p.`team_id` = te.`id`
GROUP BY c.`name`
ORDER BY `total_count_of_players` DESC, c.`name`;

#10. Find all players that play on stadium
delimiter %%
CREATE FUNCTION udf_stadium_players_count (stadium_name VARCHAR(30)) 
RETURNS INT
DETERMINISTIC
BEGIN
	DECLARE count INT;
    SET count := (
					SELECT COUNT(p.`id`) FROM `players` AS p
						JOIN `teams` AS te ON p.`team_id` = te.`id`
						JOIN `stadiums` AS s ON s.`id` = te.`stadium_id`
					WHERE s.`name` = stadium_name);
                    
	RETURN count;
END%%

SELECT udf_stadium_players_count ('Jaxworks') as `count`; # expected 14

SELECT udf_stadium_players_count ('Linklinks') as `count`; # expected 0

#11. Find good playmaker by teams
delimiter %%
CREATE PROCEDURE udp_find_playmaker(min_dribble_points INT, team_name VARCHAR(45))
BEGIN
	DECLARE avg_speed FLOAT;
    SET avg_speed := (SELECT AVG(`speed`) FROM `skills_data`);
    
	SELECT CONCAT_WS(' ', p.`first_name`, p.`last_name`) AS 'full_name',
		p.`age`,
        p.`salary`,
		sd.`dribbling`,
		sd.`speed`,
		te.`name` AS 'team_name'
	FROM `players` AS p
		JOIN `skills_data` AS sd ON p.`skills_data_id` = sd.`id`
        JOIN `teams` AS te ON te.`id` = p.`team_id`
        AND te.`name` LIKE team_name
	WHERE sd.`dribbling` > min_dribble_points
    AND sd.`speed` > avg_speed
    ORDER BY sd.`speed` DESC
    LIMIT 1;
    
END%%


CALL udp_find_playmaker (20, 'Skyble');