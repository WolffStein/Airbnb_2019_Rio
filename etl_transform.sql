-- etl_transform.sql
-- Transform and load steps. Run this AFTER staging has been populated.

-- DIAGNOSTICS: print counts of candidate rows that would be inserted into dims/fact
-- This helps understand why dims/fact are empty after running the script.
SELECT 'staging_total' AS metric, COUNT(*) FROM airbnb.staging_airbnb;
SELECT 'candidate_dim_hosts' AS metric, COUNT(*) FROM (
    SELECT DISTINCT (NULLIF(trim(host_id),'')::numeric)::bigint AS host_key
    FROM airbnb.staging_airbnb
    WHERE NULLIF(trim(host_id),'') IS NOT NULL
) t;
SELECT 'candidate_dim_locations' AS metric, COUNT(*) FROM (
    SELECT DISTINCT NULLIF(trim(latitude),'')::numeric AS lat, NULLIF(trim(longitude),'')::numeric AS lon
    FROM airbnb.staging_airbnb
    WHERE NULLIF(trim(latitude),'') IS NOT NULL AND NULLIF(trim(longitude),'') IS NOT NULL
) t;
SELECT 'candidate_dim_properties' AS metric, COUNT(*) FROM (
    SELECT DISTINCT
        (NULLIF(trim(host_id),'')::numeric)::bigint AS host_key,
        NULLIF(trim(property_type),'') AS property_type,
        NULLIF(trim(latitude),'')::numeric AS lat,
        NULLIF(trim(longitude),'')::numeric AS lon
    FROM airbnb.staging_airbnb s
    WHERE NULLIF(trim(host_id),'') IS NOT NULL AND NULLIF(trim(property_type),'') IS NOT NULL
) t;
SELECT 'invalid_host_id_count' AS metric, COUNT(*) FROM airbnb.staging_airbnb WHERE trim(host_id) <> '' AND trim(host_id) !~ '^[0-9]+(\\.[0-9]+)?$';

-- NOTE: removed global transaction to avoid full rollback of earlier successful inserts

INSERT INTO airbnb.dim_hosts (host_id, host_name, host_response_time, host_response_rate, host_is_superhost, host_listings_count)
WITH host_src AS (
    SELECT
        (NULLIF(trim(host_id), '')::numeric)::bigint AS host_key,
        NULLIF(trim(host_name), '') AS host_name,
        NULLIF(trim(host_response_time), '') AS host_response_time,
        CASE WHEN trim(host_response_rate) = '' THEN NULL ELSE (regexp_replace(host_response_rate, '%', '', 'g'))::numeric END AS host_response_rate,
        CASE WHEN lower(trim(host_is_superhost)) IN ('t','true','1') THEN true WHEN lower(trim(host_is_superhost)) IN ('f','false','0') THEN false ELSE NULL END AS host_is_superhost,
        (NULLIF(trim(host_listings_count), '')::numeric)::int AS host_listings_count
    FROM airbnb.staging_airbnb s
    WHERE NULLIF(trim(host_id), '') IS NOT NULL
)
SELECT DISTINCT ON (host_key)
    host_key AS host_id,
    host_name,
    host_response_time,
    host_response_rate,
    host_is_superhost,
    host_listings_count
FROM host_src
ORDER BY host_key, host_listings_count DESC NULLS LAST
ON CONFLICT (host_id) DO UPDATE
    SET host_name = EXCLUDED.host_name
    -- you can add other updates if you want to refresh host metadata
;

-- 2) Insert locations (deduplicate by lat/lon)
INSERT INTO airbnb.dim_locations (latitude, longitude)
SELECT DISTINCT
    NULLIF(trim(latitude), '')::numeric AS latitude,
    NULLIF(trim(longitude), '')::numeric AS longitude
FROM airbnb.staging_airbnb s
WHERE NULLIF(trim(latitude), '') IS NOT NULL AND NULLIF(trim(longitude), '') IS NOT NULL
ON CONFLICT (latitude, longitude) DO NOTHING;

INSERT INTO airbnb.dim_properties (
    host_id, location_id, property_type, room_type, accommodates, bathrooms, bedrooms, beds, bed_type,
    instant_bookable, is_business_travel_ready, cancellation_policy, n_amenities)
