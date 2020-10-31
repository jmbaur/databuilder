-- DROP VIEW IF EXISTS students_view;
DROP TABLE IF EXISTS attendance;
DROP TYPE IF EXISTS attendance_types;
DROP TABLE IF EXISTS funding_source_enrollments;
DROP TABLE IF EXISTS funding_source_registrations;
DROP TABLE IF EXISTS microschool_enrollments;
DROP TABLE IF EXISTS staffing;
DROP TABLE IF EXISTS microschool_terms;
DROP TABLE IF EXISTS microschools;
DROP TYPE IF EXISTS microschool_type;
DROP TABLE IF EXISTS grade_enrollments;
DROP TABLE IF EXISTS grade_years;
DROP TYPE IF EXISTS school_year;
DROP TABLE IF EXISTS relationships;
DROP TABLE IF EXISTS students;
DROP TYPE IF EXISTS grade_level;
DROP TYPE IF EXISTS funding_sources;
DROP TYPE IF EXISTS funding_source;
DROP TABLE IF EXISTS adults;
DROP TABLE IF EXISTS states;
DROP TABLE IF EXISTS pw_enrollments_dump;
DROP TABLE IF EXISTS pw_students_dump;
DROP TABLE IF EXISTS pw_guides_dump;
DROP TABLE IF EXISTS pw_microschools_dump;
DROP TABLE IF EXISTS pw_exceptions;
DROP TABLE IF EXISTS zoho_exceptions;

CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS states (
  id SERIAL PRIMARY KEY,
  state_name TEXT,
  state_abbrev CHAR (2)
);

INSERT INTO states (state_name, state_abbrev)
VALUES ('Alabama', 'AL'),
       ('Alaska', 'AK'),
       ('Arizona', 'AZ'),
       ('Arkansas', 'AR'),
       ('California', 'CA'),
       ('Colorado', 'CO'),
       ('Connecticut', 'CT'),
       ('Delaware', 'DE'),
       ('District of Columbia', 'DC'),
       ('Florida', 'FL'),
       ('Georgia', 'GA'),
       ('Hawaii', 'HI'),
       ('Idaho', 'ID'),
       ('Illinois', 'IL'),
       ('Indiana', 'IN'),
       ('Iowa', 'IA'),
       ('Kansas', 'KS'),
       ('Kentucky', 'KY'),
       ('Louisiana', 'LA'),
       ('Maine', 'ME'),
       ('Maryland', 'MD'),
       ('Massachusetts', 'MA'),
       ('Michigan', 'MI'),
       ('Minnesota', 'MN'),
       ('Mississippi', 'MS'),
       ('Missouri', 'MO'),
       ('Montana', 'MT'),
       ('Nebraska', 'NE'),
       ('Nevada', 'NV'),
       ('New Hampshire', 'NH'),
       ('New Jersey', 'NJ'),
       ('New Mexico', 'NM'),
       ('New York', 'NY'),
       ('North Carolina', 'NC'),
       ('North Dakota', 'ND'),
       ('Ohio', 'OH'),
       ('Oklahoma', 'OK'),
       ('Oregon', 'OR'),
       ('Pennsylvania', 'PA'),
       ('Rhode Island', 'RI'),
       ('South Carolina', 'SC'),
       ('South Dakota', 'SD'),
       ('Tennessee', 'TN'),
       ('Texas', 'TX'),
       ('Utah', 'UT'),
       ('Vermont', 'VT'),
       ('Virginia', 'VA'),
       ('Washington', 'WA'),
       ('West Virginia', 'WV'),
       ('Wisconsin', 'WI'),
       ('Wyoming', 'WY');

CREATE TABLE IF NOT EXISTS adults (
  id SERIAL PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  -- parent_2_first_name TEXT,
  -- parent_2_last_name TEXT,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  address_1 TEXT,
  address_2 TEXT,
  city TEXT,
  state TEXT,
  zip5 TEXT,
  zip4 TEXT,
  is_guide BOOLEAN NOT NULL DEFAULT false,
  is_guardian BOOLEAN NOT NULL DEFAULT false,
  zoho_id TEXT UNIQUE,
  pw_id TEXT UNIQUE,
  temp_lead_guide BOOLEAN
);

CREATE TYPE funding_source AS ENUM ('Unknown', 'Private', 'ESA', 'Sequoia Choice', 'Mesa Public Schools');

