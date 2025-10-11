import os
import pandas as pd
import psycopg2
from time import sleep

# Aguarda o Postgres iniciar
sleep(15)

# =====================================================
# 1️⃣ Conexão com o banco
# =====================================================
conn = psycopg2.connect(
    dbname=os.getenv("DB_NAME"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    host=os.getenv("DB_HOST"),
    port=os.getenv("DB_PORT"),
)
cur = conn.cursor()
print("✅ Conectado ao banco PostgreSQL")

# =====================================================
# 2️⃣ Carrega a base prata
# =====================================================
df = pd.read_csv("/data/base_de_dados_prata.csv")
df["dia"] = 1  # placeholder temporal

# =====================================================
# 3️⃣ Criação das tabelas DIMENSÃO
# =====================================================
cur.execute("""
CREATE TABLE IF NOT EXISTS dim_host (
    id_host SERIAL PRIMARY KEY,
    host_id NUMERIC UNIQUE,
    host_name TEXT,
    host_response_time TEXT,
    host_response_rate NUMERIC,
    host_is_superhost BOOLEAN,
    host_listings_count NUMERIC
);
""")

cur.execute("""
CREATE TABLE IF NOT EXISTS dim_property (
    id_property SERIAL PRIMARY KEY,
    property_type TEXT,
    room_type TEXT,
    bed_type TEXT,
    accommodates NUMERIC,
    bathrooms NUMERIC,
    bedrooms NUMERIC,
    beds NUMERIC,
    instant_bookable BOOLEAN,
    is_business_travel_ready BOOLEAN,
    cancellation_policy TEXT
);
""")

cur.execute("""
CREATE TABLE IF NOT EXISTS dim_location (
    id_location SERIAL PRIMARY KEY,
    latitude NUMERIC,
    longitude NUMERIC
);
""")

cur.execute("""
CREATE TABLE IF NOT EXISTS dim_review (
    id_review SERIAL PRIMARY KEY,
    number_of_reviews NUMERIC,
    review_scores_rating NUMERIC,
    review_scores_accuracy NUMERIC,
    review_scores_cleanliness NUMERIC,
    review_scores_checkin NUMERIC,
    review_scores_communication NUMERIC,
    review_scores_location NUMERIC,
    review_scores_value NUMERIC
);
""")

# =====================================================
# 4️⃣ Criação da tabela FATO
# =====================================================
cur.execute("""
CREATE TABLE IF NOT EXISTS fato_airbnb (
    id_fato SERIAL PRIMARY KEY,
    id_host INT REFERENCES dim_host(id_host),
    id_property INT REFERENCES dim_property(id_property),
    id_location INT REFERENCES dim_location(id_location),
    id_review INT REFERENCES dim_review(id_review),

    price NUMERIC,
    security_deposit NUMERIC,
    cleaning_fee NUMERIC,
    guests_included NUMERIC,
    extra_people NUMERIC,
    minimum_nights NUMERIC,
    n_amenities NUMERIC,
    ano INT,
    mes INT,
    dia INT
);
""")
conn.commit()
print("🧱 Estrutura criada com sucesso!")

# =====================================================
# 5️⃣ Criação e carga das dimensões
# =====================================================
dim_host = df[[
    'host_id', 'host_name',
    'host_response_time', 'host_response_rate',
    'host_is_superhost', 'host_listings_count'
]].drop_duplicates().reset_index(drop=True)

dim_property = df[[
    'property_type', 'room_type', 'bed_type',
    'accommodates', 'bathrooms', 'bedrooms', 'beds',
    'instant_bookable', 'is_business_travel_ready', 'cancellation_policy'
]].drop_duplicates().reset_index(drop=True)

dim_location = df[['latitude', 'longitude']].drop_duplicates().reset_index(drop=True)

dim_review = df[[
    'number_of_reviews', 'review_scores_rating', 'review_scores_accuracy',
    'review_scores_cleanliness', 'review_scores_checkin',
    'review_scores_communication', 'review_scores_location', 'review_scores_value'
]].drop_duplicates().reset_index(drop=True)

# Popula cada dimensão
for _, row in dim_host.iterrows():
    cur.execute("""
        INSERT INTO dim_host (
            host_id, host_name, host_response_time,
            host_response_rate, host_is_superhost, host_listings_count
        )
        VALUES (%s,%s,%s,%s,%s,%s)
        ON CONFLICT (host_id) DO NOTHING;
    """, tuple(row))

for _, row in dim_property.iterrows():
    cur.execute("""
        INSERT INTO dim_property (
            property_type, room_type, bed_type,
            accommodates, bathrooms, bedrooms, beds,
            instant_bookable, is_business_travel_ready, cancellation_policy
        )
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
        ON CONFLICT DO NOTHING;
    """, tuple(row))

for _, row in dim_location.iterrows():
    cur.execute("""
        INSERT INTO dim_location (latitude, longitude)
        VALUES (%s,%s)
        ON CONFLICT DO NOTHING;
    """, tuple(row))

for _, row in dim_review.iterrows():
    cur.execute("""
        INSERT INTO dim_review (
            number_of_reviews, review_scores_rating, review_scores_accuracy,
            review_scores_cleanliness, review_scores_checkin,
            review_scores_communication, review_scores_location, review_scores_value
        )
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
        ON CONFLICT DO NOTHING;
    """, tuple(row))

conn.commit()
print("📚 Dimensões populadas com sucesso!")

# =====================================================
# 6️⃣ Criação do dicionário de mapeamento de IDs
# =====================================================
# Mapeia host_id (do CSV) para id_host (gerado pelo banco)
cur.execute("SELECT host_id, id_host FROM dim_host;")
host_map = dict(cur.fetchall())

# Mapeia latitude/longitude -> id_location
cur.execute("SELECT latitude, longitude, id_location FROM dim_location;")
loc_map = {(float(a), float(b)): c for a, b, c in cur.fetchall()}

# Mapeia hashes de review para id_review
cur.execute("""
    SELECT number_of_reviews, review_scores_rating, id_review
    FROM dim_review;
""")
review_map = {
    (float(a or 0), float(b or 0)): c
    for a, b, c in cur.fetchall()
}

conn.commit()

# =====================================================
# 7️⃣ População da FATO
# =====================================================
insert_sql = """
    INSERT INTO fato_airbnb (
        id_host, id_property, id_location, id_review,
        price, security_deposit, cleaning_fee,
        guests_included, extra_people, minimum_nights,
        n_amenities, ano, mes, dia
    )
    VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s);
"""

for _, row in df.iterrows():
    id_host = host_map.get(row["host_id"])
    id_location = loc_map.get((float(row["latitude"]), float(row["longitude"])))
    id_review = review_map.get(
        (float(row["number_of_reviews"] or 0), float(row["review_scores_rating"] or 0))
    )

    # pulando registros inválidos
    if not id_host or not id_location or not id_review:
        continue

    cur.execute(insert_sql, (
        id_host, None, id_location, id_review,  # id_property pode ser None se não precisar
        row["price"], row["security_deposit"], row["cleaning_fee"],
        row["guests_included"], row["extra_people"], row["minimum_nights"],
        row["n_amenities"], row["ano"], row["mes"], row["dia"]
    ))

conn.commit()
print("🏗️ Fato populada com sucesso!")

# =====================================================
# 8️⃣ Criação de índices
# =====================================================
cur.execute("CREATE INDEX IF NOT EXISTS idx_fato_host ON fato_airbnb (id_host);")
cur.execute("CREATE INDEX IF NOT EXISTS idx_fato_location ON fato_airbnb (id_location);")
cur.execute("CREATE INDEX IF NOT EXISTS idx_fato_review ON fato_airbnb (id_review);")
conn.commit()

cur.close()
conn.close()
print("🎉 ETL concluído com sucesso!")
