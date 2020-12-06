--
-- PostgreSQL database dump
--

-- Dumped from database version 10.15 (Debian 10.15-1.pgdg90+1)
-- Dumped by pg_dump version 12.5 (Ubuntu 12.5-0ubuntu0.20.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: btree_gist; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;


--
-- Name: EXTENSION btree_gist; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION btree_gist IS 'support for indexing common datatypes in GiST';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: application_status; Type: TYPE; Schema: public; Owner: user
--

CREATE TYPE public.application_status AS ENUM (
    'not started',
    'saved for later',
    'submitted',
    'approved',
    'missing information',
    'not approved'
);


ALTER TYPE public.application_status OWNER TO "user";

--
-- Name: attendance_types; Type: TYPE; Schema: public; Owner: user
--

CREATE TYPE public.attendance_types AS ENUM (
    'Attendance',
    'Supplemental'
);


ALTER TYPE public.attendance_types OWNER TO "user";

--
-- Name: grade_level; Type: TYPE; Schema: public; Owner: user
--

CREATE TYPE public.grade_level AS ENUM (
    'Kindergarten',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12'
);


ALTER TYPE public.grade_level OWNER TO "user";

--
-- Name: microschool_type; Type: TYPE; Schema: public; Owner: user
--

CREATE TYPE public.microschool_type AS ENUM (
    'Microschool',
    'Prenda Family'
);


ALTER TYPE public.microschool_type OWNER TO "user";

--
-- Name: school_year; Type: TYPE; Schema: public; Owner: user
--

CREATE TYPE public.school_year AS ENUM (
    '18-19',
    '19-20',
    '20-21'
);


ALTER TYPE public.school_year OWNER TO "user";

--
-- Name: upsert_grade_enrollments(uuid, uuid, daterange); Type: FUNCTION; Schema: public; Owner: user
--

CREATE FUNCTION public.upsert_grade_enrollments(_student_id uuid, _grade_years_id uuid, _during daterange) RETURNS void
    LANGUAGE plpgsql
    AS $$ BEGIN LOOP UPDATE grade_enrollments SET grade_years_id = _grade_years_id WHERE student_id = _student_id AND during = _during; IF found THEN RETURN; END IF; BEGIN INSERT INTO grade_enrollments ( student_id , grade_years_id , during) VALUES ( _student_id , _grade_years_id , _during); RETURN; END; END LOOP; END; $$;


ALTER FUNCTION public.upsert_grade_enrollments(_student_id uuid, _grade_years_id uuid, _during daterange) OWNER TO "user";

--
-- Name: upsert_microschool_enrollments(uuid, uuid, integer, integer, daterange); Type: FUNCTION; Schema: public; Owner: user
--

CREATE FUNCTION public.upsert_microschool_enrollments(_student_id uuid, _microschool_term_id uuid, _authorized_minutes integer, _cents_per_minute integer, _during daterange) RETURNS void
    LANGUAGE plpgsql
    AS $$ BEGIN LOOP UPDATE microschool_enrollments SET authorized_minutes = _authorized_minutes , cents_per_minute = _cents_per_minute WHERE student_id = _student_id AND microschool_term_id = _microschool_term_id AND during = _during; IF found THEN RETURN; END IF; BEGIN INSERT INTO microschool_enrollments ( student_id , microschool_term_id , authorized_minutes , cents_per_minute , during) VALUES ( _student_id , _microschool_term_id , _authorized_minutes , _cents_per_minute , _during); RETURN; END; END LOOP; END; $$;


ALTER FUNCTION public.upsert_microschool_enrollments(_student_id uuid, _microschool_term_id uuid, _authorized_minutes integer, _cents_per_minute integer, _during daterange) OWNER TO "user";

--
-- Name: upsert_microschool_terms(uuid, public.grade_level, public.grade_level, integer, public.microschool_type, daterange, boolean, boolean, boolean); Type: FUNCTION; Schema: public; Owner: user
--

CREATE FUNCTION public.upsert_microschool_terms(_microschool_id uuid, _min_grade public.grade_level, _max_grade public.grade_level, _capacity integer, _type public.microschool_type, _during daterange, _accepting_students boolean, _accepting_students_aug_2020 boolean, _publicly_visible boolean) RETURNS void
    LANGUAGE plpgsql
    AS $$ BEGIN LOOP UPDATE microschool_terms SET min_grade = _min_grade , max_grade = _max_grade , capacity = _capacity , type = _type , accepting_students = _accepting_students , accepting_students_aug_2020 = _accepting_students_aug_2020 , publicly_visible = _publicly_visible WHERE microschool_id = _microschool_id AND during = _during; IF found THEN RETURN; END IF; BEGIN INSERT INTO microschool_terms ( microschool_id , min_grade , max_grade , capacity , type , during , accepting_students , accepting_students_aug_2020 , publicly_visible) VALUES ( _microschool_id , _min_grade , _max_grade , _capacity , _type , _during , _accepting_students , _accepting_students_aug_2020 , _publicly_visible); RETURN; END; END LOOP; END; $$;


ALTER FUNCTION public.upsert_microschool_terms(_microschool_id uuid, _min_grade public.grade_level, _max_grade public.grade_level, _capacity integer, _type public.microschool_type, _during daterange, _accepting_students boolean, _accepting_students_aug_2020 boolean, _publicly_visible boolean) OWNER TO "user";

--
-- Name: valid_grade_enrollment(daterange, uuid); Type: FUNCTION; Schema: public; Owner: user
--

CREATE FUNCTION public.valid_grade_enrollment(_during daterange, _grade_years_id uuid) RETURNS boolean
    LANGUAGE plpgsql
    AS $$ BEGIN RETURN (SELECT CASE WHEN EXTRACT(YEAR FROM LOWER(DATERANGE(_during)))::TEXT = ('20' || (SUBSTRING(school_year::TEXT,0,POSITION('-' IN school_year::TEXT)))) AND EXTRACT(YEAR FROM UPPER(DATERANGE(_during)))::TEXT = ('20' || (SUBSTRING(school_year::TEXT,POSITION('-' IN school_year::TEXT)+1,2))) THEN TRUE ELSE FALSE END FROM grade_years WHERE _grade_years_id = id); END; $$;


ALTER FUNCTION public.valid_grade_enrollment(_during daterange, _grade_years_id uuid) OWNER TO "user";

SET default_tablespace = '';

--
-- Name: adults; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.adults (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    prefix text,
    first_name text NOT NULL,
    middle_name text,
    last_name text NOT NULL,
    suffix text,
    email text NOT NULL,
    phone text,
    address_1 text,
    address_2 text,
    city text,
    state text,
    zip5 text,
    zip4 text,
    is_guide boolean DEFAULT false NOT NULL,
    is_guardian boolean DEFAULT false NOT NULL,
    zoho_id text,
    pw_id text,
    temp_lead_guide boolean
);


ALTER TABLE public.adults OWNER TO "user";

--
-- Name: applications; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.applications (
    id integer NOT NULL,
    application_status public.application_status NOT NULL,
    zoho_student_id text NOT NULL,
    school_year text NOT NULL,
    zoho_microschool_id text,
    funding_source text,
    document jsonb,
    files jsonb
);


ALTER TABLE public.applications OWNER TO "user";

--
-- Name: applications_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.applications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.applications_id_seq OWNER TO "user";

--
-- Name: applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.applications_id_seq OWNED BY public.applications.id;


--
-- Name: attendance; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.attendance (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    student_id uuid NOT NULL,
    attendance_date date NOT NULL,
    attendance_type public.attendance_types NOT NULL,
    minutes integer NOT NULL,
    approved_email text,
    approved_at_utc timestamp without time zone,
    approved_ip text
);


ALTER TABLE public.attendance OWNER TO "user";

--
-- Name: data_exceptions; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.data_exceptions (
    id integer NOT NULL,
    data_source text,
    data_process text,
    details jsonb,
    fixed boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.data_exceptions OWNER TO "user";

--
-- Name: data_exceptions_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.data_exceptions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.data_exceptions_id_seq OWNER TO "user";

--
-- Name: data_exceptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.data_exceptions_id_seq OWNED BY public.data_exceptions.id;


--
-- Name: edkey_attendance_comparison; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.edkey_attendance_comparison (
    year_month text,
    "Status" text,
    "PrendaWorldID" text,
    "PrendaWorldName" text,
    "SequoiaStudentID" text,
    "SequoiaName" text,
    "PrendaClassType" text,
    "SequoiaSectionID" text,
    "Date" date,
    "PrendaMinutes" integer,
    "SequoiaMinutes" integer,
    last_run_time timestamp without time zone
);


ALTER TABLE public.edkey_attendance_comparison OWNER TO "user";

--
-- Name: edkey_attendance_dump; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.edkey_attendance_dump (
    year_month text,
    "Student Number" text,
    "RecordID" text,
    "Date" date,
    "Attendance" integer,
    "Student" text,
    "SectionID" text,
    "Class" text,
    "LMS ID" text,
    "Modified on" text,
    "Synced on" text,
    "Absent" text,
    "Approved" text,
    "Reason" text,
    "StudentID" text,
    "SchoolID" text
);


ALTER TABLE public.edkey_attendance_dump OWNER TO "user";

--
-- Name: edkey_course_enrollments_dump; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.edkey_course_enrollments_dump (
    sectionid integer,
    course_name text,
    start_date date,
    end_date date,
    studentid integer
);


ALTER TABLE public.edkey_course_enrollments_dump OWNER TO "user";

--
-- Name: edkey_students_dump; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.edkey_students_dump (
    "ELMS_StudentID" text,
    "PS_StudentID" text,
    "PS_StudentNumber" text,
    last_name text,
    first_name text,
    site text,
    entry_date date,
    exit_date date,
    grade_level text,
    date1 date,
    date2 date,
    date date,
    total_minutes integer,
    date_generated text
);


ALTER TABLE public.edkey_students_dump OWNER TO "user";

--
-- Name: fountain_dump; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.fountain_dump (
    id integer NOT NULL,
    dumped_at timestamp without time zone DEFAULT now(),
    pw_guide_id text,
    pw_microschool_id text,
    pw_microschool_id_bad text,
    zoho_guide_id text,
    zoho_microschool_id text,
    zoho_guide_microschool_id text,
    hub_guide_id text,
    hub_microschool_id text,
    hub_microschool_term_id text,
    hub_staffing_id text,
    email text,
    name text,
    first_name text,
    last_name text,
    phone_number text,
    normalized_phone_number text,
    data_guide_applicant_gatekeeping text,
    data_state text,
    data_guide_applicant_home_address text[],
    data_guide_applicant_microschool_address text[],
    data_microschool_zipcode text,
    data_guide_applicant_grade_interest text[],
    data_guide_applicant_guide_motivation text,
    data_guide_applicant_experience_with_children text,
    data_guide_applicant_experience_type text[],
    data_guide_applicant_teaching_children text,
    data_guide_applicant_student_management text,
    data_guide_applicant_conflict_resolution text,
    data_guide_applicant_difficult_learning text,
    data_guide_applicant_student_recruitment text,
    data_bgc_house_member_email_1 text,
    data_bgc_house_member_email_2 text,
    data_bgc_house_member_email_3 text,
    data_guide_applicant_cpr_issue_date text,
    data_guide_applicant_cpr_upload text,
    data_guide_applicant_cv_change text,
    data_guide_applicant_cv_covid text,
    data_guide_applicant_cv_difficult_thing text,
    data_guide_applicant_cv_experiences text,
    data_guide_applicant_cv_guide_intention text,
    data_guide_applicant_cv_hardest_learning text,
    data_guide_applicant_cv_leadership text,
    data_guide_applicant_cv_motivation text,
    data_guide_applicant_cv_others_describe text,
    data_guide_applicant_cv_powerful_experience text,
    data_guide_applicant_cv_situation_right_over_easy text,
    data_guide_applicant_cv_taught_new text,
    data_guide_applicant_cv_trust text,
    data_guide_applicant_cv_well_equipped text,
    data_guide_applicant_educator_experience text,
    data_guide_applicant_email text,
    data_guide_applicant_experience_description text,
    data_guide_applicant_fingerprint_expiration text,
    data_guide_applicant_fingerprint_upload text,
    data_guide_applicant_first_name text,
    data_guide_applicant_last_name text,
    data_guide_applicant_pe_conflict_resolution text,
    data_guide_applicant_pe_difficult_learning text,
    data_guide_applicant_pe_student_behavior text,
    data_guide_applicant_pe_student_learning text,
    data_guide_applicant_pe_student_management text,
    data_guide_applicant_pe_student_progress text,
    data_guide_applicant_references_one text,
    data_guide_applicant_references_two text,
    data_guide_applicant_virtual_site_inspection_url text,
    data_utm_source text,
    created_at text,
    updated_at text,
    receive_automated_emails boolean,
    labels text[],
    is_duplicate boolean,
    file_upload_requests text[],
    lessonly_lesson_results text[],
    lessonly_path_results text[],
    lessonly_course_results text[],
    addresses text[],
    fountain_id text,
    last_transitioned_at text,
    background_checks text[],
    document_signatures text[],
    document_uploads text[],
    zipcode text,
    funnel_title text,
    funnel_custom_id text,
    funnel_id text,
    funnel_location_name text,
    funnel_location_id text,
    funnel_location_latitude real,
    funnel_location_longitude real,
    funnel_location_location_group_name text,
    funnel_location_location_group_id text,
    stage_title text,
    stage_id text,
    stage_parent_id text,
    score_cards_results text[]
);


ALTER TABLE public.fountain_dump OWNER TO "user";

--
-- Name: fountain_dump_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.fountain_dump_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fountain_dump_id_seq OWNER TO "user";

--
-- Name: fountain_dump_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.fountain_dump_id_seq OWNED BY public.fountain_dump.id;


--
-- Name: funding_source_enrollments; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.funding_source_enrollments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    student_id uuid NOT NULL,
    during daterange NOT NULL,
    funding_source_id uuid,
    registration_id uuid NOT NULL
);


ALTER TABLE public.funding_source_enrollments OWNER TO "user";

--
-- Name: funding_source_registrations; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.funding_source_registrations (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    student_id uuid NOT NULL,
    funding_source_student_id integer,
    funding_source_student_number integer,
    funding_source_id uuid NOT NULL
);


ALTER TABLE public.funding_source_registrations OWNER TO "user";

--
-- Name: funding_sources; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.funding_sources (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    account_number text,
    name text NOT NULL,
    student_cap integer
);


ALTER TABLE public.funding_sources OWNER TO "user";

--
-- Name: globals; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.globals (
    key text NOT NULL,
    document jsonb
);


ALTER TABLE public.globals OWNER TO "user";

--
-- Name: grade_enrollments; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.grade_enrollments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    student_id uuid NOT NULL,
    grade_years_id uuid NOT NULL,
    during daterange NOT NULL,
    CONSTRAINT during_grade_year CHECK (public.valid_grade_enrollment(during, grade_years_id))
);


