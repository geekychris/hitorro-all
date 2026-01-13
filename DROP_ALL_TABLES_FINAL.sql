-- Final cleanup: Drop all tables before starting with update mode
USE htcms;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS versionableobject_contents;
DROP TABLE IF EXISTS versionableobject_container;
DROP TABLE IF EXISTS versionableobject_category;
DROP TABLE IF EXISTS content_category;
DROP TABLE IF EXISTS subjectarea_user;
DROP TABLE IF EXISTS user_role;
DROP TABLE IF EXISTS role_permission;
DROP TABLE IF EXISTS Extension;
DROP TABLE IF EXISTS Post;
DROP TABLE IF EXISTS document;
DROP TABLE IF EXISTS Forum;
DROP TABLE IF EXISTS container_t;
DROP TABLE IF EXISTS RssFeedIn;
DROP TABLE IF EXISTS Client;
DROP TABLE IF EXISTS SubjectArea;
DROP TABLE IF EXISTS Role;
DROP TABLE IF EXISTS Permission;
DROP TABLE IF EXISTS user_t;
DROP TABLE IF EXISTS Content;
DROP TABLE IF EXISTS ContentType;
DROP TABLE IF EXISTS contenttype;
DROP TABLE IF EXISTS Store;
DROP TABLE IF EXISTS NamedLongEntry;
DROP TABLE IF EXISTS ObjectVersions;
DROP TABLE IF EXISTS versionable_object;

SET FOREIGN_KEY_CHECKS = 1;

SELECT 'All tables dropped successfully' as Status;
SHOW TABLES;
