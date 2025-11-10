import os
import pandas as pd
import psycopg2
from tqdm import tqdm
from colorama import Fore, Style

# === CONFIGURAÇÕES ===
DB_HOST = os.getenv("DB_HOST", "db")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "lakehouse")
DB_USER = os.getenv("DB_USER", "admin")
DB_PASSWORD = os.getenv("DB_PASSWORD", "admin")

CSV_FILE = "/data/base_de_dados_prata.csv"

# === CONEXÃO COM O BANCO ===
print(Fore.CYAN + "🔗 Conectando ao banco..." + Style.RESET_ALL)
conn = psycopg2.connect(
    host=DB_HOST, port=DB_PORT, dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD
)
cur = conn.cursor()

# === CRIAÇÃO DAS TABELAS (caso ainda não existam) ===
print(Fore.YELLOW + "🧱 Criando tabelas (se não existirem)..." + Style.RESET_ALL)
cur.execute("""
CREATE TABLE IF NOT EXISTS dim_hosts (
    host_id BIGINT PRIMARY KEY,
    host_name TEXT,
    host_response_time TEXT,
    host_response_rate NUMERIC,
    host_is_superhost BOOLEAN,
    host_listings_count NUMERIC
);
""")

cur.execute("""
CREATE TABLE IF NOT EXISTS dim_properties (
    id_property SERIAL PRIMARY KEY,
    host_id BIGINT,
    location_id INT,
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
    n_amenities NUMERIC
);
""")

cur.execute("""
CREATE TABLE IF NOT EXISTS dim_locations (
    id_location SERIAL PRIMARY KEY,
    latitude NUMERIC,
    longitude NUMERIC
);
""")

cur.execute("""
CREATE TABLE IF NOT EXISTS dim_reviews (
    id_review SERIAL PRIMARY KEY,
    host_id BIGINT,
    property_id INT,
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

cur.execute("""
CREATE TABLE IF NOT EXISTS fact_ocorrencias (
    id SERIAL PRIMARY KEY,
    host_id BIGINT REFERENCES dim_hosts(host_id),
    property_id INT REFERENCES dim_properties(id_property),
    location_id INT REFERENCES dim_locations(id_location),
    review_id INT REFERENCES dim_reviews(id_review),
    price NUMERIC,
    security_deposit NUMERIC,
    cleaning_fee NUMERIC,
    extra_people NUMERIC,
    guests_included NUMERIC,
    minimum_nights INT,
    ano INT,
    mes INT
);
""")
conn.commit()

# === LEITURA DA BASE PRATA ===
print(Fore.BLUE + "📂 Lendo CSV..." + Style.RESET_ALL)
df = pd.read_csv(CSV_FILE)

# Limitar a 2% dos registros para teste
subset_size = int(len(df) * 0.02)
df = df.head(subset_size)
print(Fore.YELLOW + f"⚠️  Rodando com apenas {len(df)} registros (2% do total) para teste." + Style.RESET_ALL)

# === INSERÇÃO NAS TABELAS ===
print(Fore.GREEN + f"🚀 Inserindo {len(df)} registros... Isso pode levar alguns minutos." + Style.RESET_ALL)

for _, row in tqdm(df.iterrows(), total=len(df)):
    try:
        # Inserir dimensões
        cur.execute("""
            INSERT INTO dim_hosts (host_id, host_name, host_response_time, host_response_rate, host_is_superhost, host_listings_count)
            VALUES (%s, %s, %s, %s, %s, %s)
            ON CONFLICT (host_id) DO NOTHING
            RETURNING host_id;
        """, (
            row["host_id"], row["host_name"], row["host_response_time"],
            row["host_response_rate"], row["host_is_superhost"], row["host_listings_count"]
        ))
        host_id = cur.fetchone()
        if not host_id:
            cur.execute("SELECT host_id FROM dim_hosts WHERE host_id = %s;", (row["host_id"],))
            host_id = cur.fetchone()
        host_id = host_id[0]

        cur.execute("""
            INSERT INTO dim_properties (host_id, location_id, property_type, room_type, bed_type, accommodates, bathrooms, bedrooms, beds,
                                      instant_bookable, is_business_travel_ready, cancellation_policy, n_amenities)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            RETURNING id_property;
        """, (
            host_id, row.get("location_id"), row["property_type"], row["room_type"], row["bed_type"], row["accommodates"],
            row["bathrooms"], row["bedrooms"], row["beds"],
            row["instant_bookable"], row["is_business_travel_ready"], row["cancellation_policy"], row.get("n_amenities")
        ))
        property_id = cur.fetchone()[0]

        cur.execute("""
            INSERT INTO dim_locations (latitude, longitude)
            VALUES (%s, %s)
            RETURNING id_location;
        """, (row["latitude"], row["longitude"]))
        location_id = cur.fetchone()[0]

        cur.execute("""
            INSERT INTO dim_reviews (host_id, property_id, number_of_reviews, review_scores_rating, review_scores_accuracy, review_scores_cleanliness,
                                    review_scores_checkin, review_scores_communication, review_scores_location, review_scores_value)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            RETURNING id_review;
        """, (
            host_id, property_id, row["number_of_reviews"], row["review_scores_rating"], row["review_scores_accuracy"],
            row["review_scores_cleanliness"], row["review_scores_checkin"],
            row["review_scores_communication"], row["review_scores_location"], row["review_scores_value"]
        ))
        review_id = cur.fetchone()[0]

        # Inserir fato (sem ano/mes)
        cur.execute("""
            INSERT INTO fact_ocorrencias (host_id, property_id, location_id, review_id,
                                      price, security_deposit, cleaning_fee, extra_people, guests_included, minimum_nights, ano, mes)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s);
        """, (
            host_id, property_id, location_id, review_id,
            row.get("price"), row.get("security_deposit"), row.get("cleaning_fee"),
            row.get("extra_people"), row.get("guests_included"), row.get("minimum_nights"), row.get("ano"), row.get("mes")
        ))

        conn.commit()

    except Exception as e:
        conn.rollback()
        print(Fore.RED + f"❌ Erro ao inserir linha: {e}" + Style.RESET_ALL)

cur.close()
conn.close()
print(Fore.GREEN + "✅ Carga concluída com sucesso!" + Style.RESET_ALL)