ALTER TABLE public.grade_enrollments OWNER TO "user";

--
-- Name: grade_years; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.grade_years (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    grade_level public.grade_level NOT NULL,
    school_year public.school_year NOT NULL,
    state uuid,
    authorized_minutes_per_year integer NOT NULL
);


ALTER TABLE public.grade_years OWNER TO "user";

--
-- Name: guide_mentors; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.guide_mentors (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    guide_id uuid NOT NULL,
    mentor_id uuid NOT NULL
);


ALTER TABLE public.guide_mentors OWNER TO "user";

--
-- Name: microschool_enrollments; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.microschool_enrollments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    student_id uuid NOT NULL,
    microschool_term_id uuid NOT NULL,
    authorized_minutes integer,
    cents_per_minute integer,
    during daterange NOT NULL,
    CONSTRAINT microschool_enrollments_cents_per_minute_check CHECK ((cents_per_minute > 0))
);


ALTER TABLE public.microschool_enrollments OWNER TO "user";

--
-- Name: microschool_terms; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.microschool_terms (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    microschool_id uuid,
    min_grade public.grade_level,
    max_grade public.grade_level,
    capacity integer,
    type public.microschool_type NOT NULL,
    during daterange NOT NULL,
    accepting_students boolean,
    accepting_students_aug_2020 boolean,
    publicly_visible boolean
);


