-- =====================================================================
-- SEÇÃO 1: ANÁLISE DE HOSTS E COMPETITIVIDADE
-- =====================================================================

-- 1.1 Ranking dos Super Hosts: Quem domina o mercado?
-- Objetivo: Identificar os principais players e suas estratégias
SELECT 
    h.host_name,
    h.host_is_superhost,
    COUNT(DISTINCT p.srk_property_id) AS total_propriedades,
    ROUND(AVG(f.price), 2) AS preco_medio,
    ROUND(AVG(r.review_scores_rating), 2) AS nota_media,
    ROUND(AVG(r.number_of_reviews), 0) AS media_avaliacoes,
    ROUND(AVG(f.price * f.minimum_nights), 2) AS receita_estimada_minima
FROM gold.dim_hosts h
JOIN gold.dim_properties p ON h.srk_host_id = p.srk_host_id
JOIN gold.fact_ocorrencias f ON p.srk_property_id = f.srk_property_id
LEFT JOIN gold.dim_reviews r ON p.srk_property_id = r.srk_property_id
WHERE h.host_is_superhost = TRUE
GROUP BY h.srk_host_id, h.host_name, h.host_is_superhost
HAVING COUNT(DISTINCT p.srk_property_id) >= 5
ORDER BY total_propriedades DESC, preco_medio DESC
LIMIT 20;

-- 1.2 Superhosts vs Hosts Regulares: Vale a pena o selo?
-- Objetivo: Quantificar o valor do status de Superhost
SELECT 
    CASE 
        WHEN h.host_is_superhost = TRUE THEN 'Superhost'
        WHEN h.host_is_superhost = FALSE THEN 'Host Regular'
        ELSE 'Não Informado'
    END AS tipo_host,
    COUNT(DISTINCT h.srk_host_id) AS total_hosts,
    COUNT(DISTINCT p.srk_property_id) AS total_propriedades,
    ROUND(AVG(f.price), 2) AS preco_medio,
    ROUND(AVG(r.review_scores_rating), 2) AS nota_geral,
    ROUND(AVG(r.review_scores_cleanliness), 2) AS nota_limpeza,
    ROUND(AVG(r.number_of_reviews), 1) AS media_num_avaliacoes,
    ROUND(AVG(p.n_amenities), 1) AS media_comodidades,
    ROUND(AVG(h.host_response_rate), 2) AS taxa_resposta_media
FROM gold.dim_hosts h
JOIN gold.dim_properties p ON h.srk_host_id = p.srk_host_id
JOIN gold.fact_ocorrencias f ON p.srk_property_id = f.srk_property_id
LEFT JOIN gold.dim_reviews r ON p.srk_property_id = r.srk_property_id
GROUP BY h.host_is_superhost
ORDER BY preco_medio DESC;

-- 1.3 Concentração de Mercado: Quantos hosts dominam a oferta?
-- Objetivo: Analisar concentração e possível oligopólio
WITH host_portfolio AS (
    SELECT 
        h.srk_host_id,
        h.host_name,
        COUNT(DISTINCT p.srk_property_id) AS num_propriedades
    FROM gold.dim_hosts h
    JOIN gold.dim_properties p ON h.srk_host_id = p.srk_host_id
    GROUP BY h.srk_host_id, h.host_name
)
SELECT 
    CASE 
        WHEN num_propriedades = 1 THEN '1 propriedade'
        WHEN num_propriedades BETWEEN 2 AND 5 THEN '2-5 propriedades'
        WHEN num_propriedades BETWEEN 6 AND 10 THEN '6-10 propriedades'
        WHEN num_propriedades BETWEEN 11 AND 20 THEN '11-20 propriedades'
        ELSE '20+ propriedades (profissional)'
    END AS categoria_host,
    COUNT(*) AS num_hosts,
    SUM(num_propriedades) AS total_propriedades,
    ROUND(SUM(num_propriedades) * 100.0 / SUM(SUM(num_propriedades)) OVER (), 2) AS percentual_mercado
