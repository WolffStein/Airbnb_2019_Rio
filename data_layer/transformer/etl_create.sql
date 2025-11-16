-- etl_create.sql
-- DDL only: creates schema and tables for the Airbnb ETL.
-- Safe to run: this file drops & recreates the target tables.

BEGIN;

CREATE SCHEMA IF NOT EXISTS airbnb;

DROP TABLE IF EXISTS airbnb.staging_airbnb CASCADE;
CREATE TABLE airbnb.staging_airbnb (
    host_id TEXT,
    host_name TEXT,
    host_response_time TEXT,
    host_response_rate TEXT,
    host_is_superhost TEXT,
    host_listings_count TEXT,
    latitude TEXT,
    longitude TEXT,
    property_type TEXT,
    room_type TEXT,
    accommodates TEXT,
    bathrooms TEXT,
    bedrooms TEXT,
    beds TEXT,
    bed_type TEXT,
    price TEXT,
    security_deposit TEXT,
    cleaning_fee TEXT,
    guests_included TEXT,
    extra_people TEXT,
    minimum_nights TEXT,
    number_of_reviews TEXT,
    review_scores_rating TEXT,
    review_scores_accuracy TEXT,
    review_scores_cleanliness TEXT,
    review_scores_checkin TEXT,
    review_scores_communication TEXT,
    review_scores_location TEXT,
    review_scores_value TEXT,
    instant_bookable TEXT,
    is_business_travel_ready TEXT,
    cancellation_policy TEXT,
    ano TEXT,
    mes TEXT,
    n_amenities TEXT
);

DROP TABLE IF EXISTS airbnb.hosts CASCADE;
DROP TABLE IF EXISTS airbnb.dim_hosts CASCADE;
CREATE TABLE airbnb.dim_hosts (
    host_id BIGINT PRIMARY KEY,
    host_name TEXT,
    host_response_time TEXT,
    host_response_rate NUMERIC,
    host_is_superhost BOOLEAN,
    host_listings_count INT
);

DROP TABLE IF EXISTS airbnb.dim_locations CASCADE;
CREATE TABLE airbnb.dim_locations (
    id SERIAL PRIMARY KEY,
    latitude NUMERIC,
    longitude NUMERIC,
    UNIQUE(latitude, longitude)
);

DROP TABLE IF EXISTS airbnb.dim_properties CASCADE;
CREATE TABLE airbnb.dim_properties (
    id SERIAL PRIMARY KEY,
    -- store related ids as attributes only (star schema: dims are independent)
    host_id BIGINT,
    location_id INT,
    property_type TEXT,
    room_type TEXT,
    accommodates INT,
    bathrooms NUMERIC,
    bedrooms INT,
    beds INT,
    bed_type TEXT,
    instant_bookable BOOLEAN,
    is_business_travel_ready BOOLEAN,
    cancellation_policy TEXT,
    n_amenities INT,
    UNIQUE(host_id, location_id, property_type)
);

DROP TABLE IF EXISTS airbnb.dim_reviews CASCADE;
CREATE TABLE airbnb.dim_reviews (
    id SERIAL PRIMARY KEY,
    -- store related ids as attributes only (star schema: dims are independent)
    host_id BIGINT,
    property_id INT,
    number_of_reviews INT,
    review_scores_rating NUMERIC,
    review_scores_accuracy NUMERIC,
    review_scores_cleanliness NUMERIC,
    review_scores_checkin NUMERIC,
    review_scores_communication NUMERIC,
    review_scores_location NUMERIC,
    review_scores_value NUMERIC
);

CREATE INDEX IF NOT EXISTS idx_dim_properties_host_id ON airbnb.dim_properties(host_id);
CREATE INDEX IF NOT EXISTS idx_dim_properties_location_id ON airbnb.dim_properties(location_id);

-- Fact table that centralizes occurrences (moved columns from properties)
DROP TABLE IF EXISTS airbnb.fact_ocorrencias CASCADE;
CREATE TABLE airbnb.fact_ocorrencias (
    id SERIAL PRIMARY KEY,
    host_id BIGINT REFERENCES airbnb.dim_hosts(host_id) ON DELETE SET NULL,
    property_id INT REFERENCES airbnb.dim_properties(id) ON DELETE SET NULL,
    location_id INT REFERENCES airbnb.dim_locations(id) ON DELETE SET NULL,
    review_id INT REFERENCES airbnb.dim_reviews(id) ON DELETE SET NULL,
    price NUMERIC,
    security_deposit NUMERIC,
    cleaning_fee NUMERIC,
    guests_included INT,
    minimum_nights INT,
    ano INT,
    mes INT
);

COMMIT;

-- End of DDL
