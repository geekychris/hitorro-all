#CREATE USER fi IDENTIFIED BY 'fipassword';
;;;
GRANT ALL PRIVILEGES ON ${database.name}.* TO fi@'localhost' IDENTIFIED BY 'fipassword';
;;;
GRANT SELECT ON ${database.name}.* TO fi@'localhost' IDENTIFIED BY 'fipassword';
;;;
GRANT ALL PRIVILEGES ON *.* TO fi@'localhost' IDENTIFIED BY 'fipassword';
;;;