FROM host_portfolio
GROUP BY 
    CASE 
        WHEN num_propriedades = 1 THEN '1 propriedade'
        WHEN num_propriedades BETWEEN 2 AND 5 THEN '2-5 propriedades'
        WHEN num_propriedades BETWEEN 6 AND 10 THEN '6-10 propriedades'
        WHEN num_propriedades BETWEEN 11 AND 20 THEN '11-20 propriedades'
        ELSE '20+ propriedades (profissional)'
    END
ORDER BY total_propriedades DESC;

-- =====================================================================
-- SEÇÃO 2: ANÁLISE DE PRECIFICAÇÃO E ESTRATÉGIAS COMERCIAIS
-- =====================================================================

-- 2.1 Precificação por Tipo de Propriedade e Quarto
-- Objetivo: Entender posicionamento de preço por categoria
SELECT 
    p.property_type,
    p.room_type,
    COUNT(DISTINCT p.srk_property_id) AS total_propriedades,
    ROUND(MIN(f.price), 2) AS preco_min,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY f.price), 2) AS percentil_25,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY f.price), 2) AS mediana,
    ROUND(AVG(f.price), 2) AS media,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY f.price), 2) AS percentil_75,
    ROUND(MAX(f.price), 2) AS preco_max,
    ROUND(STDDEV(f.price), 2) AS desvio_padrao
FROM gold.dim_properties p
JOIN gold.fact_ocorrencias f ON p.srk_property_id = f.srk_property_id
WHERE f.price > 0
GROUP BY p.property_type, p.room_type
HAVING COUNT(DISTINCT p.srk_property_id) >= 10
ORDER BY media DESC;

-- 2.2 Análise de Taxas Adicionais: Limpeza e Depósito
-- Objetivo: Identificar estratégias de taxas ocultas
SELECT 
    p.property_type,
    p.room_type,
    COUNT(*) AS total_ocorrencias,
    ROUND(AVG(f.price), 2) AS preco_base_medio,
    ROUND(AVG(f.cleaning_fee), 2) AS taxa_limpeza_media,
    ROUND(AVG(f.security_deposit), 2) AS deposito_medio,
    ROUND(AVG(f.price + COALESCE(f.cleaning_fee, 0)), 2) AS custo_total_medio,
    ROUND(AVG(COALESCE(f.cleaning_fee, 0) * 100.0 / NULLIF(f.price, 0)), 2) AS taxa_limpeza_percentual
FROM gold.dim_properties p
JOIN gold.fact_ocorrencias f ON p.srk_property_id = f.srk_property_id
WHERE f.price > 0
GROUP BY p.property_type, p.room_type
HAVING COUNT(*) >= 20
ORDER BY taxa_limpeza_percentual DESC;

-- 2.3 Políticas de Estadia Mínima e Impacto no Preço
-- Objetivo: Correlação entre minimum_nights e pricing strategy
SELECT 
    CASE 
        WHEN f.minimum_nights = 1 THEN '1 noite (flexível)'
        WHEN f.minimum_nights BETWEEN 2 AND 3 THEN '2-3 noites'
        WHEN f.minimum_nights BETWEEN 4 AND 7 THEN '4-7 noites'
        WHEN f.minimum_nights BETWEEN 8 AND 30 THEN '1-4 semanas'
        ELSE '30+ dias (mensal)'
    END AS politica_estadia,
    COUNT(DISTINCT p.srk_property_id) AS total_propriedades,
    ROUND(AVG(f.price), 2) AS preco_diaria_media,
    ROUND(AVG(f.price * f.minimum_nights), 2) AS receita_minima_media,
    ROUND(AVG(r.review_scores_value), 2) AS nota_custo_beneficio,
    ROUND(AVG(r.number_of_reviews), 1) AS media_avaliacoes