ALTER TABLE public.microschool_terms OWNER TO "user";

--
-- Name: microschools; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.microschools (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name text NOT NULL,
    phone text,
    address_1 text,
    address_2 text,
    city text,
    state uuid,
    zip5 text,
    zip4 text,
    mailing_address_1 text,
    mailing_address_2 text,
    mailing_city text,
    mailing_state uuid,
    mailing_zip5 text,
    mailing_zip4 text,
    zoho_id text,
    airtable_id text,
    pw_id text,
    status text,
    club_id text
);


ALTER TABLE public.microschools OWNER TO "user";

--
-- Name: migrations; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.migrations (
    version integer,
    "time" timestamp without time zone
);


ALTER TABLE public.migrations OWNER TO "user";

--
-- Name: prendaworld_attendance_dump; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.prendaworld_attendance_dump (
    year_month text,
    partner text,
    "Student" text,
    "PrendaWorldID" text,
    "SequoiaID" text,
    "Grade" text,
    "Type" text,
    date date,
    minutes integer
);


ALTER TABLE public.prendaworld_attendance_dump OWNER TO "user";

--
-- Name: private_funding_sources; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.private_funding_sources (
    subscription_id text,
    status text,
    customer_id text,
    adult_id uuid
)
INHERITS (public.funding_sources);