CREATE TYPE grade_level AS ENUM ('Kindergarten', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12');

CREATE TABLE IF NOT EXISTS students (
  id SERIAL PRIMARY KEY,
  complete_per funding_source,
  first_name TEXT NOT NULL,
  middle_name TEXT,
  last_name TEXT,
  preferred_first_name TEXT,
  birth_date DATE,
  email TEXT,
  phone TEXT,
  address_1 TEXT,
  address_2 TEXT,
  city TEXT,
  state INTEGER REFERENCES states (id),
  zip5 TEXT,
  zip4 TEXT,
  sais_id TEXT UNIQUE,
  airtable_id TEXT UNIQUE,
  zoho_id TEXT UNIQUE,
  pw_id TEXT UNIQUE,
  birth_state INTEGER REFERENCES states (id),
  birth_country TEXT,
  last_school TEXT,
  last_school_address TEXT,
  last_school_phone TEXT,
  last_grade_completed grade_level,
  desired_start_date TEXT,
  has_been_expelled BOOLEAN,
  lacks_nighttime_residence BOOLEAN,
  health_problems TEXT,
  on_daily_medication BOOLEAN,
  medications TEXT,
  medications_needed_during_school TEXT,
  surgeries_accidents_injuries_past_year TEXT,
  food_allergies TEXT,
  medication_or_other_allergies TEXT,
  family_doctor TEXT,
  family_doctor_phone TEXT,
  accept_medical_release BOOLEAN,
  proof_of_residence BYTEA,
  birth_certificate BYTEA,
  immunization_record BYTEA,
  primary_language_at_home TEXT,
  language_spoken_most_often TEXT,
  language_first_acquired TEXT,
  race TEXT,
  receives_special_education BOOLEAN,
  date_of_last_iep DATE,
  last_iep BYTEA,
  parent_info TEXT,
  new_enrollment BOOLEAN,
  typeform_microschool TEXT,
  submitted BOOLEAN,
  referred_by TEXT,
  desired_guide TEXT,
  video_release BOOLEAN,
  emergency_contacts TEXT,
  emergency_contact_name_1 TEXT,
  emergency_contact_phone_1 TEXT,
  emergency_contact_relationship_1 TEXT,
  emergency_contact_name_2 TEXT,
  emergency_contact_phone_2 TEXT,
  emergency_contact_relationship_2 TEXT,
  mother_guardian_name TEXT,
  mother_guardian_phone TEXT,
  mother_guardian_email TEXT,
  mother_guardian_employer TEXT,
  mother_guardian_relationship TEXT,
  father_guardian_name TEXT,
  father_guardian_phone TEXT,
  father_guardian_email TEXT,
  father_guardian_employer TEXT,
  father_guardian_relationship TEXT,
  gender TEXT,
  typeform_id TEXT,
  prenda_enrollment_date DATE,
  sequoia_entry_date DATE,
  status TEXT,
  is_esa BOOLEAN,
  recruited_by TEXT,
  withdrawal_note TEXT,
  withdrawal_reason TEXT,
  enrolled_in_sequoia TEXT

  CONSTRAINT student_required_sequoia
    CHECK (
      complete_per != 'Sequoia Choice' OR
      (state IS NOT NULL
      AND zip5 IS NOT NULL
      AND zip4 IS NOT NULL
      AND city IS NOT NULL
      AND last_name IS NOT NULL
      AND birth_date IS NOT NULL
      AND address_1 IS NOT NULL
      AND city IS NOT NULL
      AND state IS NOT NULL
      AND zip5 IS NOT NULL
      AND zip4 IS NOT NULL)
    )
);

CREATE TABLE IF NOT EXISTS relationships (
  id SERIAL PRIMARY KEY,
  guardian_id INTEGER NOT NULL REFERENCES adults (id),
  student_id INTEGER NOT NULL REFERENCES students (id),
  notes TEXT NOT NULL
);

CREATE TYPE school_year AS ENUM ('18-19', '19-20', '20-21');

CREATE TABLE IF NOT EXISTS grade_years (
  id SERIAL PRIMARY KEY,
  grade_level grade_level NOT NULL,
  school_year school_year NOT NULL,
  authorized_minutes_per_year INTEGER NOT NULL,
  UNIQUE (grade_level, school_year)
);

INSERT INTO grade_years (grade_level, school_year, authorized_minutes_per_year)
  VALUES ('Kindergarten', '19-20', 356*60),
    ('1', '19-20', 712*60),
    ('2', '19-20', 712*60),
    ('3', '19-20', 712*60),
    ('4', '19-20', 890*60),
    ('5', '19-20', 890*60),
    ('6', '19-20', 890*60),
    ('7', '19-20', 1000*60),
    ('8', '19-20', 1000*60),
    ('9', '19-20', 900*60),
    ('10', '19-20', 900*60),
    ('11', '19-20', 900*60),
    ('12', '19-20', 900*60);

CREATE TABLE IF NOT EXISTS grade_enrollments (
  id SERIAL PRIMARY KEY,
  student_id INTEGER NOT NULL REFERENCES students (id),
  grade_years_id INTEGER NOT NULL REFERENCES grade_years (id),
  -- TODO: not happy with the ability for someone to enroll in grade_year during a date range that doesn't match
  during DATERANGE NOT NULL,
  EXCLUDE USING GIST (student_id WITH =, during WITH &&)
);

CREATE TYPE microschool_type AS ENUM ('Microschool', 'Prenda Family');

CREATE TABLE IF NOT EXISTS microschools (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  phone TEXT,
  address_1 TEXT,
  address_2 TEXT,
  city TEXT,
  state INTEGER REFERENCES states (id),
  zip5 TEXT,
  zip4 TEXT,
  mailing_address_1 TEXT,
  mailing_address_2 TEXT,
  mailing_city TEXT,
  mailing_state INTEGER REFERENCES states (id),
  mailing_zip5 TEXT,
  mailing_zip4 TEXT,
  zoho_id TEXT UNIQUE,
  airtable_id TEXT UNIQUE,
  pw_id TEXT UNIQUE,
  status TEXT
);

CREATE TABLE IF NOT EXISTS microschool_terms (
  id SERIAL PRIMARY KEY,
  microschool_id INTEGER REFERENCES microschools (id),
  min_grade grade_level,
  max_grade grade_level,
  capacity INTEGER,
  type microschool_type NOT NULL,
  during DATERANGE NOT NULL,
  accepting_students BOOLEAN,
  accepting_students_aug_2020 BOOLEAN,
  publicly_visible BOOLEAN,
  EXCLUDE USING GIST (microschool_id WITH =, during WITH &&)
);

CREATE TABLE IF NOT EXISTS staffing (
  id SERIAL PRIMARY KEY,
  microschool_id INTEGER NOT NULL REFERENCES microschool_terms (id),
  guide_id INTEGER NOT NULL REFERENCES adults (id),
  -- TODO: constrain possible users to only adults where is_guide = true
  -- would this work?
  -- is_guide BOOLEAN NOT NULL CHECK (is_guide) REFERENCES adults (is_guide),
  -- CONSTRAINT staff_must_be_guide (id, is_guide)
  is_lead_guide BOOLEAN NOT NULL,
  CONSTRAINT one_lead_guide_per_microschool EXCLUDE USING GIST (microschool_id with =) WHERE (is_lead_guide IS TRUE)
);

CREATE TABLE IF NOT EXISTS microschool_enrollments (
  id SERIAL PRIMARY KEY,
  student_id INTEGER NOT NULL REFERENCES students (id),
  microschool_term_id INTEGER NOT NULL REFERENCES microschool_terms (id),
  authorized_minutes INTEGER,
  cents_per_minute INTEGER CHECK (cents_per_minute > 0),
  during DATERANGE NOT NULL,
  EXCLUDE USING GIST (student_id WITH =, during WITH &&)
);

CREATE TABLE IF NOT EXISTS funding_source_registrations (
  student_id INTEGER NOT NULL REFERENCES students (id),
  funding_source FUNDING_SOURCE NOT NULL,
  funding_source_student_id INTEGER,
  funding_source_student_number INTEGER,
  PRIMARY KEY (student_id, funding_source) -- need student_id in funding_source_enrollments for constraint
);

CREATE TABLE IF NOT EXISTS funding_source_enrollments (
  id SERIAL PRIMARY KEY,
  student_id INTEGER NOT NULL,
  funding_source FUNDING_SOURCE NOT NULL,
  during DATERANGE NOT NULL,
  FOREIGN KEY (student_id, funding_source)
    references funding_source_registrations (student_id, funding_source),
  -- this EXCLUDE only works with btree_gist
  EXCLUDE USING GIST (student_id WITH =, during WITH &&) -- no overlapping enrollments
);

CREATE TYPE attendance_types AS ENUM ('Attendance', 'Supplemental');

CREATE TABLE IF NOT EXISTS attendance (
  id SERIAL PRIMARY KEY,
  student_id INTEGER NOT NULL REFERENCES students (id),
  attendance_date DATE NOT NULL,
  attendance_type ATTENDANCE_TYPES NOT NULL,
  minutes INTEGER NOT NULL,
  approved_email TEXT,
  approved_at_utc TIMESTAMP,
  approved_ip TEXT,
  UNIQUE (student_id, attendance_date, attendance_type)
);
-- what
-- get attendance approval fields from Andy
-- add logs for attendance
-- create guide_payments table
-- create a report that difs the guide payment and attendance
-- create a report that verifies that the funding source paid us correctly
-- create attendance table with dateDeleted
-- upsertish attendance ( mark deleted if exists and add new row )
-- do same with microschool enrollments and funding source enrollments


-- CREATE OR REPLACE VIEW students_view AS
--   SELECT * FROM students
--   INNER JOIN grade_enrollments ON (students.id = grade_enrollments.student_id)
--   INNER JOIN

CREATE TABLE IF NOT EXISTS pw_microschools_dump (
  id SERIAL PRIMARY KEY,
  "ID" TEXT,
  "Name" TEXT,
  "Nickname" TEXT,
  "Type" TEXT,
  "Active" TEXT,
  "Date Created" TEXT,
  "Test Students" TEXT,
  "Kindergarten" TEXT,
  "1st" TEXT,
  "2nd" TEXT,
  "3rd" TEXT,
  "4th" TEXT,
  "5th" TEXT,
  "6th" TEXT,
  "7th" TEXT,
  "8th" TEXT,
  "Other" TEXT
);

CREATE TABLE IF NOT EXISTS pw_students_dump (
  id SERIAL PRIMARY KEY,
  "Last Name" TEXT,
  "First Name" TEXT,
  "Prenda ID" TEXT,
  "Sequoia ID" TEXT,
  "Enrolled Grade" TEXT,
  "School ID" TEXT,
  "School Name" TEXT,
  "Test Account" TEXT
);

CREATE TABLE IF NOT EXISTS pw_guides_dump (
  id SERIAL PRIMARY KEY,
  "Last Name" TEXT,
  "First Name" TEXT,
  "Email" TEXT,
  "Prenda ID" TEXT,
  "School IDs" TEXT
);

CREATE TABLE IF NOT EXISTS pw_enrollments_dump (
  id SERIAL PRIMARY KEY,
  "StudentID" TEXT,
  "School ID" TEXT,
  "Start Date" DATE,
  "End Date" DATE,
  "Hours" TEXT
);

CREATE TABLE IF NOT EXISTS pw_exceptions (
  id SERIAL PRIMARY KEY,
  insert_report text NOT NULL,
  data JSON NOT NULL
);

CREATE TABLE IF NOT EXISTS zoho_exceptions (
  id SERIAL PRIMARY KEY,
  insert_report text NOT NULL,
  data JSON NOT NULL,
  error JSON
);
CREATE TABLE "session" (
	"sid" varchar NOT NULL COLLATE "default",
	"sess" json NOT NULL,
	"expire" timestamp(6) NOT NULL
)
WITH (OIDS=FALSE);

ALTER TABLE "session" ADD CONSTRAINT "session_pkey" PRIMARY KEY ("sid") NOT DEFERRABLE INITIALLY IMMEDIATE;

CREATE INDEX "IDX_session_expire" ON "session" ("expire");
DROP TABLE IF EXISTS attendance;
DROP TYPE IF EXISTS attendance_types;
DROP TABLE IF EXISTS funding_source_enrollments;
DROP TABLE IF EXISTS funding_source_registrations;
DROP TABLE IF EXISTS microschool_enrollments;
DROP TABLE IF EXISTS staffing;
DROP TABLE IF EXISTS microschool_terms;
DROP TABLE IF EXISTS microschools;
DROP TYPE IF EXISTS microschool_type;
DROP TABLE IF EXISTS grade_enrollments;
DROP TABLE IF EXISTS grade_years;
DROP TYPE IF EXISTS school_year;
DROP TABLE IF EXISTS relationships;
DROP TABLE IF EXISTS students;
DROP TYPE IF EXISTS grade_level;
DROP TYPE IF EXISTS funding_sources;
DROP TABLE IF EXISTS adults;
DROP TABLE IF EXISTS states;

DROP EXTENSION btree_gist;
DROP EXTENSION pgcrypto;-- DROP VIEW IF EXISTS students_view;
DROP TABLE IF EXISTS attendance;
DROP TYPE IF EXISTS attendance_types;
DROP TABLE IF EXISTS funding_source_enrollments;
DROP TABLE IF EXISTS funding_source_registrations;
DROP TABLE IF EXISTS microschool_enrollments;
DROP TABLE IF EXISTS staffing;
DROP TABLE IF EXISTS microschool_terms;
DROP TABLE IF EXISTS microschools;
DROP TYPE IF EXISTS microschool_type;
DROP TABLE IF EXISTS grade_enrollments;
DROP TABLE IF EXISTS grade_years;
DROP TYPE IF EXISTS school_year;
DROP TABLE IF EXISTS relationships;
DROP TABLE IF EXISTS students;
DROP TYPE IF EXISTS grade_level;
DROP TYPE IF EXISTS funding_sources;
DROP TABLE IF EXISTS adults;
DROP TABLE IF EXISTS states;
DROP TABLE IF EXISTS pw_students_dump;
DROP TABLE IF EXISTS pw_guides_dump;
DROP TABLE IF EXISTS pw_microschools_dump;
DROP TABLE IF EXISTS pw_exceptions;
DROP TABLE IF EXISTS zoho_exceptions;

CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS states (
  id SERIAL PRIMARY KEY,
  state_name TEXT,
  state_abbrev CHAR (2)
);

INSERT INTO states (state_name, state_abbrev)
VALUES ('Alabama', 'AL'),
       ('Alaska', 'AK'),
       ('Arizona', 'AZ'),
       ('Arkansas', 'AR'),
       ('California', 'CA'),
       ('Colorado', 'CO'),
       ('Connecticut', 'CT'),
       ('Delaware', 'DE'),
       ('District of Columbia', 'DC'),
       ('Florida', 'FL'),
       ('Georgia', 'GA'),
       ('Hawaii', 'HI'),
       ('Idaho', 'ID'),
       ('Illinois', 'IL'),
       ('Indiana', 'IN'),
       ('Iowa', 'IA'),
       ('Kansas', 'KS'),
       ('Kentucky', 'KY'),
       ('Louisiana', 'LA'),
       ('Maine', 'ME'),
       ('Maryland', 'MD'),
       ('Massachusetts', 'MA'),
       ('Michigan', 'MI'),
       ('Minnesota', 'MN'),
       ('Mississippi', 'MS'),
       ('Missouri', 'MO'),
       ('Montana', 'MT'),
       ('Nebraska', 'NE'),
       ('Nevada', 'NV'),
       ('New Hampshire', 'NH'),
       ('New Jersey', 'NJ'),
       ('New Mexico', 'NM'),
       ('New York', 'NY'),
       ('North Carolina', 'NC'),
       ('North Dakota', 'ND'),
       ('Ohio', 'OH'),
       ('Oklahoma', 'OK'),
       ('Oregon', 'OR'),
       ('Pennsylvania', 'PA'),
       ('Rhode Island', 'RI'),
       ('South Carolina', 'SC'),
       ('South Dakota', 'SD'),
       ('Tennessee', 'TN'),
       ('Texas', 'TX'),
       ('Utah', 'UT'),
       ('Vermont', 'VT'),
       ('Virginia', 'VA'),
       ('Washington', 'WA'),
       ('West Virginia', 'WV'),
       ('Wisconsin', 'WI'),
       ('Wyoming', 'WY');

CREATE TABLE IF NOT EXISTS adults (
  id SERIAL PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  parent_2_first_name TEXT,
  parent_2_last_name TEXT,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  address_1 TEXT,
  address_2 TEXT,
  city TEXT,
  state TEXT,
  zip5 TEXT,
  zip4 TEXT,
  is_guide BOOLEAN NOT NULL DEFAULT false,
  is_guardian BOOLEAN NOT NULL DEFAULT false,
  zoho_id TEXT UNIQUE,
  pw_id TEXT UNIQUE,
  temp_lead_guide BOOLEAN
);

CREATE TYPE funding_sources AS ENUM ('ESA', 'Sequoia Choice', 'Private', 'Mesa Public Schools');

CREATE TYPE grade_level AS ENUM ('Kindergarten', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12');

CREATE TABLE IF NOT EXISTS students (
  id SERIAL PRIMARY KEY,
  complete_per funding_sources,
  first_name TEXT NOT NULL,
  middle_name TEXT,
  last_name TEXT,
  preferred_first_name TEXT,
  birth_date DATE,
  email TEXT,
  phone TEXT,
  address_1 TEXT,
  address_2 TEXT,
  city TEXT,
  state INTEGER REFERENCES states (id),
  zip5 TEXT,
  zip4 TEXT,
  sais_id TEXT UNIQUE,
  airtable_id TEXT UNIQUE,
  zoho_id TEXT UNIQUE,
  pw_id TEXT UNIQUE,
  birth_state INTEGER REFERENCES states (id),
  birth_country TEXT,
  last_school TEXT,
  last_school_address TEXT,
  last_school_phone TEXT,
  last_grade_completed grade_level,
  desired_start_date TEXT,
  has_been_expelled BOOLEAN,
  lacks_nighttime_residence BOOLEAN,
  health_problems TEXT,
  on_daily_medication BOOLEAN,
  medications TEXT,
  medications_needed_during_school TEXT,
  surgeries_accidents_injuries_past_year TEXT,
  food_allergies TEXT,
  medication_or_other_allergies TEXT,
  family_doctor TEXT,
  family_doctor_phone TEXT,
  accept_medical_release BOOLEAN,
  proof_of_residence BYTEA,
  birth_certificate BYTEA,
  immunization_record BYTEA,
  primary_language_at_home TEXT,
  language_spoken_most_often TEXT,
  language_first_acquired TEXT,
  race TEXT,
  receives_special_education BOOLEAN,
  date_of_last_iep DATE,
  last_iep BYTEA,
  parent_info TEXT,
  new_enrollment BOOLEAN,
  typeform_microschool TEXT,
  submitted BOOLEAN,
  referred_by TEXT,
  desired_guide TEXT,
  video_release BOOLEAN,
  emergency_contact_name_1 TEXT,
  emergency_contact_phone_1 TEXT,
  emergency_contact_relationship_1 TEXT,
  emergency_contact_name_2 TEXT,
  emergency_contact_phone_2 TEXT,
  emergency_contact_relationship_2 TEXT,
  gender TEXT,
  typeform_id TEXT,
  prenda_enrollment_date DATE,
  sequoia_entry_date DATE,
  status TEXT,
  is_esa BOOLEAN,
  recruited_by TEXT,
  withdrawal_note TEXT,
  withdrawal_reason TEXT,
  enrolled_in_sequoia TEXT

  CONSTRAINT student_required_sequoia
    CHECK (
      complete_per != 'Sequoia Choice' OR
      (state IS NOT NULL
      AND zip5 IS NOT NULL
      AND zip4 IS NOT NULL
      AND city IS NOT NULL
      AND last_name IS NOT NULL
      AND birth_date IS NOT NULL
      AND address_1 IS NOT NULL
      AND city IS NOT NULL
      AND state IS NOT NULL
      AND zip5 IS NOT NULL
      AND zip4 IS NOT NULL)
    )
);

CREATE TABLE IF NOT EXISTS relationships (
  id SERIAL PRIMARY KEY,
  guardian_id INTEGER NOT NULL REFERENCES adults (id),
  student_id INTEGER NOT NULL REFERENCES students (id),
  notes TEXT NOT NULL
);

CREATE TYPE school_year AS ENUM ('18-19', '19-20', '20-21');

CREATE TABLE IF NOT EXISTS grade_years (
  id SERIAL PRIMARY KEY,
  grade_level grade_level NOT NULL,
  school_year school_year NOT NULL,
  authorized_minutes_per_year INTEGER NOT NULL,
  UNIQUE (grade_level, school_year)
);

INSERT INTO grade_years (grade_level, school_year, authorized_minutes_per_year)
  VALUES ('Kindergarten', '19-20', 356*60),
    ('1', '19-20', 712*60),
    ('2', '19-20', 712*60),
    ('3', '19-20', 712*60),
    ('4', '19-20', 890*60),
    ('5', '19-20', 890*60),
    ('6', '19-20', 890*60),
    ('7', '19-20', 1000*60),
    ('8', '19-20', 1000*60);

CREATE TABLE IF NOT EXISTS grade_enrollments (
  id SERIAL PRIMARY KEY,
  student_id INTEGER NOT NULL REFERENCES students (id),
  grade_years_id INTEGER NOT NULL REFERENCES grade_years (id),
  -- TODO: not happy with the ability for someone to enroll in grade_year during a date range that doesn't match
  during DATERANGE NOT NULL,
  EXCLUDE USING GIST (student_id WITH =, during WITH &&)
);

CREATE TYPE microschool_type AS ENUM ('Microschool', 'Prenda Family');

CREATE TABLE IF NOT EXISTS microschools (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  phone TEXT,
  address_1 TEXT,
  address_2 TEXT,
  city TEXT,
  state INTEGER REFERENCES states (id),
  zip5 TEXT,
  zip4 TEXT,
  mailing_address_1 TEXT,
  mailing_address_2 TEXT,
  mailing_city TEXT,
  mailing_state INTEGER REFERENCES states (id),
  mailing_zip5 TEXT,
  mailing_zip4 TEXT,
  zoho_id TEXT UNIQUE,
  airtable_id TEXT UNIQUE,
  pw_id TEXT UNIQUE,
  status TEXT,
  latitude TEXT,
  longitude TEXT
);

CREATE TABLE IF NOT EXISTS microschool_terms (
  id SERIAL PRIMARY KEY,
  microschool_id INTEGER REFERENCES microschools (id),
  min_grade grade_level,
  max_grade grade_level,
  capacity INTEGER,
  type microschool_type,
  during DATERANGE NOT NULL,
  EXCLUDE USING GIST (microschool_id WITH =, during WITH &&)
);

CREATE TABLE IF NOT EXISTS staffing (
  id SERIAL PRIMARY KEY,
  microschool_id INTEGER NOT NULL REFERENCES microschools (id),
  -- TODO: constrain possible users to only users where is_guide = true
  guide_id INTEGER NOT NULL REFERENCES adults (id),
  is_lead_guide BOOLEAN NOT NULL,
  CONSTRAINT one_lead_guide_per_microschool EXCLUDE USING GIST (microschool_id with =) WHERE (is_lead_guide IS TRUE)
);

CREATE TABLE IF NOT EXISTS microschool_enrollments (
  id SERIAL PRIMARY KEY,
  student_id INTEGER NOT NULL REFERENCES students (id),
  microschool_id INTEGER NOT NULL REFERENCES microschool_terms (id),
  authorized_minutes INTEGER NOT NULL,
  cents_per_minute INTEGER CHECK (cents_per_minute > 0),
  during DATERANGE NOT NULL,
  EXCLUDE USING GIST (student_id WITH =, during WITH &&)
);

CREATE TABLE IF NOT EXISTS funding_source_registrations (
  student_id INTEGER NOT NULL REFERENCES students (id),
  funding_source FUNDING_SOURCES NOT NULL,
  funding_source_student_id INTEGER,
  funding_source_student_number INTEGER,
  PRIMARY KEY (student_id, funding_source) -- need student_id in funding_source_enrollments for constraint
);

CREATE TABLE IF NOT EXISTS funding_source_enrollments (
  id SERIAL PRIMARY KEY,
  student_id INTEGER NOT NULL,
  funding_source FUNDING_SOURCES NOT NULL,
  during DATERANGE NOT NULL,
  FOREIGN KEY (student_id, funding_source)
    references funding_source_registrations (student_id, funding_source),
  -- this EXCLUDE only works with btree_gist
  EXCLUDE USING GIST (student_id WITH =, during WITH &&) -- no overlapping enrollments
);

CREATE TYPE attendance_types AS ENUM ('Attendance', 'Supplemental');

CREATE TABLE IF NOT EXISTS attendance (
  id SERIAL PRIMARY KEY,
  student_id INTEGER NOT NULL REFERENCES students (id),
  attendance_date DATE NOT NULL,
  attendance_type ATTENDANCE_TYPES NOT NULL,
  minutes INTEGER NOT NULL,
  approved_email TEXT,
  approved_at_utc TIMESTAMP,
  approved_ip TEXT,
  UNIQUE (student_id, attendance_date, attendance_type)
);
-- what 
-- get attendance approval fields from Andy
-- add logs for attendance
-- create guide_payments table
-- create a report that difs the guide payment and attendance
-- create a report that verifies that the funding source paid us correctly
-- create attendance table with dateDeleted
-- upsertish attendance ( mark deleted if exists and add new row )
-- do same with microschool enrollments and funding source enrollments


-- CREATE OR REPLACE VIEW students_view AS
--   SELECT * FROM students
--   INNER JOIN grade_enrollments ON (students.id = grade_enrollments.student_id)
--   INNER JOIN 

CREATE TABLE IF NOT EXISTS pw_microschools_dump (
  id SERIAL PRIMARY KEY,
  "ID" TEXT,
  "Name" TEXT,
  "Nickname" TEXT,
  "Type" TEXT,
  "Active" TEXT,
  "Date Created" TEXT,
  "Test Students" TEXT,
  "Kindergarten" TEXT,
  "1st" TEXT,
  "2nd" TEXT,
  "3rd" TEXT,
  "4th" TEXT,
  "5th" TEXT,
  "6th" TEXT,
  "7th" TEXT,
  "8th" TEXT,
  "Other" TEXT
);

CREATE TABLE IF NOT EXISTS pw_students_dump (
  id SERIAL PRIMARY KEY,
  "Last Name" TEXT,
  "First Name" TEXT,
  "Prenda ID" TEXT,
  "Sequoia ID" TEXT,
  "Enrolled Grade" TEXT,
  "School ID" TEXT,
  "School Name" TEXT,
  "Test Account" TEXT
);

CREATE TABLE IF NOT EXISTS pw_guides_dump (
  id SERIAL PRIMARY KEY,
  "Last Name" TEXT,
  "First Name" TEXT,
  "Email" TEXT,
  "Prenda ID" TEXT,
  "School IDs" TEXT
);

CREATE TABLE IF NOT EXISTS pw_exceptions (
  id SERIAL PRIMARY KEY,
  insert_report text NOT NULL,
  data JSON NOT NULL
);

CREATE TABLE IF NOT EXISTS zoho_exceptions (
  id SERIAL PRIMARY KEY,
  insert_report text NOT NULL,
  data JSON NOT NULL,
  error JSON 
);

-- TODO: add loggingCREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DROP TABLE IF EXISTS pw_enrollments;
DROP TABLE IF EXISTS temp_guides;
DROP TABLE IF EXISTS users;

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
);

ALTER TABLE users
ADD COLUMN expiration timestamp;

ALTER TABLE users
DROP COLUMN expiration;

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
);DROP TABLE IF EXISTS temp_microschool_location;

