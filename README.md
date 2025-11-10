# 🏡 Airbnb_2019_Rio

Repositório voltado para **análise de dados** e **desenvolvimento de um banco de dados** baseado nas informações do **Airbnb do Rio de Janeiro em 2019**.  
O projeto utiliza **Jupyter Notebook** para exploração, tratamento e visualização dos dados.

---

## 🚀 Instruções de uso
# 🏡 Airbnb_2019_Rio

Repositório para exploração do conjunto de dados Airbnb (Rio de Janeiro) e para um pipeline ETL leve que popula um banco PostgreSQL dentro de containers Docker.

Resumo rápido
- Dados de entrada (camada prata): `base_de_dados_prata.csv` (gerado pelo notebook `AirBnB.ipynb`).
- ETL executado dentro do container `etl` que roda dois scripts SQL idempotentes: `etl_create.sql` (DDL) e `etl_transform.sql` (transformações).
- Schema alvo: schema `airbnb` com tabelas `dim_*` (dim_hosts, dim_locations, dim_properties, dim_reviews) e a tabela fato `fact_ocorrencias`.

Principais arquivos
- `etl_create.sql` — cria schema `airbnb`, tabelas `airbnb.staging_airbnb`, `airbnb.dim_*` e `airbnb.fact_ocorrencias`. (Idempotente — safe to run.)
- `etl_transform.sql` — transforma dados de `staging_airbnb` para as `dim_*` e popula `fact_ocorrencias`. Contém diagnósticos úteis para debug.
- `etl/`:
	- `Dockerfile` — imagem do serviço ETL (instala psql, deps Python)
	- `docker-entrypoint.sh` — aguarda o DB, executa `etl_create.sql`, faz `\copy` para `staging_airbnb`, executa `etl_transform.sql` e, por fim, executa `populate_db.py` (opcional).
	- `populate_db.py` — utilitário Python de carga/validação (mantido para testes locais).
- `docker-compose.yml` — define serviços: `db` (Postgres), `etl` e `pgadmin`.

Como rodar (Windows / PowerShell)
1) Build e subir containers:
```powershell
docker compose build etl
docker compose up --build
```

2) Acompanhar logs do ETL (útil para ver diagnósticos e contagens):
```powershell
docker compose logs -f etl
```

3) Comandos úteis para inspeção direta no banco (psql client dentro do serviço `db`):
```powershell
# abrir um shell psql interativo
docker compose exec db psql -U admin -d lakehouse

# verificar contagens
docker compose exec db psql -U admin -d lakehouse -c "SELECT COUNT(*) FROM airbnb.staging_airbnb;"
docker compose exec db psql -U admin -d lakehouse -c "SELECT COUNT(*) FROM airbnb.dim_hosts;"
docker compose exec db psql -U admin -d lakehouse -c "SELECT COUNT(*) FROM airbnb.fact_ocorrencias;"
```

Arquitetura ETL (resumo)
- O entrypoint do container `etl`:
	1. Espera o Postgres ficar pronto.
	2. Executa `etl_create.sql` (cria esquema/tabelas).
	3. Carrega `base_de_dados_prata.csv` para `airbnb.staging_airbnb` via `\copy` (cliente psql).
	4. Executa `etl_transform.sql` (inserções nas `dim_*` e `fact_ocorrencias`).
	5. Roda `populate_db.py` (sequência adicional para testes/validação)

Modelagem atual
- Dimensões: `airbnb.dim_hosts`, `airbnb.dim_locations`, `airbnb.dim_properties`, `airbnb.dim_reviews`.
- Fato: `airbnb.fact_ocorrencias` — centraliza as medidas (price, security_deposit, cleaning_fee, guests_included, minimum_nights, ano, mes) e referencia as dims via FKs.

Diagnóstico e troubleshooting
- `etl_transform.sql` inclui SELECTs de diagnóstico que imprimem contagens de candidatos para cada dim e para a fact. Verifique os logs do ETL para essas métricas.
- Se uma etapa falhar, o entrypoint imprime mensagens claras e sai com código de erro. Use `docker compose logs etl` para ver o erro completo (ERROR/DETAIL/HINT).
- Para reprovação rápida do transform, você pode rodar manualmente dentro do container `db`:
```powershell
docker compose exec db psql -U admin -d lakehouse -f /data/etl_transform.sql
```

Notas importantes
- O arquivo monolítico `etl.sql` foi removido/arquivado — o fluxo atual usa `etl_create.sql` + `etl_transform.sql` (mais confiável e modular).
- `.gitignore` inclui `*.csv` para evitar commitar grandes CSVs acidentalmente.

Próximos passos sugeridos
- (opcional) Adicionar índices em `fact_ocorrencias` por `ano, mes` para consultas analíticas.
- (opcional) Implementar deduplicação/unique constraints mais específicas na `fact_ocorrencias` para evitar eventos duplicados.

Contatos
- Edilberto Almeida Cantuária — [LinkedIn](https://www.linkedin.com/in/edilberto-cantuaria)
- Wolfgang Friedrich Stein — [GitHub](https://github.com/WolffStein)

---

Se quiser, eu atualizo este README com comandos específicos para Windows/PowerShell, exemplos de queries de validação (SELECTs JOIN) ou adiciono um pequeno script `check_etl.sh` para rodar verificações pós-ETL automaticamente. Diga o que prefere.
└── data/                     # Volumes do PostgreSQL e pgAdmin
