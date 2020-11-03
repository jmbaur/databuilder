CREATE TABLE IF NOT EXISTS states (
  id SERIAL PRIMARY KEY,
  state_name TEXT,
  state_abbrev CHAR (2)
);

INSERT INTO states (state_name, state_abbrev) VALUES ('Alabama', 'AL'), ('Alaska', 'AK'), ('Arizona', 'AZ'), ('Arkansas', 'AR'), ('California', 'CA'), ('Colorado', 'CO'), ('Connecticut', 'CT'), ('Delaware', 'DE'), ('District of Columbia', 'DC'), ('Florida', 'FL'), ('Georgia', 'GA'), ('Hawaii', 'HI'), ('Idaho', 'ID'), ('Illinois', 'IL'), ('Indiana', 'IN'), ('Iowa', 'IA'), ('Kansas', 'KS'), ('Kentucky', 'KY'), ('Louisiana', 'LA'), ('Maine', 'ME'), ('Maryland', 'MD'), ('Massachusetts', 'MA'), ('Michigan', 'MI'), ('Minnesota', 'MN'), ('Mississippi', 'MS'), ('Missouri', 'MO'), ('Montana', 'MT'), ('Nebraska', 'NE'), ('Nevada', 'NV'), ('New Hampshire', 'NH'), ('New Jersey', 'NJ'), ('New Mexico', 'NM'), ('New York', 'NY'), ('North Carolina', 'NC'), ('North Dakota', 'ND'), ('Ohio', 'OH'), ('Oklahoma', 'OK'), ('Oregon', 'OR'), ('Pennsylvania', 'PA'), ('Rhode Island', 'RI'), ('South Carolina', 'SC'), ('South Dakota', 'SD'), ('Tennessee', 'TN'), ('Texas', 'TX'), ('Utah', 'UT'), ('Vermont', 'VT'), ('Virginia', 'VA'), ('Washington', 'WA'), ('West Virginia', 'WV'), ('Wisconsin', 'WI'), ('Wyoming', 'WY');

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

INSERT INTO grade_years (grade_level, school_year, authorized_minutes_per_year) VALUES ('Kindergarten', '19-20', 356*60), ('1', '19-20', 712*60), ('2', '19-20', 712*60), ('3', '19-20', 712*60), ('4', '19-20', 890*60), ('5', '19-20', 890*60), ('6', '19-20', 890*60), ('7', '19-20', 1000*60), ('8', '19-20', 1000*60), ('9', '19-20', 900*60), ('10', '19-20', 900*60), ('11', '19-20', 900*60), ('12', '19-20', 900*60);

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