DROP TABLE IF EXISTS pw_students_dump;
DROP TABLE IF EXISTS pw_guides_dump;
DROP TABLE IF EXISTS pw_microschools_dump;
DROP TABLE IF EXISTS pw_exceptions;
DROP TABLE IF EXISTS zoho_exceptions;-- DROP VIEW IF EXISTS students_view;
DROP TABLE IF EXISTS attendance;
DROP TYPE IF EXISTS attendance_types;
DROP TABLE IF EXISTS funding_source_enrollments;
DROP TABLE IF EXISTS funding_source_registrations;
DROP TABLE IF EXISTS microschool_enrollments;
DROP TABLE IF EXISTS staffing;
DROP TABLE IF EXISTS microschool_terms;
DROP TABLE IF EXISTS microschools;
DROP TYPE IF EXISTS microschool_type;
DROP TABLE IF EXISTS grade_enrollments;
DROP TABLE IF EXISTS grade_years;
DROP TYPE IF EXISTS school_year;
DROP TABLE IF EXISTS relationships;
DROP TABLE IF EXISTS students;
DROP TYPE IF EXISTS grade_level;
DROP TYPE IF EXISTS funding_sources;
DROP TABLE IF EXISTS adults;
DROP TABLE IF EXISTS states;
DROP TABLE IF EXISTS pw_students_dump;
DROP TABLE IF EXISTS pw_guides_dump;
DROP TABLE IF EXISTS pw_microschools_dump;
DROP TABLE IF EXISTS pw_exceptions;
DROP TABLE IF EXISTS zoho_exceptions;

CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS states (
  id SERIAL PRIMARY KEY,
  state_name TEXT,
  state_abbrev CHAR (2)
);

INSERT INTO states (state_name, state_abbrev)
VALUES ('Alabama', 'AL'),
       ('Alaska', 'AK'),
       ('Arizona', 'AZ'),
       ('Arkansas', 'AR'),
       ('California', 'CA'),
       ('Colorado', 'CO'),
       ('Connecticut', 'CT'),
       ('Delaware', 'DE'),
       ('District of Columbia', 'DC'),
       ('Florida', 'FL'),
       ('Georgia', 'GA'),
       ('Hawaii', 'HI'),
       ('Idaho', 'ID'),
       ('Illinois', 'IL'),
       ('Indiana', 'IN'),
       ('Iowa', 'IA'),
       ('Kansas', 'KS'),
       ('Kentucky', 'KY'),
       ('Louisiana', 'LA'),
       ('Maine', 'ME'),
       ('Maryland', 'MD'),
       ('Massachusetts', 'MA'),
       ('Michigan', 'MI'),
       ('Minnesota', 'MN'),
       ('Mississippi', 'MS'),
       ('Missouri', 'MO'),
       ('Montana', 'MT'),
       ('Nebraska', 'NE'),
       ('Nevada', 'NV'),
       ('New Hampshire', 'NH'),
       ('New Jersey', 'NJ'),
       ('New Mexico', 'NM'),
       ('New York', 'NY'),
       ('North Carolina', 'NC'),
       ('North Dakota', 'ND'),
       ('Ohio', 'OH'),
       ('Oklahoma', 'OK'),
       ('Oregon', 'OR'),
       ('Pennsylvania', 'PA'),
       ('Rhode Island', 'RI'),
       ('South Carolina', 'SC'),
       ('South Dakota', 'SD'),
       ('Tennessee', 'TN'),
       ('Texas', 'TX'),
       ('Utah', 'UT'),
       ('Vermont', 'VT'),
       ('Virginia', 'VA'),
       ('Washington', 'WA'),
       ('West Virginia', 'WV'),
       ('Wisconsin', 'WI'),
       ('Wyoming', 'WY');

