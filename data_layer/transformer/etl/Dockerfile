# Imagem base do Python
FROM python:3.11-slim

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Copia todos os arquivos da pasta local (etl/) para dentro do container
COPY . .

# Instala as dependências necessárias e o cliente psql
RUN apt-get update \
	&& apt-get install -y --no-install-recommends postgresql-client gcc libpq-dev \
	&& pip install pandas psycopg2-binary tqdm colorama \
	&& apt-get remove -y gcc \
	&& apt-get autoremove -y \
	&& rm -rf /var/lib/apt/lists/*

# Copia scripts SQL que existem no bind-mounted project root into /data via docker-compose volume
# (Compose already mounts project root to /data in service definition)

# Add an entrypoint script that waits for the DB and runs SQL files, then starts the Python loader
RUN chmod +x /app/docker-entrypoint.sh

ENTRYPOINT ["/app/docker-entrypoint.sh"]

# Default command (entrypoint will exec this at the end)
#CMD ["python", "populate_db.py"]