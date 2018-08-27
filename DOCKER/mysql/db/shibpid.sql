# Create `shibboleth` database with `shibpid` table

SET NAMES 'utf8';
SET CHARACTER SET utf8;
CHARSET utf8;
CREATE DATABASE IF NOT EXISTS shibboleth CHARACTER SET=utf8;
USE shibboleth;
CREATE TABLE IF NOT EXISTS `shibpid` (
  `localEntity` VARCHAR(255) NOT NULL,
  `peerEntity` VARCHAR(255) NOT NULL,
  `principalName` VARCHAR(255) NOT NULL DEFAULT '',
  `localId` VARCHAR(255) NOT NULL,
  `persistentId` VARCHAR(50) NOT NULL,
  `peerProvidedId` VARCHAR(255) DEFAULT NULL,
  `creationDate` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deactivationDate` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (localEntity, peerEntity, persistentId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