FROM gold.fact_ocorrencias f
JOIN gold.dim_properties p ON f.srk_property_id = p.srk_property_id
LEFT JOIN gold.dim_reviews r ON p.srk_property_id = r.srk_property_id
GROUP BY 
    CASE 
        WHEN f.minimum_nights = 1 THEN '1 noite (flexível)'
        WHEN f.minimum_nights BETWEEN 2 AND 3 THEN '2-3 noites'
        WHEN f.minimum_nights BETWEEN 4 AND 7 THEN '4-7 noites'
        WHEN f.minimum_nights BETWEEN 8 AND 30 THEN '1-4 semanas'
        ELSE '30+ dias (mensal)'
    END
ORDER BY receita_minima_media DESC;

-- 2.4 Análise de Políticas de Cancelamento
-- Objetivo: Entender trade-off entre flexibilidade e preço
SELECT 
    p.cancellation_policy,
    COUNT(DISTINCT p.srk_property_id) AS total_propriedades,
    ROUND(AVG(f.price), 2) AS preco_medio,
    ROUND(AVG(r.review_scores_rating), 2) AS nota_geral,
    ROUND(AVG(r.number_of_reviews), 1) AS media_avaliacoes,
    ROUND(COUNT(DISTINCT p.srk_property_id) * 100.0 / SUM(COUNT(DISTINCT p.srk_property_id)) OVER (), 2) AS percentual_mercado
FROM gold.dim_properties p
JOIN gold.fact_ocorrencias f ON p.srk_property_id = f.srk_property_id
LEFT JOIN gold.dim_reviews r ON p.srk_property_id = r.srk_property_id
GROUP BY p.cancellation_policy
ORDER BY total_propriedades DESC;

-- =====================================================================
-- SEÇÃO 3: ANÁLISE DE QUALIDADE E EXPERIÊNCIA DO HÓSPEDE
-- =====================================================================

-- 3.1 Top 30 Propriedades: Excelência em Avaliações
-- Objetivo: Benchmark de qualidade no mercado
SELECT 
    p.property_type,
    p.room_type,
    p.accommodates,
    p.bedrooms,
    h.host_name,
    h.host_is_superhost,
    ROUND(f.price, 2) AS preco_diaria,
    r.number_of_reviews,
    r.review_scores_rating AS nota_geral,
    r.review_scores_cleanliness AS limpeza,
    r.review_scores_communication AS comunicacao,
    r.review_scores_location AS localizacao,
    r.review_scores_value AS custo_beneficio,
    p.n_amenities AS num_comodidades
FROM gold.dim_properties p
JOIN gold.dim_hosts h ON p.srk_host_id = h.srk_host_id
JOIN gold.fact_ocorrencias f ON p.srk_property_id = f.srk_property_id
JOIN gold.dim_reviews r ON p.srk_property_id = r.srk_property_id
WHERE r.review_scores_rating >= 95
  AND r.number_of_reviews >= 20
ORDER BY r.review_scores_rating DESC, r.number_of_reviews DESC
LIMIT 30;