ALTER TABLE public.private_funding_sources OWNER TO "user";

--
-- Name: pw_enrollments; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.pw_enrollments (
    id integer NOT NULL,
    pw_student_id integer NOT NULL,
    pw_microschool_id integer NOT NULL,
    authorized_minutes integer,
    cents_per_minute integer,
    during daterange NOT NULL
);


ALTER TABLE public.pw_enrollments OWNER TO "user";

--
-- Name: pw_enrollments_dump; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.pw_enrollments_dump (
    id integer NOT NULL,
    "StudentID" text,
    "School ID" text,
    "Start Date" date,
    "End Date" date,
    "Hours" text,
    "Funding Source" text
);


ALTER TABLE public.pw_enrollments_dump OWNER TO "user";

--
-- Name: pw_enrollments_dump_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.pw_enrollments_dump_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pw_enrollments_dump_id_seq OWNER TO "user";

--
-- Name: pw_enrollments_dump_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.pw_enrollments_dump_id_seq OWNED BY public.pw_enrollments_dump.id;


--
-- Name: pw_enrollments_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.pw_enrollments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pw_enrollments_id_seq OWNER TO "user";

--
-- Name: pw_enrollments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.pw_enrollments_id_seq OWNED BY public.pw_enrollments.id;


--
-- Name: pw_exceptions; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.pw_exceptions (
    id integer NOT NULL,
    insert_report text NOT NULL,
    data json NOT NULL
);


ALTER TABLE public.pw_exceptions OWNER TO "user";

--
-- Name: pw_exceptions_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.pw_exceptions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pw_exceptions_id_seq OWNER TO "user";

--
-- Name: pw_exceptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.pw_exceptions_id_seq OWNED BY public.pw_exceptions.id;


--
-- Name: pw_guides_dump; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.pw_guides_dump (
    id integer NOT NULL,
    "Last Name" text,
    "First Name" text,
    "Email" text,
    "Prenda ID" text,
    "School IDs" text
);


ALTER TABLE public.pw_guides_dump OWNER TO "user";

--
-- Name: pw_guides_dump_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.pw_guides_dump_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pw_guides_dump_id_seq OWNER TO "user";

--
-- Name: pw_guides_dump_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.pw_guides_dump_id_seq OWNED BY public.pw_guides_dump.id;


--
-- Name: pw_microschools_dump; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.pw_microschools_dump (
    id integer NOT NULL,
    "ID" text,
    "Name" text,
    "Nickname" text,
    "Type" text,
    "Active" text,
    "Date Created" text,
    "Test Students" text,
    "Kindergarten" text,
    "1st" text,
    "2nd" text,
    "3rd" text,
    "4th" text,
    "5th" text,
    "6th" text,
    "7th" text,
    "8th" text,
    "Other" text,
    "Mongo _id" text
);


ALTER TABLE public.pw_microschools_dump OWNER TO "user";

--
-- Name: pw_microschools_dump_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.pw_microschools_dump_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pw_microschools_dump_id_seq OWNER TO "user";

--
-- Name: pw_microschools_dump_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.pw_microschools_dump_id_seq OWNED BY public.pw_microschools_dump.id;


--
-- Name: pw_students_dump; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.pw_students_dump (
    id integer NOT NULL,
    "Last Name" text,
    "First Name" text,
    "Prenda ID" text,
    "Sequoia ID" text,
    "Enrolled Grade" text,
    "School ID" text,
    "School Name" text,
    "Test Account" text
);


