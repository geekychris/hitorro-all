CREATE DATABASE htcms CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER htcms IDENTIFIED BY 'htcms';
GRANT ALL PRIVILEGES ON htcms.* TO htcms@'localhost' IDENTIFIED BY 'htcms';
#GRANT ALL ON htcms.* TO htcms@'localhost';
GRANT SELECT ON htcms.* TO htcms@'localhost' IDENTIFIED BY 'htcms';
GRANT ALL PRIVILEGES ON *.* TO htcms@'localhost' IDENTIFIED BY 'htcms';