-- 3.2 Análise Multidimensional de Avaliações
-- Objetivo: Identificar pontos fortes e fracos por categoria
SELECT 
    p.room_type,
    COUNT(DISTINCT r.srk_review_id) AS total_avaliacoes,
    ROUND(AVG(r.review_scores_rating), 2) AS nota_geral,
    ROUND(AVG(r.review_scores_accuracy), 2) AS precisao,
    ROUND(AVG(r.review_scores_cleanliness), 2) AS limpeza,
    ROUND(AVG(r.review_scores_checkin), 2) AS checkin,
    ROUND(AVG(r.review_scores_communication), 2) AS comunicacao,
    ROUND(AVG(r.review_scores_location), 2) AS localizacao,
    ROUND(AVG(r.review_scores_value), 2) AS custo_beneficio,
    -- Identificar ponto mais forte
    CASE 
        WHEN AVG(r.review_scores_cleanliness) = GREATEST(
            AVG(r.review_scores_accuracy),
            AVG(r.review_scores_cleanliness),
            AVG(r.review_scores_checkin),
            AVG(r.review_scores_communication),
            AVG(r.review_scores_location),
            AVG(r.review_scores_value)
        ) THEN 'Limpeza'
        WHEN AVG(r.review_scores_location) = GREATEST(
            AVG(r.review_scores_accuracy),
            AVG(r.review_scores_cleanliness),
            AVG(r.review_scores_checkin),
            AVG(r.review_scores_communication),
            AVG(r.review_scores_location),
            AVG(r.review_scores_value)
        ) THEN 'Localização'
        ELSE 'Outro'
    END AS ponto_forte
FROM gold.dim_properties p
JOIN gold.dim_reviews r ON p.srk_property_id = r.srk_property_id
GROUP BY p.room_type
ORDER BY nota_geral DESC;

-- 3.3 Correlação: Comodidades vs Satisfação vs Preço
-- Objetivo: ROI de investimento em amenities
SELECT 
    CASE 
        WHEN p.n_amenities < 10 THEN '1. Básico (0-9)'
        WHEN p.n_amenities < 20 THEN '2. Padrão (10-19)'
        WHEN p.n_amenities < 30 THEN '3. Confortável (20-29)'
        WHEN p.n_amenities < 40 THEN '4. Luxo (30-39)'
        ELSE '5. Premium (40+)'
    END AS categoria_comodidades,
    COUNT(DISTINCT p.srk_property_id) AS total_propriedades,
    ROUND(AVG(p.n_amenities), 1) AS media_amenities,
    ROUND(AVG(f.price), 2) AS preco_medio,
    ROUND(AVG(r.review_scores_rating), 2) AS nota_geral,
    ROUND(AVG(r.review_scores_value), 2) AS custo_beneficio,
    ROUND(AVG(r.number_of_reviews), 1) AS media_num_avaliacoes
FROM gold.dim_properties p
JOIN gold.fact_ocorrencias f ON p.srk_property_id = f.srk_property_id
LEFT JOIN gold.dim_reviews r ON p.srk_property_id = r.srk_property_id
GROUP BY 
    CASE 
        WHEN p.n_amenities < 10 THEN '1. Básico (0-9)'
        WHEN p.n_amenities < 20 THEN '2. Padrão (10-19)'
        WHEN p.n_amenities < 30 THEN '3. Confortável (20-29)'
        WHEN p.n_amenities < 40 THEN '4. Luxo (30-39)'
        ELSE '5. Premium (40+)'
    END
ORDER BY categoria_comodidades;

-- =====================================================================
-- SEÇÃO 4: ANÁLISE GEOGRÁFICA E LOCALIZAÇÃO
-- =====================================================================

-- 4.1 Hotspots de Alto Valor: Onde estão as propriedades premium?
-- Objetivo: Mapear regiões de maior valor agregado
SELECT 
    ROUND(l.latitude::numeric, 3) AS latitude_zona,
    ROUND(l.longitude::numeric, 3) AS longitude_zona,
    COUNT(DISTINCT p.srk_property_id) AS densidade_propriedades,
    ROUND(AVG(f.price), 2) AS preco_medio,
    ROUND(AVG(r.review_scores_rating), 2) AS nota_media,
    ROUND(AVG(r.review_scores_location), 2) AS nota_localizacao,
    -- Classificar zona por preço
    CASE 
        WHEN AVG(f.price) >= 500 THEN 'Premium'
        WHEN AVG(f.price) >= 300 THEN 'Alto Padrão'
        WHEN AVG(f.price) >= 150 THEN 'Médio'
        ELSE 'Econômico'
    END AS categoria_zona
