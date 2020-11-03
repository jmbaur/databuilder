CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DROP TABLE IF EXISTS pw_enrollments;
DROP TABLE IF EXISTS temp_guides;
DROP TABLE IF EXISTS users;

-- test comment

CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  username TEXT NOT NULL UNIQUE,
  pwdhash TEXT NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  is_admin BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT users_check_empty_strings
    CHECK (username != '' AND pwdhash != '' AND first_name != '' AND last_name != '' AND email != '')
); -- test comment on a table statement

ALTER TABLE users ADD COLUMN expiration timestamp;
ALTER TABLE users DROP COLUMN expiration;

CREATE TABLE IF NOT EXISTS temp_guides (
  id SERIAL PRIMARY KEY,
  pw_user_id TEXT NOT NULL,
  bio TEXT,
  photo TEXT,
  UNIQUE (pw_user_id)
);

CREATE TABLE IF NOT EXISTS pw_enrollments (
  id SERIAL PRIMARY KEY,
  pw_student_id INTEGER NOT NULL,
  pw_microschool_id INTEGER NOT NULL,
  authorized_minutes INTEGER,
  cents_per_minute INTEGER,
  during DATERANGE NOT NULL,
  EXCLUDE USING GIST (pw_student_id WITH =, during WITH &&)
);
