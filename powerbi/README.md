# Power BI – Dashboards para Airbnb Rio 2019

Este guia explica como consumir as views SQL criadas (arquivo `powerbi/views_gold.sql`) e montar dashboards no Power BI a partir do PostgreSQL do projeto.

## 1) Subir o banco (Docker)
Em um PowerShell na raiz do projeto:
```powershell
docker-compose up -d
```
Credenciais (do `docker-compose.yml`):
- Host: `localhost`
- Porta: `5432`
- Banco: `airbnb`
- Usuário: `postgres`
- Senha: `postgres`

## 2) Criar as Views no PostgreSQL
Use o pgAdmin (http://localhost:5050 – usuário `admin@admin.com`, senha `admin`) ou `psql` para executar o script:
- Arquivo: `powerbi/views_gold.sql`
- Isso criará as views `gold.v_*` correspondentes a cada análise.

## 3) Conectar o Power BI ao PostgreSQL
No Power BI Desktop:
- Get Data (Obter Dados) > PostgreSQL database
- Server: `localhost:5432`
- Database: `airbnb`
- Data Connectivity mode: escolha `DirectQuery` (atualização em tempo real) ou `Import` (melhor performance)
- Credenciais: Database > usuário `postgres`, senha `postgres`
- SSL: em ambiente local, pode desmarcar criptografia se necessário (ou manter padrão)
- Se desejar, use a opção Advanced > SQL statement para puxar uma view específica.

Recomendação: marque apenas as views `gold.v_*` que deseja usar (por ex.: `gold.v_precificacao_tipo_quarto`, `gold.v_modelo_reserva`, etc.).

## 4) Modelagem (relacionamentos)
Se optar por usar as tabelas base (`gold.dim_*` e `gold.fact_ocorrencias`) em vez das views, crie os relacionamentos:

**Esquema Star Schema:**
- `fact_ocorrencias[srk_property_id]` → `dim_properties[srk_property_id]` 
  - **Cardinalidade:** Muitos para Um (N:1)
  - **Direção do filtro:** Única (dim_properties → fact_ocorrencias)
  - fact_ocorrencias é a tabela de fatos (pode ter múltiplas ocorrências por propriedade)

- `dim_properties[srk_host_id]` → `dim_hosts[srk_host_id]`
  - **Cardinalidade:** Muitos para Um (N:1)
  - **Direção do filtro:** Única (dim_hosts → dim_properties)
  - Um host pode ter várias propriedades

- `dim_properties[srk_property_id]` → `dim_reviews[srk_property_id]`
  - **Cardinalidade:** Um para Um (1:1)
  - **Direção do filtro:** Ambas (bidirecional) ⚠️ ou Única (preferível)
  - Cada propriedade tem apenas um registro de review agregado

- `dim_properties[srk_location_id]` → `dim_locations[srk_location_id]`
  - **Cardinalidade:** Muitos para Um (N:1)
  - **Direção do filtro:** Única (dim_locations → dim_properties)
  - Várias propriedades podem compartilhar a mesma localização

**⚠️ Importante:**
- Marque `dim_properties` como tabela central (se usar esquema estrela)
- Evite relacionamentos bidirecionais quando possível (podem impactar performance)
- Use relacionamentos ativos; relacionamentos inativos podem ser úteis para cenários específicos

Use também uma **dimensão calendário** se for analisar além de `ano`/`mes` nativos:
- Criar tabela Calendar com datas de 2019
- Relacionar: `fact_ocorrencias[date]` → `Calendar[Date]` (N:1)

## 5) Medidas DAX
O arquivo `powerbi/dax_measures.md` traz um conjunto de medidas prontas (Preço Médio, Nota Média, Receita Mínima, Preço por Pessoa, Market Share, Segmento Preço x Qualidade, etc.).

## 6) Blueprint de Páginas (sugestão)
- Hosts & Competitividade
  - Tabela: `v_host_ranking_superhosts`
  - Gráfico de barras: `v_superhosts_vs_hosts` (comparar preço, notas, market share)
  - Distribuição: `v_concentracao_mercado_hosts`
- Precificação
  - Box/Colunas: `v_precificacao_tipo_quarto`
  - Barras: `v_taxas_adicionais` (Taxa limpeza %)
  - Barras: `v_politica_estadia_minima` (receita mínima x avaliação)
- Qualidade
  - Tabela Top-N: `v_top_propriedades_avaliacao`
  - Radar/Colunas: `v_avaliacoes_por_roomtype`
  - Dispersão: `v_comodidades_correlacao` (amenities x nota x preço)
- Geografia
  - Mapa/Heatmap: `v_hotspots_premium` (lat/lon arredondado)
  - Barras: `v_densidade_localizacao`
- Temporal
  - Linha: `v_precos_por_mes_2019`
  - Cartões/Comparativos: `v_eventos_especiais_variacao`
- Modelos de Negócio
  - Pizza/Barras: `v_modelo_reserva`
  - Tabela: `v_business_travel_ready`
  - Dispersão: `v_capacidade_vs_demanda`
- Insights Estratégicos
  - Matriz/Heatmap: `v_segmentacao_preco_qualidade`
  - Tabela oportunidades: `v_gaps_mercado`
  - KPIs: `v_benchmark_top100`

## 7) Atualização e Performance
- DirectQuery: bom para dados sempre atualizados; pode ser mais lento em visuais complexos.
- Import: melhor performance; agende atualizações no Power BI Service se publicar.

## 8) Observações
- A view `v_segmentacao_preco_qualidade` ajusta a junção de reviews por `srk_property_id`.
- Caso prefira maior flexibilidade com segmentações/slicers, use as tabelas base e as medidas DAX em vez das views Top-N com `LIMIT`.
