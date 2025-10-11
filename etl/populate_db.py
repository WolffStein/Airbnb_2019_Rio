import os
import sys
import pandas as pd
import psycopg2
from tqdm import tqdm
from colorama import Fore, Style, init

# ===== Inicializações =====
init(autoreset=True)
sys.stdout.reconfigure(line_buffering=True)  # imprime os logs em tempo real

# ===== Configurações do banco =====
DB_HOST = os.getenv("DB_HOST", "db")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "lakehouse")
DB_USER = os.getenv("DB_USER", "admin")
DB_PASSWORD = os.getenv("DB_PASSWORD", "admin")
CSV_PATH = "/data/base_de_dados_prata.csv"

# ===== Conexão =====
print(Fore.CYAN + "🔗 Conectando ao banco...")
conn = psycopg2.connect(
    host=DB_HOST,
    port=DB_PORT,
    dbname=DB_NAME,
    user=DB_USER,
    password=DB_PASSWORD
)
cur = conn.cursor()

# ===== Criação das tabelas =====
print(Fore.YELLOW + "🧱 Criando tabelas (se não existirem)...")

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

cur.execute("""
CREATE TABLE IF NOT EXISTS fact_listing (
    id_listing SERIAL PRIMARY KEY,
    id_host INT REFERENCES dim_host(id_host),
    id_property INT REFERENCES dim_property(id_property),
    id_location INT REFERENCES dim_location(id_location),
    id_review INT REFERENCES dim_review(id_review),
    price NUMERIC,
    security_deposit NUMERIC,
    cleaning_fee NUMERIC,
    guests_included INT,
    extra_people NUMERIC,
    minimum_nights INT,
    maximum_nights INT
);
""")
conn.commit()

# ===== Leitura do CSV =====
print(Fore.CYAN + "📂 Lendo CSV...")
df = pd.read_csv(CSV_PATH, sep=";", encoding="utf-8")

# ===== Função auxiliar =====
def insert_unique(table, unique_cols, values_dict):
    """Insere registro se não existir e retorna o id."""
    cols = list(values_dict.keys())
    vals = [values_dict[c] for c in cols]
    placeholders = ", ".join(["%s"] * len(cols))
    cols_str = ", ".join(cols)
    where_clause = " AND ".join([f"{c} = %s" for c in unique_cols])

    cur.execute(f"SELECT id_{table.split('_')[1]} FROM {table} WHERE {where_clause};",
                [values_dict[c] for c in unique_cols])
    result = cur.fetchone()
    if result:
        return result[0]

    cur.execute(
        f"INSERT INTO {table} ({cols_str}) VALUES ({placeholders}) RETURNING id_{table.split('_')[1]};",
        vals
    )
    return cur.fetchone()[0]

# ===== População =====
print(Fore.GREEN + f"🚀 Inserindo {len(df)} registros... Isso pode levar alguns minutos.")

dim_counts = {"dim_host": 0, "dim_property": 0, "dim_location": 0, "dim_review": 0}
fact_count = 0

for _, row in tqdm(df.iterrows(), total=len(df), desc="Processando registros", disable=False, ascii=True, file=sys.stdout):
    r = row.where(pd.notnull(row), None)

    try:
        # --- Dimensões ---
        id_host = insert_unique("dim_host", ["host_id"], {
            "host_id": r.get("host_id"),
            "host_name": r.get("host_name"),
            "host_response_time": r.get("host_response_time"),
            "host_response_rate": r.get("host_response_rate"),
            "host_is_superhost": r.get("host_is_superhost"),
            "host_listings_count": r.get("host_listings_count")
        })
        dim_counts["dim_host"] += 1

        id_property = insert_unique("dim_property",
            ["property_type", "room_type", "bed_type", "accommodates", "bathrooms", "bedrooms", "beds"],
            {
                "property_type": r.get("property_type"),
                "room_type": r.get("room_type"),
                "bed_type": r.get("bed_type"),
                "accommodates": r.get("accommodates"),
                "bathrooms": r.get("bathrooms"),
                "bedrooms": r.get("bedrooms"),
                "beds": r.get("beds"),
                "instant_bookable": r.get("instant_bookable"),
                "is_business_travel_ready": r.get("is_business_travel_ready"),
                "cancellation_policy": r.get("cancellation_policy")
            }
        )
        dim_counts["dim_property"] += 1

        id_location = insert_unique("dim_location", ["latitude", "longitude"], {
            "latitude": r.get("latitude"),
            "longitude": r.get("longitude")
        })
        dim_counts["dim_location"] += 1

        id_review = insert_unique("dim_review", ["number_of_reviews", "review_scores_rating"], {
            "number_of_reviews": r.get("number_of_reviews"),
            "review_scores_rating": r.get("review_scores_rating"),
            "review_scores_accuracy": r.get("review_scores_accuracy"),
            "review_scores_cleanliness": r.get("review_scores_cleanliness"),
            "review_scores_checkin": r.get("review_scores_checkin"),
            "review_scores_communication": r.get("review_scores_communication"),
            "review_scores_location": r.get("review_scores_location"),
            "review_scores_value": r.get("review_scores_value")
        })
        dim_counts["dim_review"] += 1

        # --- Fato ---
        cur.execute("""
            INSERT INTO fact_listing (
                id_host, id_property, id_location, id_review,
                price, security_deposit, cleaning_fee,
                guests_included, extra_people, minimum_nights, maximum_nights
            )
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s);
        """, (
            id_host, id_property, id_location, id_review,
            r.get("price"), r.get("security_deposit"), r.get("cleaning_fee"),
            r.get("guests_included"), r.get("extra_people"),
            r.get("minimum_nights"), r.get("maximum_nights")
        ))
        fact_count += 1

    except Exception as e:
        conn.rollback()
        print(Fore.RED + f"\n❌ Erro ao inserir linha: {e}")
        continue

conn.commit()
cur.close()
conn.close()

# ===== Resumo =====
print(Style.BRIGHT + "\n✅ ETL concluído com sucesso!")
print(Fore.CYAN + f"   - Linhas processadas: {len(df)}")
print(Fore.YELLOW + f"   - Inserções em dim_host: {dim_counts['dim_host']}")
print(Fore.YELLOW + f"   - Inserções em dim_property: {dim_counts['dim_property']}")
print(Fore.YELLOW + f"   - Inserções em dim_location: {dim_counts['dim_location']}")
print(Fore.YELLOW + f"   - Inserções em dim_review: {dim_counts['dim_review']}")
print(Fore.GREEN + f"   - Registros adicionados em fact_listing: {fact_count}")
print(Fore.CYAN + "\n💡 Dica: use pgAdmin (http://localhost:5050) para explorar as tabelas!")