ALTER TABLE public.pw_students_dump OWNER TO "user";

--
-- Name: pw_students_dump_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.pw_students_dump_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pw_students_dump_id_seq OWNER TO "user";

--
-- Name: pw_students_dump_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.pw_students_dump_id_seq OWNED BY public.pw_students_dump.id;


--
-- Name: pw_subscriptions_dump; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.pw_subscriptions_dump (
    "School Id" text,
    "Mongo _id" text,
    "Adult Id" text,
    "Customer Stripe Id" text,
    "Expiration" date,
    "Last Paid Date" date,
    "Paid Amount" integer,
    "Subscription Status" text,
    "School Type" text
);


ALTER TABLE public.pw_subscriptions_dump OWNER TO "user";

--
-- Name: relationships; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.relationships (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    guardian_id uuid NOT NULL,
    student_id uuid NOT NULL,
    notes text NOT NULL
);


ALTER TABLE public.relationships OWNER TO "user";

--
-- Name: session; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.session (
    sid character varying NOT NULL,
    sess json NOT NULL,
    expire timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.session OWNER TO "user";

--
-- Name: staffing; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.staffing (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    microschool_terms_id uuid NOT NULL,
    guide_id uuid NOT NULL,
    is_lead_guide boolean NOT NULL
);


ALTER TABLE public.staffing OWNER TO "user";

--
-- Name: states; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.states (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    state_name text,
    state_abbrev character(2)
);


ALTER TABLE public.states OWNER TO "user";

--
-- Name: students; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.students (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    prefix text,
    first_name text NOT NULL,
    middle_name text,
    last_name text,
    preferred_first_name text,
    suffix text,
    birth_date date,
    email text,
    phone text,
    address_1 text,
    address_2 text,
    city text,
    state uuid,
    zip5 text,
    zip4 text,
    sais_id text,
    airtable_id text,
    zoho_id text,
    pw_id text,
    birth_state uuid,
    birth_country text,
    last_school text,
    last_school_address text,
    last_school_phone text,
    last_grade_completed public.grade_level,
    desired_start_date text,
    has_been_expelled boolean,
    lacks_nighttime_residence boolean,
    health_problems text,
    on_daily_medication boolean,
    medications text,
    medications_needed_during_school text,
    surgeries_accidents_injuries_past_year text,
    food_allergies text,
    medication_or_other_allergies text,
    family_doctor text,
    family_doctor_phone text,
    accept_medical_release boolean,
    proof_of_residence bytea,
    birth_certificate bytea,
    immunization_record bytea,
    primary_language_at_home text,
    language_spoken_most_often text,
    language_first_acquired text,
    race text,
    receives_special_education boolean,
    date_of_last_iep date,
    last_iep bytea,
    parent_info text,
    new_enrollment boolean,
    typeform_microschool text,
    submitted boolean,
    referred_by text,
    desired_guide text,
    video_release boolean,
    emergency_contact_name_1 text,
    emergency_contact_phone_1 text,
    emergency_contact_relationship_1 text,
    emergency_contact_name_2 text,
    emergency_contact_phone_2 text,
    emergency_contact_relationship_2 text,
    mother_guardian_name text,
    mother_guardian_phone text,
    mother_guardian_email text,
    mother_guardian_employer text,
    mother_guardian_relationship text,
    father_guardian_name text,
    father_guardian_phone text,
    father_guardian_email text,
    father_guardian_employer text,
    father_guardian_relationship text,
    gender text,
    typeform_id text,
    prenda_enrollment_date date,
    sequoia_entry_date date,
    status text,
    is_esa boolean,
    recruited_by text,
    withdrawal_note text,
    withdrawal_reason text,
    enrolled_in_sequoia text
);


ALTER TABLE public.students OWNER TO "user";

--
-- Name: temp_guides; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.temp_guides (
    id integer NOT NULL,
    pw_user_id text NOT NULL,
    bio text,
    photo text
);


ALTER TABLE public.temp_guides OWNER TO "user";

--
-- Name: temp_guides_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.temp_guides_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.temp_guides_id_seq OWNER TO "user";

--
-- Name: temp_guides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.temp_guides_id_seq OWNED BY public.temp_guides.id;


--
-- Name: temp_microschool_location; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.temp_microschool_location (
    id integer NOT NULL,
    microschool_zoho_id text NOT NULL,
    latitude text,
    longitude text,
    city text
);


ALTER TABLE public.temp_microschool_location OWNER TO "user";

--
-- Name: temp_microschool_location_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.temp_microschool_location_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.temp_microschool_location_id_seq OWNER TO "user";

--
-- Name: temp_microschool_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.temp_microschool_location_id_seq OWNED BY public.temp_microschool_location.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username text NOT NULL,
    pwdhash text NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    email text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    is_admin boolean DEFAULT false NOT NULL,
    expiration timestamp without time zone,
    CONSTRAINT users_check_empty_strings CHECK (((username <> ''::text) AND (pwdhash <> ''::text) AND (first_name <> ''::text) AND (last_name <> ''::text) AND (email <> ''::text)))
);


ALTER TABLE public.users OWNER TO "user";

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO "user";

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: zoho_exceptions; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.zoho_exceptions (
    id integer NOT NULL,
    insert_report text NOT NULL,
    data json NOT NULL,
    error json
);