FROM gold.dim_locations l
JOIN gold.dim_properties p ON l.srk_location_id = p.srk_location_id
JOIN gold.fact_ocorrencias f ON p.srk_property_id = f.srk_property_id
LEFT JOIN gold.dim_reviews r ON p.srk_property_id = r.srk_property_id
GROUP BY latitude_zona, longitude_zona
HAVING COUNT(DISTINCT p.srk_property_id) >= 10
ORDER BY preco_medio DESC
LIMIT 25;

-- 4.2 Análise de Densidade: Competição por Localização
-- Objetivo: Identificar áreas saturadas vs oportunidades
WITH location_stats AS (
    SELECT 
        ROUND(l.latitude::numeric, 2) AS lat,
        ROUND(l.longitude::numeric, 2) AS lon,
        COUNT(DISTINCT p.srk_property_id) AS num_propriedades,
        AVG(f.price) AS avg_price
    FROM gold.dim_locations l
    JOIN gold.dim_properties p ON l.srk_location_id = p.srk_location_id
    JOIN gold.fact_ocorrencias f ON p.srk_property_id = f.srk_property_id
    GROUP BY lat, lon
)
SELECT 
    CASE 
        WHEN num_propriedades < 5 THEN 'Baixa Densidade'
        WHEN num_propriedades < 15 THEN 'Média Densidade'
        WHEN num_propriedades < 30 THEN 'Alta Densidade'
        ELSE 'Saturado'
    END AS categoria_densidade,
    COUNT(*) AS num_zonas,
    ROUND(AVG(num_propriedades), 1) AS media_propriedades_por_zona,
    ROUND(AVG(avg_price), 2) AS preco_medio
FROM location_stats
GROUP BY 
    CASE 
        WHEN num_propriedades < 5 THEN 'Baixa Densidade'
        WHEN num_propriedades < 15 THEN 'Média Densidade'
        WHEN num_propriedades < 30 THEN 'Alta Densidade'
        ELSE 'Saturado'
    END
ORDER BY preco_medio DESC;

-- =====================================================================
-- SEÇÃO 5: ANÁLISE TEMPORAL E SAZONALIDADE
-- =====================================================================

-- 5.1 Evolução de Preços ao Longo de 2019
-- Objetivo: Identificar sazonalidade e períodos de alta demanda
SELECT 
    f.mes,
    CASE f.mes
        WHEN 1 THEN 'Janeiro'
        WHEN 2 THEN 'Fevereiro (Carnaval)'
        WHEN 3 THEN 'Março'
        WHEN 4 THEN 'Abril'
        WHEN 5 THEN 'Maio'
        WHEN 6 THEN 'Junho'
        WHEN 7 THEN 'Julho (Férias)'
        WHEN 8 THEN 'Agosto'
        WHEN 9 THEN 'Setembro'
        WHEN 10 THEN 'Outubro'
        WHEN 11 THEN 'Novembro'
        WHEN 12 THEN 'Dezembro (Réveillon)'
    END AS mes_nome,
    COUNT(DISTINCT f.srk_fact_id) AS total_ocorrencias,
    ROUND(AVG(f.price), 2) AS preco_medio,
    ROUND(MIN(f.price), 2) AS preco_min,
    ROUND(MAX(f.price), 2) AS preco_max,
    ROUND(AVG(f.cleaning_fee), 2) AS taxa_limpeza_media,
    ROUND(AVG(f.minimum_nights), 1) AS estadia_minima_media
FROM gold.fact_ocorrencias f
WHERE f.ano = 2019 AND f.price > 0
GROUP BY f.mes
ORDER BY f.mes;

