# Imagem base do Python
FROM python:3.11-slim

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Copia todos os arquivos da pasta local (etl/) para dentro do container
COPY . .

# Instala as dependências necessárias
RUN pip install pandas psycopg2-binary

# Define o comando padrão que o container vai executar
CMD ["python", "populate_db.py"]