ALTER TABLE public.zoho_exceptions OWNER TO "user";

--
-- Name: zoho_exceptions_id_seq; Type: SEQUENCE; Schema: public; Owner: user
--

CREATE SEQUENCE public.zoho_exceptions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.zoho_exceptions_id_seq OWNER TO "user";

--
-- Name: zoho_exceptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user
--

ALTER SEQUENCE public.zoho_exceptions_id_seq OWNED BY public.zoho_exceptions.id;


--
-- Name: applications id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.applications ALTER COLUMN id SET DEFAULT nextval('public.applications_id_seq'::regclass);


--
-- Name: data_exceptions id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.data_exceptions ALTER COLUMN id SET DEFAULT nextval('public.data_exceptions_id_seq'::regclass);


--
-- Name: fountain_dump id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.fountain_dump ALTER COLUMN id SET DEFAULT nextval('public.fountain_dump_id_seq'::regclass);


--
-- Name: private_funding_sources id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.private_funding_sources ALTER COLUMN id SET DEFAULT public.uuid_generate_v4();


--
-- Name: pw_enrollments id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.pw_enrollments ALTER COLUMN id SET DEFAULT nextval('public.pw_enrollments_id_seq'::regclass);


--
-- Name: pw_enrollments_dump id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.pw_enrollments_dump ALTER COLUMN id SET DEFAULT nextval('public.pw_enrollments_dump_id_seq'::regclass);


--
-- Name: pw_exceptions id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.pw_exceptions ALTER COLUMN id SET DEFAULT nextval('public.pw_exceptions_id_seq'::regclass);


--
-- Name: pw_guides_dump id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.pw_guides_dump ALTER COLUMN id SET DEFAULT nextval('public.pw_guides_dump_id_seq'::regclass);


--
-- Name: pw_microschools_dump id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.pw_microschools_dump ALTER COLUMN id SET DEFAULT nextval('public.pw_microschools_dump_id_seq'::regclass);


--
-- Name: pw_students_dump id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.pw_students_dump ALTER COLUMN id SET DEFAULT nextval('public.pw_students_dump_id_seq'::regclass);


--
-- Name: temp_guides id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.temp_guides ALTER COLUMN id SET DEFAULT nextval('public.temp_guides_id_seq'::regclass);


