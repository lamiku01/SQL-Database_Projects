SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- CREATE USER cecs535 and GRANT ACCESS TO CECSProject
-- -----------------------------------------------------
DROP USER IF EXISTS 'cecs535'@'%';
FLUSH PRIVILEGES;

CREATE USER 'cecs535'@'%' IDENTIFIED BY 'taforever';
GRANT ALL PRIVILEGES ON *.* TO 'cecs535'@'%';
FLUSH PRIVILEGES;

-- -----------------------------------------------------
-- Schema CECSProject
-- -----------------------------------------------------
DROP DATABASE IF EXISTS `CECSProject`;
CREATE DATABASE IF NOT EXISTS `CECSProject`;


USE `CECSProject` ;

-- -----------------------------------------------------
-- Table `CECSProject`.`HOTEL`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `CECSProject`.`HOTEL` ;

CREATE TABLE IF NOT EXISTS `CECSProject`.`HOTEL` (
  `hotelid` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `address` VARCHAR(100) NOT NULL,
  `manager-name` VARCHAR(100) NOT NULL,
  `number-rooms` INT NOT NULL,
  `amenities` VARCHAR(200) NOT NULL,
  PRIMARY KEY (`hotelid`))
AUTO_INCREMENT = 1;

-- -----------------------------------------------------
-- Table `CECSProject`.`ROOM`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `CECSProject`.`ROOM` ;

CREATE TABLE IF NOT EXISTS `CECSProject`.`ROOM` (
  `number` INT NOT NULL,
  `type` VARCHAR(9) NOT NULL,
  `occupancy` INT NOT NULL,
  `number-beds` INT NOT NULL,
  `type-beds` VARCHAR(6) NOT NULL,
  `price` INT UNSIGNED NOT NULL,
  `hotel-id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`number`, `hotel-id`),
  INDEX `hotel-id` (`hotel-id` ASC) VISIBLE,
  CONSTRAINT `room_ibfk_1`
    FOREIGN KEY (`hotel-id`)
    REFERENCES `CECSProject`.`HOTEL` (`hotelid`));

-- -----------------------------------------------------
-- Table `CECSProject`.`CUSTOMER`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `CECSProject`.`CUSTOMER` ;

CREATE TABLE IF NOT EXISTS `CECSProject`.`CUSTOMER` (
  `cust-id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `street` VARCHAR(100) NOT NULL,
  `city` VARCHAR(100) NOT NULL,
  `zip` CHAR(5) NOT NULL,
  `status` ENUM('gold', 'silver', 'business') NOT NULL,
  PRIMARY KEY (`cust-id`))
AUTO_INCREMENT = 100;

-- -----------------------------------------------------
-- Table `CECSProject`.`RESERVATION`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `CECSProject`.`RESERVATION` ;

CREATE TABLE IF NOT EXISTS `CECSProject`.`RESERVATION` (
  `hotel-id` INT UNSIGNED NOT NULL,
  `cust-id` INT UNSIGNED NOT NULL,
  `room-number` INT NOT NULL,
  `begin-date` DATE NOT NULL,
  `end-date` DATE NOT NULL,
  `credit-card-number` CHAR(20) NOT NULL,
  `exp-date` CHAR(5) NOT NULL,
  PRIMARY KEY (`room-number`, `hotel-id`, `begin-date`, `end-date`),
  CONSTRAINT `reservation_ibfk_1`
    FOREIGN KEY (`room-number` , `hotel-id`)
    REFERENCES `CECSProject`.`ROOM` (`number` , `hotel-id`));

-- -----------------------------------------------------
-- Trigger `CECSProject`.`ROOM_BEFORE_INSERT`
-- -----------------------------------------------------
USE `CECSProject`;

DELIMITER $$

USE `CECSProject`$$
DROP TRIGGER IF EXISTS `CECSProject`.`ROOM_BEFORE_INSERT` $$
CREATE TRIGGER `CECSProject`.`ROOM_BEFORE_INSERT`
BEFORE INSERT ON `CECSProject`.`ROOM`
FOR EACH ROW
BEGIN
	IF NEW.number IS NULL THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Room number is required for table Room';
		END IF;
	IF (NEW.type NOT IN ('regular', 'extra', 'suite', 'business', 'luxury', 'family')) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Room type must be regular, extra, suite, business, luxury, or family';
		END IF;
	IF (NEW.occupancy NOT BETWEEN 1 AND 5) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Room occupancy must be 1-5 people';
		END IF;
	IF (NEW.`number-beds` NOT BETWEEN 1 AND 3) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Number of beds must be 1, 2, or 3';
		END IF;
	IF (NEW.`type-beds` NOT IN ('queen', 'king', 'full')) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Bed type must be queen, king, or full';
		END IF;
    IF (NEW.price < 0) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Room Price must be a positive number';
		END IF; 
    IF NEW.`hotel-id` IS NULL THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Hotel ID is required for table Room';
		END IF;
END$$
DELIMITER ;

-- -----------------------------------------------------
-- procedure Occupancy
-- -----------------------------------------------------
USE `CECSProject`;
DROP procedure IF EXISTS `CECSProject`.`Occupancy`;

DELIMITER $$
USE `CECSProject`$$
CREATE PROCEDURE `Occupancy`(IN hotelid INT, IN in_date DATE)
BEGIN
	DECLARE number_of_reserved_rooms INT;
	SELECT COUNT(*) INTO number_of_reserved_rooms FROM RESERVATION
    WHERE `hotel-id` = hotelid AND in_date >= `begin-date` AND in_date <= `end-date`;
    SELECT number_of_reserved_rooms;
END$$

DELIMITER ;


-- -----------------------------------------------------
-- Table `CECSProject`.`REVENUE`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `CECSProject`.`REVENUE` ;

CREATE TABLE IF NOT EXISTS `CECSProject`.`REVENUE` (hotelid INT, total INT, PRIMARY KEY(hotelid)) 
	SELECT RESERVATION.`hotel-id` as hotelid, sum(price * DATEDIFF(`end-date`, `begin-date`)) as total FROM (RESERVATION, ROOM)
	WHERE RESERVATION.`hotel-id` = ROOM.`hotel-id` AND RESERVATION.`room-number` = ROOM.number
	GROUP BY RESERVATION.`hotel-id`;

-- -----------------------------------------------------
-- Trigger `CECSProject`.`RESERVATION_AFTER_INSERT`
-- -----------------------------------------------------
DELIMITER $$
USE `CECSProject` $$

DROP TRIGGER IF EXISTS `CECSProject`.`RESERVATION_AFTER_INSERT` $$
USE `CECSProject`$$
CREATE TRIGGER `CECSProject`.`RESERVATION_AFTER_INSERT`
AFTER INSERT ON `CECSProject`.`RESERVATION`
FOR EACH ROW
BEGIN
	UPDATE REVENUE
    SET REVENUE.total = REVENUE.total + (SELECT (price * DATEDIFF(NEW.`end-date`, NEW.`begin-date`)) FROM (ROOM) WHERE ROOM.`hotel-id`=NEW.`hotel-id` AND ROOM.number=NEW.`room-number`)
    WHERE REVENUE.hotelid = NEW.`hotel-id`;
END$$

DELIMITER ;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
