-- =====================================================
-- DDL - CAMADA GOLD (Star Schema)
-- Dataset: Airbnb Rio de Janeiro 2019
-- Schema: gold
-- =====================================================

CREATE SCHEMA IF NOT EXISTS gold;

-- =====================================================
-- TABELAS DE DIMENSÃO
-- =====================================================

-- Dimensão: HOSTS (Anfitriões)
DROP TABLE IF EXISTS gold.dim_hosts CASCADE;

CREATE TABLE gold.dim_hosts (
    srk_host_id BIGINT PRIMARY KEY,
    host_id_original BIGINT,
    host_name TEXT,
    host_response_time TEXT,
    host_response_rate NUMERIC,
    host_is_superhost BOOLEAN,
    host_listings_count INT
);

-- Dimensão: LOCATIONS (Localizações Geográficas)
DROP TABLE IF EXISTS gold.dim_locations CASCADE;

CREATE TABLE gold.dim_locations (
    srk_location_id SERIAL PRIMARY KEY,
    latitude NUMERIC NOT NULL,
    longitude NUMERIC NOT NULL,
    UNIQUE(latitude, longitude)
);

-- Dimensão: PROPERTIES (Propriedades/Imóveis)
DROP TABLE IF EXISTS gold.dim_properties CASCADE;

CREATE TABLE gold.dim_properties (
    srk_property_id SERIAL PRIMARY KEY,
    srk_host_id BIGINT REFERENCES gold.dim_hosts(srk_host_id),
    srk_location_id INT REFERENCES gold.dim_locations(srk_location_id),
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
    n_amenities INT
);

-- Dimensão: REVIEWS (Avaliações)
DROP TABLE IF EXISTS gold.dim_reviews CASCADE;

CREATE TABLE gold.dim_reviews (
    srk_review_id SERIAL PRIMARY KEY,
    srk_host_id BIGINT REFERENCES gold.dim_hosts(srk_host_id),
    srk_property_id INT REFERENCES gold.dim_properties(srk_property_id),
    number_of_reviews INT,
    review_scores_rating NUMERIC,
    review_scores_accuracy NUMERIC,
    review_scores_cleanliness NUMERIC,
    review_scores_checkin NUMERIC,
    review_scores_communication NUMERIC,
    review_scores_location NUMERIC,
    review_scores_value NUMERIC
);

-- =====================================================
-- TABELA FATO
-- =====================================================

-- Fato: OCORRÊNCIAS (Transações/Listagens)
DROP TABLE IF EXISTS gold.fact_ocorrencias CASCADE;

CREATE TABLE gold.fact_ocorrencias (
    srk_fact_id SERIAL PRIMARY KEY,
    srk_host_id BIGINT REFERENCES gold.dim_hosts(srk_host_id) ON DELETE SET NULL,
    srk_property_id INT REFERENCES gold.dim_properties(srk_property_id) ON DELETE SET NULL,
    srk_location_id INT REFERENCES gold.dim_locations(srk_location_id) ON DELETE SET NULL,
    srk_review_id INT REFERENCES gold.dim_reviews(srk_review_id) ON DELETE SET NULL,
    price NUMERIC,
    security_deposit NUMERIC,
    cleaning_fee NUMERIC,
    guests_included INT,
    minimum_nights INT,
    ano INT,
    mes INT
);

-- =====================================================
-- ÍNDICES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_dim_hosts_original ON gold.dim_hosts(host_id_original);
CREATE INDEX IF NOT EXISTS idx_dim_hosts_superhost ON gold.dim_hosts(host_is_superhost);

CREATE INDEX IF NOT EXISTS idx_dim_locations_coords ON gold.dim_locations(latitude, longitude);

CREATE INDEX IF NOT EXISTS idx_dim_properties_host ON gold.dim_properties(srk_host_id);
CREATE INDEX IF NOT EXISTS idx_dim_properties_location ON gold.dim_properties(srk_location_id);
CREATE INDEX IF NOT EXISTS idx_dim_properties_type ON gold.dim_properties(property_type);
CREATE INDEX IF NOT EXISTS idx_dim_properties_room_type ON gold.dim_properties(room_type);

CREATE INDEX IF NOT EXISTS idx_dim_reviews_host ON gold.dim_reviews(srk_host_id);
CREATE INDEX IF NOT EXISTS idx_dim_reviews_property ON gold.dim_reviews(srk_property_id);
CREATE INDEX IF NOT EXISTS idx_dim_reviews_rating ON gold.dim_reviews(review_scores_rating);

CREATE INDEX IF NOT EXISTS idx_fact_host ON gold.fact_ocorrencias(srk_host_id);
CREATE INDEX IF NOT EXISTS idx_fact_property ON gold.fact_ocorrencias(srk_property_id);
CREATE INDEX IF NOT EXISTS idx_fact_location ON gold.fact_ocorrencias(srk_location_id);
CREATE INDEX IF NOT EXISTS idx_fact_review ON gold.fact_ocorrencias(srk_review_id);
CREATE INDEX IF NOT EXISTS idx_fact_ano_mes ON gold.fact_ocorrencias(ano, mes);
CREATE INDEX IF NOT EXISTS idx_fact_price ON gold.fact_ocorrencias(price);
