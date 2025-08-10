CREATE TABLE IF NOT EXISTS `rex_saloon` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `saloonid` varchar(50) DEFAULT NULL,
  `owner` varchar(50) DEFAULT NULL,
  `rent` int(3) NOT NULL DEFAULT 0,
  `status` varchar(50) DEFAULT 'closed',
  `money` double(11,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `rex_saloon_stock` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `saloonid` varchar(50) DEFAULT NULL,
  `item` varchar(50) DEFAULT NULL,
  `stock` int(11) NOT NULL DEFAULT 0,
  `price` double(11,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

INSERT INTO `rex_saloon` (`saloonid`, `owner`, `money`) VALUES
('valsaloon', 'vacant', 0.00),
('blasaloon', 'vacant', 0.00),
('rhosaloon', 'vacant', 0.00),
('doysaloon', 'vacant', 0.00),
('bassaloon', 'vacant', 0.00),
('oldsaloon', 'vacant', 0.00),
('armsaloon', 'vacant', 0.00),
('tumsaloon', 'vacant', 0.00);

INSERT INTO `management_funds` (`job_name`, `amount`, `type`) VALUES
('valsaloon', 0, 'boss'),
('blasaloon', 0, 'boss'),
('rhosaloon', 0, 'boss'),
('doysaloon', 0, 'boss'),
('bassaloon', 0, 'boss'),
('oldsaloon', 0, 'boss'),
('armsaloon', 0, 'boss'),
('tumsaloon', 0, 'boss');