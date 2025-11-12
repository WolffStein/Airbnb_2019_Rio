-- gold_join_test.sql
-- Single query that joins fact_ocorrencias with dim tables to validate integration and sample combined rows.
-- Run with: docker compose exec -T db psql -U admin -d lakehouse < etl/sql/gold_join_test.sql

\echo '--- Join test: fact -> properties -> hosts -> locations -> reviews (sample) ---'
SELECT
  f.id AS fact_id,
  f.ano, f.mes,
  f.price,
  h.host_id,
  h.host_name,
  p.id AS property_id,
  p.property_type,
  l.id AS location_id,
  l.latitude,
  l.longitude,
  r.number_of_reviews
FROM airbnb.fact_ocorrencias f
LEFT JOIN airbnb.dim_properties p ON f.property_id = p.id
LEFT JOIN airbnb.dim_hosts h ON f.host_id = h.host_id
LEFT JOIN airbnb.dim_locations l ON f.location_id = l.id
LEFT JOIN airbnb.dim_reviews r ON f.review_id = r.id
ORDER BY f.id DESC
LIMIT 50;

\echo '--- Referential stats: how many fact rows have missing FK targets ---'
SELECT
  SUM(CASE WHEN f.property_id IS NULL OR p.id IS NULL THEN 1 ELSE 0 END) AS missing_property,
  SUM(CASE WHEN f.host_id IS NULL OR h.host_id IS NULL THEN 1 ELSE 0 END) AS missing_host,
  SUM(CASE WHEN f.location_id IS NULL OR l.id IS NULL THEN 1 ELSE 0 END) AS missing_location,
  SUM(CASE WHEN f.review_id IS NULL OR r.id IS NULL THEN 1 ELSE 0 END) AS missing_review
FROM airbnb.fact_ocorrencias f
LEFT JOIN airbnb.dim_properties p ON f.property_id = p.id
LEFT JOIN airbnb.dim_hosts h ON f.host_id = h.host_id
LEFT JOIN airbnb.dim_locations l ON f.location_id = l.id
LEFT JOIN airbnb.dim_reviews r ON f.review_id = r.id;

\echo '--- Done: gold_join_test.sql ---'