CREATE TABLE IF NOT EXISTS adults (
  id SERIAL PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  parent_2_first_name TEXT,
  parent_2_last_name TEXT,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  address_1 TEXT,
  address_2 TEXT,
  city TEXT,
  state TEXT,
  zip5 TEXT,
  zip4 TEXT,
  is_guide BOOLEAN NOT NULL DEFAULT false,
  is_guardian BOOLEAN NOT NULL DEFAULT false,
  zoho_id TEXT UNIQUE,
  pw_id TEXT UNIQUE,
  temp_lead_guide BOOLEAN
);

CREATE TYPE funding_sources AS ENUM ('ESA', 'Sequoia Choice', 'Private', 'Mesa Public Schools');

CREATE TYPE grade_level AS ENUM ('Kindergarten', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12');

CREATE TABLE IF NOT EXISTS students (
  id SERIAL PRIMARY KEY,
  complete_per funding_sources,
  first_name TEXT NOT NULL,
  middle_name TEXT,
  last_name TEXT,
  preferred_first_name TEXT,
  birth_date DATE,
  email TEXT,
  phone TEXT,
  address_1 TEXT,
  address_2 TEXT,
  city TEXT,
  state INTEGER REFERENCES states (id),
  zip5 TEXT,
  zip4 TEXT,
  sais_id TEXT UNIQUE,
  airtable_id TEXT UNIQUE,
  zoho_id TEXT UNIQUE,
  pw_id TEXT UNIQUE,
  birth_state INTEGER REFERENCES states (id),
  birth_country TEXT,
  last_school TEXT,
  last_school_address TEXT,
  last_school_phone TEXT,
  last_grade_completed grade_level,
  desired_start_date TEXT,
  has_been_expelled BOOLEAN,
  lacks_nighttime_residence BOOLEAN,
  health_problems TEXT,
  on_daily_medication BOOLEAN,
  medications TEXT,
  medications_needed_during_school TEXT,
  surgeries_accidents_injuries_past_year TEXT,
  food_allergies TEXT,
  medication_or_other_allergies TEXT,
  family_doctor TEXT,
  family_doctor_phone TEXT,
  accept_medical_release BOOLEAN,
  proof_of_residence BYTEA,
  birth_certificate BYTEA,
  immunization_record BYTEA,
  primary_language_at_home TEXT,
  language_spoken_most_often TEXT,
  language_first_acquired TEXT,
  race TEXT,
  receives_special_education BOOLEAN,
  date_of_last_iep DATE,
  last_iep BYTEA,
  parent_info TEXT,
  new_enrollment BOOLEAN,
  typeform_microschool TEXT,
  submitted BOOLEAN,
  referred_by TEXT,
  desired_guide TEXT,
  video_release BOOLEAN,
  emergency_contact_name_1 TEXT,
  emergency_contact_phone_1 TEXT,
  emergency_contact_relationship_1 TEXT,
  emergency_contact_name_2 TEXT,
  emergency_contact_phone_2 TEXT,
  emergency_contact_relationship_2 TEXT,
  gender TEXT,
  typeform_id TEXT,
  prenda_enrollment_date DATE,
  sequoia_entry_date DATE,
  status TEXT,
  is_esa BOOLEAN,
  recruited_by TEXT,
  withdrawal_note TEXT,
  withdrawal_reason TEXT,
  enrolled_in_sequoia TEXT

  CONSTRAINT student_required_sequoia
    CHECK (
      complete_per != 'Sequoia Choice' OR
      (state IS NOT NULL
      AND zip5 IS NOT NULL
      AND zip4 IS NOT NULL
      AND city IS NOT NULL
      AND last_name IS NOT NULL
      AND birth_date IS NOT NULL
      AND address_1 IS NOT NULL
      AND city IS NOT NULL
      AND state IS NOT NULL
      AND zip5 IS NOT NULL
      AND zip4 IS NOT NULL)
    )
);

CREATE TABLE IF NOT EXISTS relationships (
  id SERIAL PRIMARY KEY,
  guardian_id INTEGER NOT NULL REFERENCES adults (id),
  student_id INTEGER NOT NULL REFERENCES students (id),
  notes TEXT NOT NULL
);

CREATE TYPE school_year AS ENUM ('18-19', '19-20', '20-21');

CREATE TABLE IF NOT EXISTS grade_years (
  id SERIAL PRIMARY KEY,
  grade_level grade_level NOT NULL,
  school_year school_year NOT NULL,
  authorized_minutes_per_year INTEGER NOT NULL,
  UNIQUE (grade_level, school_year)
);

INSERT INTO grade_years (grade_level, school_year, authorized_minutes_per_year)
  VALUES ('Kindergarten', '19-20', 356*60),
    ('1', '19-20', 712*60),
    ('2', '19-20', 712*60),
    ('3', '19-20', 712*60),
    ('4', '19-20', 890*60),
    ('5', '19-20', 890*60),
    ('6', '19-20', 890*60),
    ('7', '19-20', 1000*60),
    ('8', '19-20', 1000*60),
    ('9', '19-20', 900*60),
    ('10', '19-20', 900*60),
    ('11', '19-20', 900*60),
    ('12', '19-20', 900*60);

CREATE TABLE IF NOT EXISTS grade_enrollments (
  id SERIAL PRIMARY KEY,
  student_id INTEGER NOT NULL REFERENCES students (id),
  grade_years_id INTEGER NOT NULL REFERENCES grade_years (id),
  -- TODO: not happy with the ability for someone to enroll in grade_year during a date range that doesn't match
  during DATERANGE NOT NULL,
  EXCLUDE USING GIST (student_id WITH =, during WITH &&)
);

CREATE TYPE microschool_type AS ENUM ('Microschool', 'Prenda Family');

CREATE TABLE IF NOT EXISTS microschools (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  phone TEXT,
  address_1 TEXT,
  address_2 TEXT,
  city TEXT,
  state INTEGER REFERENCES states (id),
  zip5 TEXT,
  zip4 TEXT,
  mailing_address_1 TEXT,
  mailing_address_2 TEXT,
  mailing_city TEXT,
  mailing_state INTEGER REFERENCES states (id),
  mailing_zip5 TEXT,
  mailing_zip4 TEXT,
  zoho_id TEXT UNIQUE,
  airtable_id TEXT UNIQUE,
  pw_id TEXT UNIQUE,
  status TEXT
);

CREATE TABLE IF NOT EXISTS microschool_terms (
  id SERIAL PRIMARY KEY,
  microschool_id INTEGER REFERENCES microschools (id),
  min_grade grade_level,
  max_grade grade_level,
  capacity INTEGER,
  type microschool_type,
  during DATERANGE NOT NULL,
  accepting_students BOOLEAN,
  EXCLUDE USING GIST (microschool_id WITH =, during WITH &&)
);

CREATE TABLE IF NOT EXISTS staffing (
  id SERIAL PRIMARY KEY,
  microschool_id INTEGER NOT NULL REFERENCES microschools (id),
  -- TODO: constrain possible users to only users where is_guide = true
  guide_id INTEGER NOT NULL REFERENCES adults (id),
  is_lead_guide BOOLEAN NOT NULL,
  CONSTRAINT one_lead_guide_per_microschool EXCLUDE USING GIST (microschool_id with =) WHERE (is_lead_guide IS TRUE)
);

CREATE TABLE IF NOT EXISTS microschool_enrollments (
  id SERIAL PRIMARY KEY,
  student_id INTEGER NOT NULL REFERENCES students (id),
  microschool_id INTEGER NOT NULL REFERENCES microschool_terms (id),
  authorized_minutes INTEGER NOT NULL,
  cents_per_minute INTEGER CHECK (cents_per_minute > 0),
  during DATERANGE NOT NULL,
  EXCLUDE USING GIST (student_id WITH =, during WITH &&)
);

CREATE TABLE IF NOT EXISTS funding_source_registrations (
  student_id INTEGER NOT NULL REFERENCES students (id),
  funding_source FUNDING_SOURCES NOT NULL,
  funding_source_student_id INTEGER,
  funding_source_student_number INTEGER,
  PRIMARY KEY (student_id, funding_source) -- need student_id in funding_source_enrollments for constraint
);

CREATE TABLE IF NOT EXISTS funding_source_enrollments (
  id SERIAL PRIMARY KEY,
  student_id INTEGER NOT NULL,
  funding_source FUNDING_SOURCES NOT NULL,
  during DATERANGE NOT NULL,
  FOREIGN KEY (student_id, funding_source)
    references funding_source_registrations (student_id, funding_source),
  -- this EXCLUDE only works with btree_gist
  EXCLUDE USING GIST (student_id WITH =, during WITH &&) -- no overlapping enrollments
);

CREATE TYPE attendance_types AS ENUM ('Attendance', 'Supplemental');

CREATE TABLE IF NOT EXISTS attendance (
  id SERIAL PRIMARY KEY,
  student_id INTEGER NOT NULL REFERENCES students (id),
  attendance_date DATE NOT NULL,
  attendance_type ATTENDANCE_TYPES NOT NULL,
  minutes INTEGER NOT NULL,
  approved_email TEXT,
  approved_at_utc TIMESTAMP,
  approved_ip TEXT,
  UNIQUE (student_id, attendance_date, attendance_type)
);
-- what 
-- get attendance approval fields from Andy
-- add logs for attendance
-- create guide_payments table
-- create a report that difs the guide payment and attendance
-- create a report that verifies that the funding source paid us correctly
-- create attendance table with dateDeleted
-- upsertish attendance ( mark deleted if exists and add new row )
-- do same with microschool enrollments and funding source enrollments


-- CREATE OR REPLACE VIEW students_view AS
--   SELECT * FROM students
--   INNER JOIN grade_enrollments ON (students.id = grade_enrollments.student_id)
--   INNER JOIN 

CREATE TABLE IF NOT EXISTS pw_microschools_dump (
  id SERIAL PRIMARY KEY,
  "ID" TEXT,
  "Name" TEXT,
  "Nickname" TEXT,
  "Type" TEXT,
  "Active" TEXT,
  "Date Created" TEXT,
  "Test Students" TEXT,
  "Kindergarten" TEXT,
  "1st" TEXT,
  "2nd" TEXT,
  "3rd" TEXT,
  "4th" TEXT,
  "5th" TEXT,
  "6th" TEXT,
  "7th" TEXT,
  "8th" TEXT,
  "Other" TEXT
);

CREATE TABLE IF NOT EXISTS pw_students_dump (
  id SERIAL PRIMARY KEY,
  "Last Name" TEXT,
  "First Name" TEXT,
  "Prenda ID" TEXT,
  "Sequoia ID" TEXT,
  "Enrolled Grade" TEXT,
  "School ID" TEXT,
  "School Name" TEXT,
  "Test Account" TEXT
);

CREATE TABLE IF NOT EXISTS pw_guides_dump (
  id SERIAL PRIMARY KEY,
  "Last Name" TEXT,
  "First Name" TEXT,
  "Email" TEXT,
  "Prenda ID" TEXT,
  "School IDs" TEXT
);

CREATE TABLE IF NOT EXISTS pw_exceptions (
  id SERIAL PRIMARY KEY,
  insert_report text NOT NULL,
  data JSON NOT NULL
);

CREATE TABLE IF NOT EXISTS zoho_exceptions (
  id SERIAL PRIMARY KEY,
  insert_report text NOT NULL,
  data JSON NOT NULL,
  error JSON 
);

-- TODO: add loggingDROP TABLE IF EXISTS temp_microschool_location;

CREATE TABLE IF NOT EXISTS temp_microschool_location (
id SERIAL PRIMARY KEY,
microschool_zoho_id TEXT NOT NULL,
latitude TEXT,
longitude TEXT,
city TEXT
);


INSERT INTO temp_microschool_location ("microschool_zoho_id", "latitude", "longitude", "city") VALUES
('3928975000013366001', '32.705232', '-114.62982', 'Yuma'),
('3928975000013289023', '34.251941', '-110.054104', 'Show Low'),
('3928975000013306001', '33.424543', '-111.760301', 'Mesa'),
('3928975000013287027', '35.714329', '-117.397995', 'Trona'),
('3928975000013273001', '33.079294', '-112.044013', 'Maricopa'),
('3928975000013378004', '33.388699', '-111.810112', 'Mesa'),
('3928975000013282001', '32.764945', '-109.652233', 'Safford'),
('3928975000013267051', '34.255568', '-110.08852', 'Show Low'),
('3928975000013062001', '33.404002', '-111.715112', 'Mesa'),
('3928975000013287007', '33.44338', '-112.30952', 'Avondale'),
('3928975000012936001', '34.569085', '-112.344389', 'Prescott Valley'),
('3928975000013271004', '34.256575', '-110.050278', 'Show Low'),
('3928975000013023001', '35.15983', '-111.65913', 'Flagstaff'),
('3928975000013069001', '34.252491', '-110.03918', 'Show Low'),
('3928975000013045001', '33.061676', '-111.960146', 'Maricopa'),
('3928975000012677001', '40.332434', '-111.717523', 'Orem'),
('3928975000011895001', '36.955991', '-112.98968', 'Colorado City'),
('3928975000011891001', '33.455114', '-111.911266', 'Scottsdale'),
('3928975000011879007', '31.99326', '-109.86484', 'Cochise'),
('3928975000013268004', '35.246173', '-112.188986', 'Williams'),
('3928975000011461001', '33.478272', '-112.079008', 'Phoenix'),
('3928975000011217004', '34.235874', '-111.317062', 'Payson'),
('3928975000010944082', '36.988176', '-112.990724', 'Colorado City'),
('3928975000010134022', '33.439435', '-111.675276', 'Mesa'),
('3928975000009891065', '35.205775', '-114.025973', 'Kingman'),
('3928975000009891096', '33.292467', '-111.779685', 'Gilbert'),
('3928975000009652021', '32.18148', '-110.8631', 'Tucson'),
('3928975000009587069', '33.619051', '-112.343305', 'Surprise'),
('3928975000009740040', '34.467153', '-110.091254', 'Taylor'),
('3928975000009738126', '33.40465', '-111.715975', 'Mesa'),
('3928975000009163032', '31.55754', '-110.2461', 'Sierra Vista'),
('3928975000008832206', '33.22584', '-111.527102', 'San Tan Valley'),
('3928975000008833044', '35.213199', '-111.655241', 'Flagstaff'),
('3928975000009784055', '33.444328', '-111.778578', 'Mesa'),
('3928975000009064013', '35.225598', '-113.983448', 'Kingman'),
('3928975000008832105', '33.319857', '-111.71603', 'Gilbert'),
('3928975000009159019', '34.193548', '-111.320525', 'Payson'),
('3928975000008830054', '33.353327', '-111.801363', 'Gilbert'),
('3928975000008665049', '33.03498', '-112.016778', 'Maricopa'),
('3928975000008681021', '33.145458', '-111.564204', 'San Tan Valley'),
('3928975000008668111', '34.285727', '-110.108117', 'Show Low'),
('3928975000007703011', '33.47897', '-112.304143', 'Avondale'),
('3928975000012700001', '33.227832', '-111.654069', 'Queen Creek'),
('3928975000012031001', '33.342659', '-111.722753', 'Gilbert'),
('3928975000012628012', '33.247691', '-111.514911', 'San Tan Valley'),
('3928975000006026001', '32.833475', '-109.695703', 'Safford'),
('3928975000008496021', '33.434405', '-111.798497', 'Mesa'),
('3928975000005423005', '31.35031', '-109.5573', 'Douglas'),
('3928975000006472002', '31.54807', '-110.25243', 'Sierra Vista'),
('3928975000013257013', '31.56672', '-110.28736', 'Sierra Vista'),
('3928975000005658008', '36.97', '-112.99', 'Colorado City'),
('3928975000005114002', '33.314403', '-111.730063', 'Gilbert'),
('3928975000005324002', '33.466228', '-112.405979', 'Goodyear'),
('3928975000005304001', '33.415583', '-111.492006', 'Apache Junction'),
('3928975000004011001', '36.97450051549038', '-112.98282554194198', 'Colorado City'),
('3928975000003995004', '33.193564', '-111.580685', 'San Tan Valley'),
('3928975000003933004', '34.286143', '-110.108116', 'Show Low'),
('3928975000003924001', '33.252722', '-111.808096', 'Chandler'),
('3928975000001131001', '32.856711', '-109.823262', 'Pima'),
('3928975000003865001', '36.973571589183095', '-112.97651853823952', 'Colorado City'),
('3928975000000764083', '34.245652', '-110.058088', 'Show Low'),
('3928975000000764079', '31.35031', '-109.5573', 'Douglas'),
('3928975000000764080', '31.4568', '-110.26296', 'Hereford'),
('3928975000000764075', '31.41187', '-109.8728', 'Bisbee'),
('3928975000000764081', '31.4522', '-110.22027', 'Hereford'),
('3928975000013179001', '33.318178', '-111.730419', 'Gilbert'),
('3928975000011877004', '33.452318', '-111.766568', 'Mesa'),
('3928975000011980001', '33.44096', '-112.385155', 'Goodyear'),
('3928975000011897001', '35.216019', '-111.614641', 'Flagstaff'),
('3928975000012624034', '33.371099', '-111.892029', 'Mesa'),
('3928975000012628001', '33.25541', '-111.740447', 'Gilbert'),
('3928975000012700015', '33.062837', '-112.0349', 'Maricopa'),
('3928975000012624023', '33.180868', '-111.575101', 'San Tan Valley'),
('3928975000008611001', '34.255685', '-111.315048', 'Payson'),
('3928975000012645004', '33.244195', '-111.55695', 'San Tan Valley'),
('3928975000012178001', '33.391442', '-111.806098', 'Mesa'),
('3928975000004063010', '42.911532', '-78.837881', 'Buffalo'),
('3928975000011368001', '33.653536', '-112.15733', 'Glendale'),
('3928975000003280010', '33.429476', '-111.803904', 'Mesa'),
('3928975000004114001', '35.244035', '-111.558543', 'Flagstaff'),
('3928975000007257010', '33.23635', '-111.706936', 'Gilbert'),
('3928975000002346001', '33.046839', '-112.023677', 'Maricopa'),
('3928975000002773140', '32.753071', '-109.736743', 'Safford'),
('3928975000008142022', '33.497643', '-112.391', 'Goodyear'),
('3928975000007713141', '36.997522', '-112.989769', 'Colorado City'),
('3928975000008129009', '33.646623', '-112.187152', 'Glendale'),
('3928975000007948023', '34.50027', '-110.08247', 'Snowflake'),
('3928975000008828187', '33.067686', '-112.011034', 'Maricopa'),
('3928975000007257004', '33.135631', '-111.565413', 'San Tan Valley'),
('3928975000008778092', '33.244766', '-111.52391', 'San Tan Valley'),
('3928975000008517025', '33.32377', '-111.706556', 'Higley'),
('3928975000003280004', '36.976614351651484', '-112.97719589729465', 'Colorado City'),
('3928975000002264001', '33.440194', '-111.783997', 'Mesa'),
('3928975000001709064', '33.445888', '-111.784394', 'Mesa'),
('3928975000003293001', '33.326101', '-111.699635', 'Higley'),
('3928975000003075002', '33.316853', '-111.732895', 'Gilbert'),
('3928975000001681001', '33.463174', '-111.773833', 'Mesa'),
('3928975000001657013', '34.300926', '-110.118161', 'Show Low'),
('3928975000001681013', '33.392361', '-111.634102', 'Mesa'),
('3928975000003293007', '32.940118', '-111.710908', 'Casa Grande'),
('3928975000001667007', '33.436994', '-111.757811', 'Mesa'),
('3928975000003245052', '34.49325', '-110.06357', 'Snowflake'),
('3928975000003683112', '33.311173', '-111.731391', 'Gilbert'),
('3928975000003630013', '34.263682', '-111.325688', 'Payson'),
('3928975000003915001', '36.97127953752504', '-112.97872424721773', 'Colorado City'),
('3928975000000764071', '31.67667', '-110.26363', 'Huachuca City'),
('3928975000000764056', '33.426162', '-111.857537', 'Mesa'),
('3928975000000764060', '32.22072', '-110.944795', 'Tucson'),
('3928975000001648064', '31.70067', '-109.7444', 'Elfrida'),
('3928975000003738120', '40.6680612222482', '-74.1184950455892', 'Bayonne'),
('3928975000009894084', '34.162483', '-110.000229', 'Lakeside'),
('3928975000009893001', '35.19462', '-114.05939', 'Kingman'),
('3928975000011101001', '33.359174', '-111.692008', 'Higley'),
('3928975000011307004', '33.398241', '-112.567793', 'Buckeye'),
('3928975000002851042', '33.428367', '-111.734111', 'Mesa'),
('3928975000010666088', '32.922798', '-109.823997', 'Pima'),
('3928975000009901012', '36.97465', '-112.97891', 'Colorado City'),
('3928975000000764035', '33.423364', '-111.855525', 'Mesa'),
('3928975000010663102', '33.49801', '-112.325807', 'Avondale'),
('3928975000010561001', '36.92', '-111.46', 'Page'),
('3928975000011067004', '33.044619', '-112.000791', 'Maricopa'),
('3928975000011064010', '32.29287', '-110.965303', 'Tucson'),
('3928975000002847038', '33.54717', '-112.449717', 'Waddell'),
('3928975000009899043', '35.197142', '-111.596379', 'Flagstaff'),
('3928975000004788004', '31.35161', '-109.55698', 'Douglas'),
('3928975000002252004', '36.988438', '-79.91469738069767', 'Colorado City'),
('3928975000009162056', '35.201419', '-113.968064', 'Kingman'),
('3928975000008675065', '31.914642', '-110.988211', 'Sahuarita'),
('3928975000003608124', '33.316059', '-111.737928', 'Gilbert'),
('3928975000003431004', '35.236078', '-111.669034', 'Flagstaff'),
('3928975000003608193', '31.909221', '-110.989286', 'Sahuarita'),
('3928975000003629013', '31.75716', '-109.72095', 'Elfrida'),
('3928975000003630004', '34.188801', '-110.012662', 'Lakeside'),
('3928975000003365001', '37.00289695958424', '-112.99111610976472', 'Hildale'),
('3928975000003619001', '36.990974019097706', '-112.97100554014058', 'Colorado City'),
('3928975000003366007', '34.392689', '-111.461774', 'Pine'),
('3928975000003422001', '34.507387', '-110.130953', 'Snowflake'),
('3928975000001040096', '32.29169', '-109.87444', 'Willcox'),
('3928975000004861001', '36.97', '-112.99', 'Colorado City'),
('3928975000005056049', '33.36069', '-111.69886', 'Higley'),
('3928975000004851001', '31.974326', '-110.968994', 'Sahuarita'),
('3928975000004787002', '33.568558', '-112.456522', 'Waddell'),
('3928975000004836005', '33.454007', '-112.086366', 'Phoenix'),
('3928975000011871015', '33.741992', '-112.132215', 'Phoenix'),
('3928975000011309010', '31.5608', '-110.29189', 'Sierra Vista'),
('3928975000011871001', '33.421382', '-111.838137', 'Mesa'),
('3928975000012243001', '34.511196', '-110.081076', 'Snowflake'),
('3928975000011872200', '33.471734', '-112.368788', 'Goodyear'),
('3928975000012495001', '33.568825', '-112.457453', 'Waddell'),
('3928975000000764044', '34.586373', '-109.67044', 'Concho'),
('3928975000010663144', '35.265908', '-111.531088', 'Flagstaff'),
('3928975000010668208', '35.184411', '-111.662638', 'Flagstaff'),
('3928975000010134008', '34.561101', '-112.484529', 'Prescott'),
('3928975000010133006', '33.458368', '-111.772268', 'Mesa'),
('3928975000000764038', '31.96484', '-110.29713', 'Benson'),
('3928975000000764052', '31.958556', '-110.462794', 'Benson'),
('3928975000000764037', '33.593919', '-112.369567', 'Surprise'),
('3928975000001729007', '40.6680612222482', '-74.1184950455892', 'Bayonne'),
('3928975000002079010', '33.579427', '-112.216678', 'Peoria'),
('3928975000000764057', '33.36', '-110.67', 'San Carlos'),
('3928975000000764055', '33.475626', '-112.167463', 'Phoenix'),
('3928975000001658001', '33.616388', '-112.335583', 'El Mirage'),
('3928975000003287001', '33.048927', '-112.024279', 'Maricopa'),
('3928975000001657007', '33.178044', '-111.598016', 'Chandler Heights'),
('3928975000003738053', '33.370099', '-111.771698', 'Gilbert'),
('3928975000009162028', '33.388316', '-112.138998', 'Phoenix'),
('3928975000008321005', '33.21278', '-111.805164', 'Chandler'),
('3928975000008394012', '33.374915', '-111.769513', 'Gilbert'),
('3928975000009162042', '35.22244', '-113.97433', 'Kingman'),
('3928975000009066010', '33.242158', '-111.593022', 'Queen Creek'),
('3928975000009156025', '32.294789', '-110.827176', 'Tucson'),
('3928975000008521072', '33.404952', '-111.716793', 'Mesa'),
('3928975000001654013', '33.257837', '-111.619386', 'Queen Creek'),
('3928975000001681007', '33.318944', '-111.728592', 'Gilbert'),
('3928975000001347001', '31.43663', '-110.23421', 'Hereford'),
('3928975000001649004', '34.255568', '-110.08852', 'Show Low'),
('3928975000004651006', '33.63134', '-112.446466', 'Surprise'),
('3928975000004347005', '33.49915', '-112.37672', 'Litchfield Park'),
('3928975000004547013', '33.876969', '-111.314673', 'Tonto Basin'),
('3928975000004669004', '34.26084', '-110.039615', 'Show Low'),
('3928975000004246003', '36.97465', '-112.97891', 'Colorado City'),
('3928975000004185001', '40.6680612222482', '-74.1184950455892', 'Bayonne'),
('3928975000003758010', '34.955986', '-110.334163', 'Joseph City'),
('3928975000000764070', '35.226423', '-111.463982', 'Flagstaff'),
('3928975000000764068', '31.4936', '-110.25191', 'Sierra Vista'),
('3928975000000764063', '31.964046', '-110.978808', 'Sahuarita'),
('3928975000003376001', '31.41', '-110.24', 'Hereford'),
('3928975000002767153', '33.457528', '-111.777838', 'Mesa'),
('3928975000001657019', '32.840119', '-109.763307', 'Thatcher'),
('3928975000004552008', '33.473682', '-111.92491', 'Scottsdale');

DROP TABLE IF EXISTS globals;DROP TABLE IF EXISTS globals;

CREATE TABLE IF NOT EXISTS globals (
  key TEXT PRIMARY KEY,
  document JSONB
);

INSERT INTO globals (key, document)
VALUES ('downloadAttendanceData', '{"isRunning": false, "timeRan": null}');

DROP TABLE IF EXISTS applications;

DROP TYPE IF EXISTS application_status;

CREATE TABLE IF NOT EXISTS applications (
  -- I didn't use PRIMARY KEY (student_id, school_year) because there is a chance that student_id could have null values with new enrollments in the future
  id SERIAL PRIMARY KEY,
  application_status application_status NOT NULL,
  -- TODO: add foreign key constraints and types when no longer running ephemeral ddl at import
  -- TODO: change from zoho_id to local id as soon as id's are stable
  zoho_student_id TEXT NOT NULL,
  school_year TEXT NOT NULL,
  zoho_microschool_id TEXT,
  funding_source TEXT,
  document JSONB,
  UNIQUE (zoho_student_id, zoho_microschool_id),
  UNIQUE (zoho_student_id, school_year)
);

ALTER TABLE applications DROP COLUMN IF EXISTS images;
ALTER TABLE applications DROP COLUMN IF EXISTS files;


ALTER TABLE applications ADD COLUMN IF NOT EXISTS files JSONB;

DROP TABLE IF EXISTS applications;

DROP TYPE IF EXISTS application_status;

CREATE TYPE application_status AS ENUM ('not started', 'saved for later', 'submitted', 'approved', 'missing information', 'not approved');



SELECT 'dont want the down to run and delete the data';
-- ALTER TABLE applications DROP COLUMN IF EXISTS files;ALTER TABLE applications ADD COLUMN IF NOT EXISTS files JSONB;DROP TABLE IF EXISTS "session";
CREATE TABLE IF NOT EXISTS "session" (
  "sid" varchar NOT NULL COLLATE "default",
	"sess" json NOT NULL,
	"expire" timestamp(6) NOT NULL
) WITH (OIDS=FALSE);

ALTER TABLE "session" DROP CONSTRAINT IF EXISTS "session_pkey";
ALTER TABLE "session" ADD CONSTRAINT "session_pkey" PRIMARY KEY ("sid") NOT DEFERRABLE INITIALLY IMMEDIATE;

CREATE INDEX IF NOT EXISTS "IDX_session_expire" ON "session" ("expire");
