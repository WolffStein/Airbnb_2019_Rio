-- =====================================================
-- DDL - CAMADA SILVER
-- Dataset: Airbnb Rio de Janeiro 2019
-- Schema: silver
-- =====================================================

CREATE SCHEMA IF NOT EXISTS silver;

-- =====================================================
-- TABELAS
-- =====================================================

-- Tabela: HOST (Anfitriões)
CREATE TABLE IF NOT EXISTS silver.host (
    id_host SERIAL PRIMARY KEY,
    host_id NUMERIC NOT NULL UNIQUE,
    host_name TEXT,
    host_response_time TEXT,
    host_response_rate NUMERIC,
    host_is_superhost BOOLEAN,
    host_listings_count NUMERIC,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela: LOCATION (Localizações Geográficas)
CREATE TABLE IF NOT EXISTS silver.location (
    id_location SERIAL PRIMARY KEY,
    latitude NUMERIC,
    longitude NUMERIC,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(latitude, longitude)
);

-- Tabela: PROPERTY (Propriedades/Imóveis)
CREATE TABLE IF NOT EXISTS silver.property (
    id_property SERIAL PRIMARY KEY,
    id_host INTEGER NOT NULL,
    id_location INTEGER NOT NULL,
    property_type TEXT,
    room_type TEXT,
    bed_type TEXT,
    accommodates NUMERIC,
    bathrooms NUMERIC,
    bedrooms NUMERIC,
    beds NUMERIC,
    instant_bookable BOOLEAN,
    is_business_travel_ready BOOLEAN,
    cancellation_policy TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_host FOREIGN KEY (id_host) 
        REFERENCES silver.host(id_host) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_location FOREIGN KEY (id_location) 
        REFERENCES silver.location(id_location) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

-- Tabela: REVIEW (Avaliações dos Hóspedes)
CREATE TABLE IF NOT EXISTS silver.review (
    id_review SERIAL PRIMARY KEY,
    id_host INTEGER NOT NULL,
    number_of_reviews NUMERIC,
    review_scores_rating NUMERIC,
    review_scores_accuracy NUMERIC,
    review_scores_cleanliness NUMERIC,
    review_scores_checkin NUMERIC,
    review_scores_communication NUMERIC,
    review_scores_location NUMERIC,
    review_scores_value NUMERIC,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_host_review FOREIGN KEY (id_host) 
        REFERENCES silver.host(id_host) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

-- =====================================================
-- ÍNDICES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_host_id ON silver.host(host_id);
CREATE INDEX IF NOT EXISTS idx_host_superhost ON silver.host(host_is_superhost);

CREATE INDEX IF NOT EXISTS idx_location_coords ON silver.location(latitude, longitude);

CREATE INDEX IF NOT EXISTS idx_property_host ON silver.property(id_host);
CREATE INDEX IF NOT EXISTS idx_property_location ON silver.property(id_location);
CREATE INDEX IF NOT EXISTS idx_property_type ON silver.property(property_type);
CREATE INDEX IF NOT EXISTS idx_room_type ON silver.property(room_type);

CREATE INDEX IF NOT EXISTS idx_review_host ON silver.review(id_host);
CREATE INDEX IF NOT EXISTS idx_review_rating ON silver.review(review_scores_rating);