SELECT
    CASE WHEN trim(s.host_id) = '' THEN NULL ELSE (NULLIF(trim(s.host_id), '')::numeric)::bigint END AS host_id,
    l.id AS location_id,
    NULLIF(trim(s.property_type), ''),
    NULLIF(trim(s.room_type), ''),
    (NULLIF(trim(s.accommodates), '')::numeric)::int,
    NULLIF(trim(s.bathrooms), '')::numeric,
    (NULLIF(trim(s.bedrooms), '')::numeric)::int,
    (NULLIF(trim(s.beds), '')::numeric)::int,
    NULLIF(trim(s.bed_type), ''),
    CASE WHEN lower(trim(s.instant_bookable)) IN ('t','true','1') THEN true WHEN lower(trim(s.instant_bookable)) IN ('f','false','0') THEN false ELSE NULL END,
    CASE WHEN lower(trim(s.is_business_travel_ready)) IN ('t','true','1') THEN true WHEN lower(trim(s.is_business_travel_ready)) IN ('f','false','0') THEN false ELSE NULL END,
    NULLIF(trim(s.cancellation_policy), ''),
    (NULLIF(trim(s.n_amenities), '')::numeric)::int
FROM airbnb.staging_airbnb s
LEFT JOIN airbnb.dim_locations l ON l.latitude = NULLIF(trim(s.latitude), '')::numeric AND l.longitude = NULLIF(trim(s.longitude), '')::numeric
ON CONFLICT (host_id, location_id, property_type) DO NOTHING;

-- 4) Insert reviews (one row per staging line; links host + property if possible)
INSERT INTO airbnb.dim_reviews (
    host_id, property_id, number_of_reviews, review_scores_rating, review_scores_accuracy, review_scores_cleanliness,
    review_scores_checkin, review_scores_communication, review_scores_location, review_scores_value)
SELECT
    CASE WHEN trim(s.host_id) = '' THEN NULL ELSE (NULLIF(trim(s.host_id), '')::numeric)::bigint END AS host_id,
    p.id AS property_id,
    (NULLIF(trim(s.number_of_reviews), '')::numeric)::int,
    NULLIF(trim(s.review_scores_rating), '')::numeric,
    NULLIF(trim(s.review_scores_accuracy), '')::numeric,
    NULLIF(trim(s.review_scores_cleanliness), '')::numeric,
    NULLIF(trim(s.review_scores_checkin), '')::numeric,
    NULLIF(trim(s.review_scores_communication), '')::numeric,
    NULLIF(trim(s.review_scores_location), '')::numeric,
    NULLIF(trim(s.review_scores_value), '')::numeric
FROM airbnb.staging_airbnb s
LEFT JOIN airbnb.dim_locations l ON l.latitude = NULLIF(trim(s.latitude), '')::numeric AND l.longitude = NULLIF(trim(s.longitude), '')::numeric
LEFT JOIN airbnb.dim_properties p ON p.location_id = l.id AND p.host_id = CASE WHEN trim(s.host_id) = '' THEN NULL ELSE (NULLIF(trim(s.host_id), '')::numeric)::bigint END
;

-- 5) Insert fact table occurrences (central star fact)
INSERT INTO airbnb.fact_ocorrencias (
    host_id, property_id, location_id, review_id,
    price, security_deposit, cleaning_fee, guests_included, minimum_nights, ano, mes
)
SELECT
    CASE WHEN trim(s.host_id) = '' THEN NULL ELSE (NULLIF(trim(s.host_id), '')::numeric)::bigint END AS host_id,
    p.id AS property_id,
    l.id AS location_id,
    r.id AS review_id,
    CASE WHEN trim(s.price) = '' THEN NULL ELSE regexp_replace(trim(s.price), '\\$', '', 'g')::numeric END,
    CASE WHEN trim(s.security_deposit) = '' THEN NULL ELSE regexp_replace(trim(s.security_deposit), '\\$', '', 'g')::numeric END,
    CASE WHEN trim(s.cleaning_fee) = '' THEN NULL ELSE regexp_replace(trim(s.cleaning_fee), '\\$', '', 'g')::numeric END,
    (NULLIF(trim(s.guests_included), '')::numeric)::int,
    (NULLIF(trim(s.minimum_nights), '')::numeric)::int,
    (NULLIF(trim(s.ano), '')::numeric)::int,
    (NULLIF(trim(s.mes), '')::numeric)::int