--
-- Name: temp_microschool_location id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.temp_microschool_location ALTER COLUMN id SET DEFAULT nextval('public.temp_microschool_location_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: zoho_exceptions id; Type: DEFAULT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.zoho_exceptions ALTER COLUMN id SET DEFAULT nextval('public.zoho_exceptions_id_seq'::regclass);


--
-- Name: adults adults_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.adults
    ADD CONSTRAINT adults_pkey PRIMARY KEY (id);


--
-- Name: adults adults_pw_id_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.adults
    ADD CONSTRAINT adults_pw_id_key UNIQUE (pw_id);


--
-- Name: adults adults_zoho_id_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.adults
    ADD CONSTRAINT adults_zoho_id_key UNIQUE (zoho_id);


--
-- Name: applications applications_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT applications_pkey PRIMARY KEY (id);


--
-- Name: applications applications_zoho_student_id_school_year_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT applications_zoho_student_id_school_year_key UNIQUE (zoho_student_id, school_year);


--
-- Name: applications applications_zoho_student_id_zoho_microschool_id_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT applications_zoho_student_id_zoho_microschool_id_key UNIQUE (zoho_student_id, zoho_microschool_id);


--
-- Name: attendance attendance_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_pkey PRIMARY KEY (id);


--
-- Name: attendance attendance_student_id_attendance_date_attendance_type_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_student_id_attendance_date_attendance_type_key UNIQUE (student_id, attendance_date, attendance_type);


--
-- Name: edkey_attendance_comparison edkey_attendance_comparison_SequoiaStudentID_SequoiaSection_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.edkey_attendance_comparison
    ADD CONSTRAINT "edkey_attendance_comparison_SequoiaStudentID_SequoiaSection_key" UNIQUE ("SequoiaStudentID", "SequoiaSectionID", "Date");


--
-- Name: fountain_dump fountain_dump_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.fountain_dump
    ADD CONSTRAINT fountain_dump_pkey PRIMARY KEY (id);


--
-- Name: funding_source_enrollments funding_source_enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.funding_source_enrollments
    ADD CONSTRAINT funding_source_enrollments_pkey PRIMARY KEY (id);


--
-- Name: funding_source_enrollments funding_source_enrollments_student_id_during_excl; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.funding_source_enrollments
    ADD CONSTRAINT funding_source_enrollments_student_id_during_excl EXCLUDE USING gist (student_id WITH =, during WITH &&);


--
-- Name: funding_source_registrations funding_source_registrations_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.funding_source_registrations
    ADD CONSTRAINT funding_source_registrations_pkey PRIMARY KEY (id);


--
-- Name: funding_sources funding_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.funding_sources
    ADD CONSTRAINT funding_sources_pkey PRIMARY KEY (id);


--
-- Name: globals globals_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.globals
    ADD CONSTRAINT globals_pkey PRIMARY KEY (key);


--
-- Name: grade_enrollments grade_enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.grade_enrollments
    ADD CONSTRAINT grade_enrollments_pkey PRIMARY KEY (id);


--
-- Name: grade_enrollments grade_enrollments_student_id_during_excl; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.grade_enrollments
    ADD CONSTRAINT grade_enrollments_student_id_during_excl EXCLUDE USING gist (student_id WITH =, during WITH &&);


--
-- Name: grade_years grade_years_grade_level_school_year_state_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.grade_years
    ADD CONSTRAINT grade_years_grade_level_school_year_state_key UNIQUE (grade_level, school_year, state);


--
-- Name: grade_years grade_years_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.grade_years
    ADD CONSTRAINT grade_years_pkey PRIMARY KEY (id);


--
-- Name: guide_mentors guide_mentors_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.guide_mentors
    ADD CONSTRAINT guide_mentors_pkey PRIMARY KEY (id);


--
-- Name: microschool_enrollments microschool_enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.microschool_enrollments
    ADD CONSTRAINT microschool_enrollments_pkey PRIMARY KEY (id);


--
-- Name: microschool_enrollments microschool_enrollments_student_id_during_excl; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.microschool_enrollments
    ADD CONSTRAINT microschool_enrollments_student_id_during_excl EXCLUDE USING gist (student_id WITH =, during WITH &&);


--
-- Name: microschool_terms microschool_terms_microschool_id_during_excl; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.microschool_terms
    ADD CONSTRAINT microschool_terms_microschool_id_during_excl EXCLUDE USING gist (microschool_id WITH =, during WITH &&);


--
-- Name: microschool_terms microschool_terms_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.microschool_terms
    ADD CONSTRAINT microschool_terms_pkey PRIMARY KEY (id);


--
-- Name: microschools microschools_airtable_id_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.microschools
    ADD CONSTRAINT microschools_airtable_id_key UNIQUE (airtable_id);


--
-- Name: microschools microschools_name_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.microschools
    ADD CONSTRAINT microschools_name_key UNIQUE (name);


--
-- Name: microschools microschools_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.microschools
    ADD CONSTRAINT microschools_pkey PRIMARY KEY (id);


--
-- Name: microschools microschools_pw_id_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.microschools
    ADD CONSTRAINT microschools_pw_id_key UNIQUE (pw_id);


--
-- Name: microschools microschools_zoho_id_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.microschools
    ADD CONSTRAINT microschools_zoho_id_key UNIQUE (zoho_id);


--
-- Name: migrations migrations_time_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_time_key UNIQUE ("time");


--
-- Name: staffing one_lead_guide_per_microschool; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.staffing
    ADD CONSTRAINT one_lead_guide_per_microschool EXCLUDE USING gist (microschool_terms_id WITH =) WHERE ((is_lead_guide IS TRUE));


--
-- Name: pw_enrollments_dump pw_enrollments_dump_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.pw_enrollments_dump
    ADD CONSTRAINT pw_enrollments_dump_pkey PRIMARY KEY (id);


--
-- Name: pw_enrollments pw_enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.pw_enrollments
    ADD CONSTRAINT pw_enrollments_pkey PRIMARY KEY (id);


--
-- Name: pw_enrollments pw_enrollments_pw_student_id_during_excl; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.pw_enrollments
    ADD CONSTRAINT pw_enrollments_pw_student_id_during_excl EXCLUDE USING gist (pw_student_id WITH =, during WITH &&);


--
-- Name: pw_exceptions pw_exceptions_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.pw_exceptions
    ADD CONSTRAINT pw_exceptions_pkey PRIMARY KEY (id);


--
-- Name: pw_guides_dump pw_guides_dump_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.pw_guides_dump
    ADD CONSTRAINT pw_guides_dump_pkey PRIMARY KEY (id);


--
-- Name: pw_microschools_dump pw_microschools_dump_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.pw_microschools_dump
    ADD CONSTRAINT pw_microschools_dump_pkey PRIMARY KEY (id);


--
-- Name: pw_students_dump pw_students_dump_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.pw_students_dump
    ADD CONSTRAINT pw_students_dump_pkey PRIMARY KEY (id);


--
-- Name: relationships relationships_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.relationships
    ADD CONSTRAINT relationships_pkey PRIMARY KEY (id);


--
-- Name: session session_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_pkey PRIMARY KEY (sid);


--
-- Name: staffing staffing_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.staffing
    ADD CONSTRAINT staffing_pkey PRIMARY KEY (id);


--
-- Name: states states_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.states
    ADD CONSTRAINT states_pkey PRIMARY KEY (id);


--
-- Name: students students_airtable_id_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_airtable_id_key UNIQUE (airtable_id);


--
-- Name: students students_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_pkey PRIMARY KEY (id);


--
-- Name: students students_pw_id_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_pw_id_key UNIQUE (pw_id);


--
-- Name: students students_sais_id_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_sais_id_key UNIQUE (sais_id);


--
-- Name: students students_zoho_id_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_zoho_id_key UNIQUE (zoho_id);


--
-- Name: temp_guides temp_guides_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.temp_guides
    ADD CONSTRAINT temp_guides_pkey PRIMARY KEY (id);


--
-- Name: temp_guides temp_guides_pw_user_id_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.temp_guides
    ADD CONSTRAINT temp_guides_pw_user_id_key UNIQUE (pw_user_id);


--
-- Name: temp_microschool_location temp_microschool_location_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.temp_microschool_location
    ADD CONSTRAINT temp_microschool_location_pkey PRIMARY KEY (id);


--
-- Name: staffing unq_guide_per_microschool; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.staffing
    ADD CONSTRAINT unq_guide_per_microschool UNIQUE (microschool_terms_id, guide_id);


--
-- Name: guide_mentors unq_mentor_per_guide; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.guide_mentors
    ADD CONSTRAINT unq_mentor_per_guide UNIQUE (mentor_id, guide_id);


--
-- Name: funding_source_registrations unq_student_per_funding_source; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.funding_source_registrations
    ADD CONSTRAINT unq_student_per_funding_source UNIQUE (student_id, funding_source_id);


--
-- Name: private_funding_sources unq_subscription_id_per_name; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.private_funding_sources
    ADD CONSTRAINT unq_subscription_id_per_name UNIQUE (name, subscription_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: zoho_exceptions zoho_exceptions_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.zoho_exceptions
    ADD CONSTRAINT zoho_exceptions_pkey PRIMARY KEY (id);


--
-- Name: IDX_session_expire; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX "IDX_session_expire" ON public.session USING btree (expire);


--
-- Name: attendance attendance_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id);


--
-- Name: funding_source_enrollments funding_source_enrollments_funding_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.funding_source_enrollments
    ADD CONSTRAINT funding_source_enrollments_funding_source_id_fkey FOREIGN KEY (funding_source_id) REFERENCES public.funding_sources(id);


--
-- Name: funding_source_enrollments funding_source_enrollments_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.funding_source_enrollments
    ADD CONSTRAINT funding_source_enrollments_student_id_fkey FOREIGN KEY (student_id, funding_source_id) REFERENCES public.funding_source_registrations(student_id, funding_source_id);


--
-- Name: funding_source_registrations funding_source_registrations_funding_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.funding_source_registrations
    ADD CONSTRAINT funding_source_registrations_funding_source_id_fkey FOREIGN KEY (funding_source_id) REFERENCES public.funding_sources(id);


--
-- Name: funding_source_registrations funding_source_registrations_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.funding_source_registrations
    ADD CONSTRAINT funding_source_registrations_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id);