-- 5.2 Variação de Preço: Eventos Especiais
-- Objetivo: Comparar meses de eventos (Carnaval, Réveillon) com base
WITH monthly_stats AS (
    SELECT 
        mes,
        AVG(price) AS avg_price
    FROM gold.fact_ocorrencias
    WHERE ano = 2019 AND price > 0
    GROUP BY mes
),
baseline AS (
    SELECT AVG(avg_price) AS baseline_price
    FROM monthly_stats
    WHERE mes NOT IN (2, 12) -- Excluir Carnaval e Réveillon
)
SELECT 
    m.mes,
    CASE m.mes
        WHEN 2 THEN 'Fevereiro (Carnaval)'
        WHEN 12 THEN 'Dezembro (Réveillon)'
        ELSE 'Outros Meses'
    END AS periodo,
    ROUND(m.avg_price, 2) AS preco_medio,
    ROUND(b.baseline_price, 2) AS preco_base,
    ROUND(m.avg_price - b.baseline_price, 2) AS diferenca_absoluta,
    ROUND((m.avg_price - b.baseline_price) * 100.0 / b.baseline_price, 2) AS variacao_percentual
FROM monthly_stats m
CROSS JOIN baseline b
WHERE m.mes IN (2, 12)
ORDER BY m.mes;

-- =====================================================================
-- SEÇÃO 6: ANÁLISE DE MODELOS DE NEGÓCIO
-- =====================================================================

-- 6.1 Reserva Instantânea: Conveniência vs Controle
-- Objetivo: Avaliar impacto de instant booking no negócio
SELECT 
    CASE 
        WHEN p.instant_bookable = TRUE THEN 'Reserva Instantânea'
        ELSE 'Requer Aprovação'
    END AS modelo_reserva,
    COUNT(DISTINCT p.srk_property_id) AS total_propriedades,
    ROUND(AVG(f.price), 2) AS preco_medio,
    ROUND(AVG(r.review_scores_rating), 2) AS nota_geral,
    ROUND(AVG(r.number_of_reviews), 1) AS media_num_avaliacoes,
    ROUND(AVG(r.review_scores_communication), 2) AS nota_comunicacao,
    ROUND(COUNT(DISTINCT p.srk_property_id) * 100.0 / SUM(COUNT(DISTINCT p.srk_property_id)) OVER (), 2) AS market_share
FROM gold.dim_properties p
JOIN gold.fact_ocorrencias f ON p.srk_property_id = f.srk_property_id
LEFT JOIN gold.dim_reviews r ON p.srk_property_id = r.srk_property_id
GROUP BY p.instant_bookable
ORDER BY total_propriedades DESC;

-- 6.2 Business Travel Ready: Segmento Corporativo
-- Objetivo: Analisar características do segmento business
SELECT 
    p.property_type,
    p.room_type,
    COUNT(DISTINCT p.srk_property_id) AS total_propriedades,
    ROUND(AVG(f.price), 2) AS preco_medio,
    ROUND(AVG(p.accommodates), 1) AS capacidade_media,
    ROUND(AVG(p.n_amenities), 1) AS media_comodidades,
    ROUND(AVG(r.review_scores_cleanliness), 2) AS nota_limpeza,
    ROUND(AVG(r.review_scores_communication), 2) AS nota_comunicacao,
    ROUND(AVG(r.review_scores_checkin), 2) AS nota_checkin,
    p.instant_bookable,
    ROUND(AVG(f.minimum_nights), 1) AS estadia_min_media
FROM gold.dim_properties p
JOIN gold.fact_ocorrencias f ON p.srk_property_id = f.srk_property_id
LEFT JOIN gold.dim_reviews r ON p.srk_property_id = r.srk_property_id
WHERE p.is_business_travel_ready = TRUE
GROUP BY p.property_type, p.room_type, p.instant_bookable
HAVING COUNT(DISTINCT p.srk_property_id) >= 5
ORDER BY total_propriedades DESC;

