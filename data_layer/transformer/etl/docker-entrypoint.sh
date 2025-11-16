#!/bin/sh
set -e

export PGPASSWORD="${DB_PASS:-admin}"
export PGPASSWORD="${DB_PASSWORD:-admin}"
echo "[entrypoint] Waiting for database ${DB_HOST:-db}:${DB_PORT:-5432}..."

RETRIES=30
until pg_isready -h "${DB_HOST:-db}" -p "${DB_PORT:-5432}" -U "${DB_USER:-admin}" >/dev/null 2>&1 || [ $RETRIES -le 0 ]; do
    echo "[entrypoint] pg_isready: waiting... ($RETRIES)"
    RETRIES=$((RETRIES-1))
    sleep 2
done

if [ $RETRIES -le 0 ]; then
    echo "[entrypoint] ERROR: database not available after retries"
    exit 1
fi


echo "[entrypoint] Database is ready. Running SQL initialization if files exist..."

SQL_DIR=/data

echo "[entrypoint] Listing /data (debug):"
ls -la ${SQL_DIR} || true


if [ -f "${SQL_DIR}/etl_create.sql" ]; then
    echo "[entrypoint] Executing etl_create.sql"
    if psql -v ON_ERROR_STOP=1 -h "${DB_HOST:-db}" -p "${DB_PORT:-5432}" -U "${DB_USER:-admin}" -d "${DB_NAME:-lakehouse}" -f "${SQL_DIR}/etl_create.sql"; then
        echo "[entrypoint] etl_create.sql ran successfully"
    else
        echo "[entrypoint][ERROR] etl_create.sql failed (see psql output above)" >&2
        exit 1
    fi
else
    echo "[entrypoint] No etl_create.sql found at ${SQL_DIR}, skipping"
fi

# export password for non-interactive psql (used by COPY and -f)
export PGPASSWORD="${DB_PASSWORD:-admin}"

if [ -f "${SQL_DIR}/base_de_dados_prata.csv" ]; then
  echo "[entrypoint] Found CSV at ${SQL_DIR}/base_de_dados_prata.csv. Loading into staging via \copy..."
  if psql -v ON_ERROR_STOP=1 -h "${DB_HOST:-db}" -p "${DB_PORT:-5432}" -U "${DB_USER:-admin}" -d "${DB_NAME:-lakehouse}" -c "\\copy airbnb.staging_airbnb FROM '${SQL_DIR}/base_de_dados_prata.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',')"; then
    echo "[entrypoint] CSV loaded into staging successfully"
    echo "[entrypoint] staging row count:";
    psql -h "${DB_HOST:-db}" -p "${DB_PORT:-5432}" -U "${DB_USER:-admin}" -d "${DB_NAME:-lakehouse}" -c "SELECT COUNT(*) FROM airbnb.staging_airbnb;"
  else
    echo "[entrypoint][ERROR] CSV \copy failed (see psql output above)" >&2
    exit 1
  fi
else
  echo "[entrypoint] No CSV file found at ${SQL_DIR}/base_de_dados_prata.csv, skipping staging load"
fi

if [ -f "${SQL_DIR}/etl_transform.sql" ]; then
  echo "[entrypoint] Executing etl_transform.sql"
  if psql -v ON_ERROR_STOP=1 -h "${DB_HOST:-db}" -p "${DB_PORT:-5432}" -U "${DB_USER:-admin}" -d "${DB_NAME:-lakehouse}" -f "${SQL_DIR}/etl_transform.sql"; then
    echo "[entrypoint] etl_transform.sql ran successfully"
    echo "[entrypoint] Post-transform counts:";
  psql -h "${DB_HOST:-db}" -p "${DB_PORT:-5432}" -U "${DB_USER:-admin}" -d "${DB_NAME:-lakehouse}" -c "SELECT 'dim_hosts' as table, COUNT(*) FROM airbnb.dim_hosts;"
  psql -h "${DB_HOST:-db}" -p "${DB_PORT:-5432}" -U "${DB_USER:-admin}" -d "${DB_NAME:-lakehouse}" -c "SELECT 'dim_locations' as table, COUNT(*) FROM airbnb.dim_locations;"
  psql -h "${DB_HOST:-db}" -p "${DB_PORT:-5432}" -U "${DB_USER:-admin}" -d "${DB_NAME:-lakehouse}" -c "SELECT 'dim_properties' as table, COUNT(*) FROM airbnb.dim_properties;"
  psql -h "${DB_HOST:-db}" -p "${DB_PORT:-5432}" -U "${DB_USER:-admin}" -d "${DB_NAME:-lakehouse}" -c "SELECT 'dim_reviews' as table, COUNT(*) FROM airbnb.dim_reviews;"
  psql -h "${DB_HOST:-db}" -p "${DB_PORT:-5432}" -U "${DB_USER:-admin}" -d "${DB_NAME:-lakehouse}" -c "SELECT 'fact_ocorrencias' as table, COUNT(*) FROM airbnb.fact_ocorrencias;"
  else
    echo "[entrypoint][ERROR] etl_transform.sql failed (see psql output above)" >&2
    exit 1
  fi
else
  echo "[entrypoint] No etl_transform.sql found at ${SQL_DIR}, skipping"
fi

echo "[entrypoint] Initialization SQL complete. Handing off to CMD." 

exec "$@"
