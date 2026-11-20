-- =============================================================================
-- MySQL database setup for Smart Livestock Health and Farm Management System
-- =============================================================================
-- Run these commands as the MySQL root user (or any user with GRANT OPTION).
--
-- Usage:
--   mysql -u root -p < docs/02_setup/mysql-setup.sql
--
-- Or paste into the mysql shell:
--   mysql -u root -p
--   source docs/02_setup/mysql-setup.sql;
-- =============================================================================

-- Step 1: Create the database with full Unicode support
CREATE DATABASE IF NOT EXISTS livestock_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Step 2: Create a dedicated application user (least-privilege principle)
-- IMPORTANT: Replace 'CHANGE_THIS_PASSWORD' with a strong random password.
--            Store it in backend/.env under DB_PASSWORD — never hard-code it.
CREATE USER IF NOT EXISTS 'livestock_user'@'127.0.0.1'
    IDENTIFIED BY 'CHANGE_THIS_PASSWORD';

-- Step 3: Grant only the permissions the Django ORM needs
--   SELECT, INSERT, UPDATE, DELETE  — runtime data operations
--   CREATE, DROP, INDEX, ALTER       — needed by django migrate
--   REFERENCES                       — needed for foreign key constraints
GRANT SELECT, INSERT, UPDATE, DELETE,
      CREATE, DROP, INDEX, ALTER, REFERENCES
    ON livestock_db.*
    TO 'livestock_user'@'127.0.0.1';

-- Apply the privilege changes immediately
FLUSH PRIVILEGES;

-- Step 4: Verify the grants look correct
SHOW GRANTS FOR 'livestock_user'@'127.0.0.1';

-- =============================================================================
-- For testing environments only — creates a separate test database that
-- Django uses when running: python manage.py test
-- =============================================================================
-- CREATE DATABASE IF NOT EXISTS test_livestock_db
--     CHARACTER SET utf8mb4
--     COLLATE utf8mb4_unicode_ci;
--
-- GRANT ALL PRIVILEGES ON test_livestock_db.*
--     TO 'livestock_user'@'127.0.0.1';
-- =============================================================================

-- =============================================================================
-- Useful diagnostic queries
-- =============================================================================

-- Check which databases exist:
-- SHOW DATABASES;

-- Check active connections:
-- SHOW PROCESSLIST;

-- Check MySQL version:
-- SELECT VERSION();

-- Check character set configuration:
-- SHOW VARIABLES LIKE 'character_set%';
-- SHOW VARIABLES LIKE 'collation%';