--
-- Name: grade_enrollments grade_enrollments_grade_years_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.grade_enrollments
    ADD CONSTRAINT grade_enrollments_grade_years_id_fkey FOREIGN KEY (grade_years_id) REFERENCES public.grade_years(id);


--
-- Name: grade_enrollments grade_enrollments_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.grade_enrollments
    ADD CONSTRAINT grade_enrollments_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id);


--
-- Name: grade_years grade_years_state_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.grade_years
    ADD CONSTRAINT grade_years_state_fkey FOREIGN KEY (state) REFERENCES public.states(id);


--
-- Name: guide_mentors guide_mentors_guide_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.guide_mentors
    ADD CONSTRAINT guide_mentors_guide_id_fkey FOREIGN KEY (guide_id) REFERENCES public.adults(id);


--
-- Name: guide_mentors guide_mentors_mentor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.guide_mentors
    ADD CONSTRAINT guide_mentors_mentor_id_fkey FOREIGN KEY (mentor_id) REFERENCES public.adults(id);


--
-- Name: microschool_enrollments microschool_enrollments_microschool_term_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.microschool_enrollments
    ADD CONSTRAINT microschool_enrollments_microschool_term_id_fkey FOREIGN KEY (microschool_term_id) REFERENCES public.microschool_terms(id);


--
-- Name: microschool_enrollments microschool_enrollments_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.microschool_enrollments
    ADD CONSTRAINT microschool_enrollments_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id);


--
-- Name: microschool_terms microschool_terms_microschool_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.microschool_terms
    ADD CONSTRAINT microschool_terms_microschool_id_fkey FOREIGN KEY (microschool_id) REFERENCES public.microschools(id);


--
-- Name: microschools microschools_mailing_state_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.microschools
    ADD CONSTRAINT microschools_mailing_state_fkey FOREIGN KEY (mailing_state) REFERENCES public.states(id);


--
-- Name: microschools microschools_state_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.microschools
    ADD CONSTRAINT microschools_state_fkey FOREIGN KEY (state) REFERENCES public.states(id);


--
-- Name: private_funding_sources private_funding_sources_adult_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.private_funding_sources
    ADD CONSTRAINT private_funding_sources_adult_id_fkey FOREIGN KEY (adult_id) REFERENCES public.adults(id);


--
-- Name: relationships relationships_guardian_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.relationships
    ADD CONSTRAINT relationships_guardian_id_fkey FOREIGN KEY (guardian_id) REFERENCES public.adults(id);


--
-- Name: relationships relationships_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.relationships
    ADD CONSTRAINT relationships_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id);


--
-- Name: staffing staffing_guide_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.staffing
    ADD CONSTRAINT staffing_guide_id_fkey FOREIGN KEY (guide_id) REFERENCES public.adults(id);


--
-- Name: staffing staffing_microschool_terms_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.staffing
    ADD CONSTRAINT staffing_microschool_terms_id_fkey FOREIGN KEY (microschool_terms_id) REFERENCES public.microschool_terms(id);


--
-- Name: students students_birth_state_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_birth_state_fkey FOREIGN KEY (birth_state) REFERENCES public.states(id);


--
-- Name: students students_state_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_state_fkey FOREIGN KEY (state) REFERENCES public.states(id);


--
-- PostgreSQL database dump complete
--

