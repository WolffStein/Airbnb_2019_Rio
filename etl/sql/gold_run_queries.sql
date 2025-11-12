-- gold_run_queries.sql
-- Conjunto de queries para executar rapidamente pela CLI (psql)
-- Execute dentro do container db com:
-- docker compose exec db bash -lc "psql -U admin -d lakehouse -f /data/etl/sql/gold_run_queries.sql"

\echo '--- Counts: dims and fact ---'
SELECT 'dim_hosts' table_name, count(*) FROM airbnb.dim_hosts;
SELECT 'dim_locations' table_name, count(*) FROM airbnb.dim_locations;
SELECT 'dim_properties' table_name, count(*) FROM airbnb.dim_properties;
SELECT 'dim_reviews' table_name, count(*) FROM airbnb.dim_reviews;
SELECT 'fact_ocorrencias' table_name, count(*) FROM airbnb.fact_ocorrencias;

\echo '--- Distinct ids ---'
SELECT 'distinct hosts' as what, count(DISTINCT host_id) FROM airbnb.dim_hosts;
SELECT 'distinct properties' as what, count(DISTINCT id) FROM airbnb.dim_properties;
SELECT 'distinct locations' as what, count(DISTINCT id) FROM airbnb.dim_locations;

\echo '--- Null / missing key checks ---'
SELECT 'dim_hosts null host_id', count(*) FROM airbnb.dim_hosts WHERE host_id IS NULL;
SELECT 'dim_properties null id', count(*) FROM airbnb.dim_properties WHERE id IS NULL;
SELECT 'fact null property_id', count(*) FROM airbnb.fact_ocorrencias WHERE property_id IS NULL;
SELECT 'fact null ano/mes', count(*) FROM airbnb.fact_ocorrencias WHERE ano IS NULL OR mes IS NULL;

\echo '--- Duplicate host_id in dim_hosts (should be 0) ---'
SELECT host_id, count(*) cnt FROM airbnb.dim_hosts GROUP BY host_id HAVING count(*) > 1 ORDER BY cnt DESC LIMIT 20;

\echo '--- Sample rows ---'
SELECT * FROM airbnb.dim_hosts LIMIT 10;
SELECT * FROM airbnb.dim_properties LIMIT 10;
SELECT * FROM airbnb.fact_ocorrencias ORDER BY ano DESC, mes DESC LIMIT 15;

\echo '--- Referential integrity quick checks ---'
SELECT count(*) AS properties_without_host
FROM airbnb.dim_properties p
LEFT JOIN airbnb.dim_hosts h ON p.host_id = h.host_id
WHERE h.host_id IS NULL;

SELECT count(*) AS properties_without_location
FROM airbnb.dim_properties p
LEFT JOIN airbnb.dim_locations l ON p.location_id = l.id
WHERE l.id IS NULL;

SELECT count(*) AS facts_without_property
FROM airbnb.fact_ocorrencias f
LEFT JOIN airbnb.dim_properties p ON f.property_id = p.id
WHERE p.id IS NULL;

\echo '--- Price sanity checks ---'
SELECT COUNT(*) AS zero_or_negative_price FROM airbnb.fact_ocorrencias WHERE price IS NULL OR price <= 0;
SELECT COUNT(*) AS very_high_price FROM airbnb.fact_ocorrencias WHERE price > 1000;
SELECT ROUND(AVG(price),2) AS avg_price, ROUND(stddev_pop(price),2) AS sd_price FROM airbnb.fact_ocorrencias;

\echo '--- Avg price by ano/mes (recent 12) ---'
SELECT ano, mes, ROUND(AVG(price),2) AS avg_price, COUNT(*) AS cnt
FROM airbnb.fact_ocorrencias
GROUP BY ano, mes
ORDER BY ano DESC, mes DESC
LIMIT 12;

\echo '--- Top hosts by number of properties ---'
SELECT h.host_id, h.host_name, COUNT(p.id) AS num_properties
FROM airbnb.dim_hosts h
LEFT JOIN airbnb.dim_properties p ON p.host_id = h.host_id
GROUP BY h.host_id, h.host_name
ORDER BY num_properties DESC
LIMIT 20;

\echo '--- Top locations by average price (min 10 properties) ---'
SELECT l.id AS location_id, ROUND(AVG(f.price),2) AS avg_price, COUNT(DISTINCT p.id) AS properties
FROM airbnb.dim_locations l
JOIN airbnb.dim_properties p ON p.location_id = l.id
JOIN airbnb.fact_ocorrencias f ON f.property_id = p.id
GROUP BY l.id
HAVING COUNT(DISTINCT p.id) >= 10
ORDER BY avg_price DESC
LIMIT 20;

\echo '--- Distribution: room_type and property_type ---'
SELECT property_type, COUNT(*) FROM airbnb.dim_properties GROUP BY property_type ORDER BY COUNT(*) DESC LIMIT 20;
SELECT room_type, COUNT(*) FROM airbnb.dim_properties GROUP BY room_type ORDER BY COUNT(*) DESC;

\echo '--- Reviews summary ---'
SELECT COUNT(*) AS reviews_total, AVG(number_of_reviews) AS avg_reviews_per_property FROM airbnb.dim_reviews;

\echo '--- Done: gold_run_queries.sql ---'