-- 6.3 Capacidade vs Demanda: Otimização de Ocupação
-- Objetivo: Identificar sweet spot de capacidade
SELECT 
    p.accommodates AS capacidade_hospedes,
    p.bedrooms AS num_quartos,
    p.beds AS num_camas,
    COUNT(DISTINCT p.srk_property_id) AS total_propriedades,
    ROUND(AVG(f.price), 2) AS preco_medio,
    ROUND(AVG(f.price) / NULLIF(p.accommodates, 0), 2) AS preco_por_pessoa,
    ROUND(AVG(r.review_scores_rating), 2) AS nota_geral,
    ROUND(AVG(r.number_of_reviews), 1) AS media_avaliacoes,
    ROUND(AVG(f.minimum_nights), 1) AS estadia_min_media
FROM gold.dim_properties p
JOIN gold.fact_ocorrencias f ON p.srk_property_id = f.srk_property_id
LEFT JOIN gold.dim_reviews r ON p.srk_property_id = r.srk_property_id
WHERE p.accommodates BETWEEN 1 AND 10
  AND p.bedrooms IS NOT NULL
GROUP BY p.accommodates, p.bedrooms, p.beds
HAVING COUNT(DISTINCT p.srk_property_id) >= 10
ORDER BY capacidade_hospedes, num_quartos;

-- =====================================================================
-- SEÇÃO 7: INSIGHTS ESTRATÉGICOS E SEGMENTAÇÃO
-- =====================================================================

-- 7.1 Segmentação de Mercado: Matriz Preço x Qualidade
-- Objetivo: Posicionamento estratégico de propriedades
WITH property_metrics AS (
    SELECT 
        p.srk_property_id,
        p.property_type,
        p.room_type,
        AVG(f.price) AS avg_price,
        AVG(r.review_scores_rating) AS avg_rating
    FROM gold.dim_properties p
    JOIN gold.fact_ocorrencias f ON p.srk_property_id = f.srk_property_id
    LEFT JOIN gold.dim_reviews r ON p.srk_property_id = r.srk_review_id
    WHERE r.number_of_reviews >= 5
    GROUP BY p.srk_property_id, p.property_type, p.room_type
),
price_quartiles AS (
    SELECT 
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_price) AS median_price
    FROM property_metrics
),
rating_quartiles AS (
    SELECT 
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_rating) AS median_rating
    FROM property_metrics
)
SELECT 
    CASE 
        WHEN pm.avg_price >= pq.median_price AND pm.avg_rating >= rq.median_rating THEN 'Premium (Alto Preço, Alta Qualidade)'
        WHEN pm.avg_price >= pq.median_price AND pm.avg_rating < rq.median_rating THEN 'Caro (Alto Preço, Baixa Qualidade)'
        WHEN pm.avg_price < pq.median_price AND pm.avg_rating >= rq.median_rating THEN 'Custo-Benefício (Baixo Preço, Alta Qualidade)'
        ELSE 'Econômico (Baixo Preço, Baixa Qualidade)'
    END AS segmento,
    COUNT(*) AS total_propriedades,
    ROUND(AVG(pm.avg_price), 2) AS preco_medio,
    ROUND(AVG(pm.avg_rating), 2) AS nota_media,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentual_mercado
FROM property_metrics pm
CROSS JOIN price_quartiles pq
CROSS JOIN rating_quartiles rq
GROUP BY 
    CASE 
        WHEN pm.avg_price >= pq.median_price AND pm.avg_rating >= rq.median_rating THEN 'Premium (Alto Preço, Alta Qualidade)'
        WHEN pm.avg_price >= pq.median_price AND pm.avg_rating < rq.median_rating THEN 'Caro (Alto Preço, Baixa Qualidade)'
        WHEN pm.avg_price < pq.median_price AND pm.avg_rating >= rq.median_rating THEN 'Custo-Benefício (Baixo Preço, Alta Qualidade)'
        ELSE 'Econômico (Baixo Preço, Baixa Qualidade)'
    END
ORDER BY total_propriedades DESC;