FROM airbnb.staging_airbnb s
LEFT JOIN airbnb.dim_locations l ON l.latitude = NULLIF(trim(s.latitude), '')::numeric AND l.longitude = NULLIF(trim(s.longitude), '')::numeric
LEFT JOIN airbnb.dim_properties p ON p.location_id = l.id AND p.host_id = CASE WHEN trim(s.host_id) = '' THEN NULL ELSE (NULLIF(trim(s.host_id), '')::numeric)::bigint END
LEFT JOIN airbnb.dim_reviews r ON r.property_id = p.id AND r.host_id = CASE WHEN trim(s.host_id) = '' THEN NULL ELSE (NULLIF(trim(s.host_id), '')::numeric)::bigint END
;

-- DIAGNOSTIC: count how many rows the fact SELECT would produce and show a sample
SELECT 'candidate_fact_rows' AS metric, COUNT(*) FROM (
    SELECT
        CASE WHEN trim(s.host_id) = '' THEN NULL ELSE (NULLIF(trim(s.host_id), '')::numeric)::bigint END AS host_id,
        p.id AS property_id,
        l.id AS location_id,
        r.id AS review_id,
        CASE WHEN trim(s.price) = '' THEN NULL ELSE regexp_replace(trim(s.price), '\\$', '', 'g')::numeric END AS price,
        CASE WHEN trim(s.security_deposit) = '' THEN NULL ELSE regexp_replace(trim(s.security_deposit), '\\$', '', 'g')::numeric END AS security_deposit,
        CASE WHEN trim(s.cleaning_fee) = '' THEN NULL ELSE regexp_replace(trim(s.cleaning_fee), '\\$', '', 'g')::numeric END AS cleaning_fee,
        (NULLIF(trim(s.guests_included), '')::numeric)::int AS guests_included,
        (NULLIF(trim(s.minimum_nights), '')::numeric)::int AS minimum_nights,
        (NULLIF(trim(s.ano), '')::numeric)::int AS ano,
        (NULLIF(trim(s.mes), '')::numeric)::int AS mes
    FROM airbnb.staging_airbnb s
    LEFT JOIN airbnb.dim_locations l ON l.latitude = NULLIF(trim(s.latitude), '')::numeric AND l.longitude = NULLIF(trim(s.longitude), '')::numeric
    LEFT JOIN airbnb.dim_properties p ON p.location_id = l.id AND p.host_id = CASE WHEN trim(s.host_id) = '' THEN NULL ELSE (NULLIF(trim(s.host_id), '')::numeric)::bigint END
    LEFT JOIN airbnb.dim_reviews r ON r.property_id = p.id AND r.host_id = CASE WHEN trim(s.host_id) = '' THEN NULL ELSE (NULLIF(trim(s.host_id), '')::numeric)::bigint END
) t;

-- DIAGNOSTIC: show a sample of candidate fact rows
SELECT
    CASE WHEN trim(s.host_id) = '' THEN NULL ELSE (NULLIF(trim(s.host_id), '')::numeric)::bigint END AS host_id,
    p.id AS property_id,
    l.id AS location_id,
    r.id AS review_id,
    CASE WHEN trim(s.price) = '' THEN NULL ELSE regexp_replace(trim(s.price), '\\$', '', 'g')::numeric END AS price,
    CASE WHEN trim(s.security_deposit) = '' THEN NULL ELSE regexp_replace(trim(s.security_deposit), '\\$', '', 'g')::numeric END AS security_deposit,
    CASE WHEN trim(s.cleaning_fee) = '' THEN NULL ELSE regexp_replace(trim(s.cleaning_fee), '\\$', '', 'g')::numeric END AS cleaning_fee,
    (NULLIF(trim(s.guests_included), '')::numeric)::int AS guests_included,
    (NULLIF(trim(s.minimum_nights), '')::numeric)::int AS minimum_nights,
    (NULLIF(trim(s.ano), '')::numeric)::int AS ano,
    (NULLIF(trim(s.mes), '')::numeric)::int AS mes
FROM airbnb.staging_airbnb s
LEFT JOIN airbnb.dim_locations l ON l.latitude = NULLIF(trim(s.latitude), '')::numeric AND l.longitude = NULLIF(trim(s.longitude), '')::numeric
LEFT JOIN airbnb.dim_properties p ON p.location_id = l.id AND p.host_id = CASE WHEN trim(s.host_id) = '' THEN NULL ELSE (NULLIF(trim(s.host_id), '')::numeric)::bigint END
LEFT JOIN airbnb.dim_reviews r ON r.property_id = p.id AND r.host_id = CASE WHEN trim(s.host_id) = '' THEN NULL ELSE (NULLIF(trim(s.host_id), '')::numeric)::bigint END
LIMIT 10;

-- End (no global transaction)

-- End of transform