-- 7.2 Análise de Oportunidades: Gaps de Mercado
-- Objetivo: Identificar nichos subatendidos
WITH market_analysis AS (
    SELECT 
        p.property_type,
        p.room_type,
        CASE 
            WHEN p.accommodates <= 2 THEN 'Casal/Individual'
            WHEN p.accommodates <= 4 THEN 'Família Pequena'
            WHEN p.accommodates <= 6 THEN 'Família Grande'
            ELSE 'Grupo'
        END AS segmento_publico,
        COUNT(DISTINCT p.srk_property_id) AS oferta_atual,
        AVG(r.number_of_reviews) AS demanda_estimada,
        AVG(f.price) AS preco_medio
    FROM gold.dim_properties p
    JOIN gold.fact_ocorrencias f ON p.srk_property_id = f.srk_property_id
    LEFT JOIN gold.dim_reviews r ON p.srk_property_id = r.srk_property_id
    GROUP BY p.property_type, p.room_type, 
        CASE 
            WHEN p.accommodates <= 2 THEN 'Casal/Individual'
            WHEN p.accommodates <= 4 THEN 'Família Pequena'
            WHEN p.accommodates <= 6 THEN 'Família Grande'
            ELSE 'Grupo'
        END
)
SELECT 
    property_type,
    room_type,
    segmento_publico,
    oferta_atual,
    ROUND(demanda_estimada, 1) AS demanda_media,
    ROUND(preco_medio, 2) AS preco_medio,
    -- Índice de oportunidade (alta demanda / baixa oferta)
    ROUND(demanda_estimada / NULLIF(oferta_atual, 0), 2) AS indice_oportunidade
FROM market_analysis
WHERE oferta_atual >= 5
ORDER BY indice_oportunidade DESC
LIMIT 25;

-- 7.3 Benchmark Competitivo: Melhores Práticas
-- Objetivo: KPIs das propriedades top performer
WITH top_performers AS (
    SELECT 
        p.srk_property_id,
        r.review_scores_rating,
        r.number_of_reviews,
        f.price
    FROM gold.dim_properties p
    JOIN gold.dim_reviews r ON p.srk_property_id = r.srk_property_id
    JOIN gold.fact_ocorrencias f ON p.srk_property_id = f.srk_property_id
    WHERE r.review_scores_rating >= 95
      AND r.number_of_reviews >= 30
    ORDER BY r.review_scores_rating DESC, r.number_of_reviews DESC
    LIMIT 100
)
SELECT 
    'Top 100 Performers' AS categoria,
    COUNT(DISTINCT tp.srk_property_id) AS total_propriedades,
    ROUND(AVG(f.price), 2) AS preco_medio,
    ROUND(AVG(r.review_scores_rating), 2) AS nota_geral,
    ROUND(AVG(r.review_scores_cleanliness), 2) AS nota_limpeza,
    ROUND(AVG(r.review_scores_communication), 2) AS nota_comunicacao,
    ROUND(AVG(r.review_scores_location), 2) AS nota_localizacao,
    ROUND(AVG(r.review_scores_value), 2) AS nota_custo_beneficio,
    ROUND(AVG(p.n_amenities), 1) AS media_comodidades,
    ROUND(AVG(f.minimum_nights), 1) AS estadia_min_media,
    ROUND(AVG(CASE WHEN h.host_is_superhost THEN 1 ELSE 0 END) * 100, 2) AS percentual_superhosts,
    ROUND(AVG(CASE WHEN p.instant_bookable THEN 1 ELSE 0 END) * 100, 2) AS percentual_instant_book
FROM top_performers tp
JOIN gold.dim_properties p ON tp.srk_property_id = p.srk_property_id
JOIN gold.dim_hosts h ON p.srk_host_id = h.srk_host_id
JOIN gold.fact_ocorrencias f ON p.srk_property_id = f.srk_property_id
JOIN gold.dim_reviews r ON p.srk_property_id = r.srk_property_id;
-- =====================================================================