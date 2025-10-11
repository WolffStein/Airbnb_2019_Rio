# Modelo Entidade-Relacionamento (MER)

## 1. Introdução

O Modelo Entidade-Relacionamento (MER) descreve de forma conceitual as principais **entidades, atributos e relacionamentos** do banco de dados do projeto *Airbnb Rio de Janeiro 2019*.
Objetiva representar a estrutura lógica dos dados coletados da plataforma, permitindo análise e normalização futura.

A modelagem parte do conjunto de dados extraidos na camada prata (`base_de_dados_prata.csv`), que contém informações sobre anfitriões, anúncios, avaliações, políticas de reserva e características das propriedades.
A camada prata é obtida executando a célula 39 do arquivo `AirBnB.ipynb` 

## 2. Entidades e Atributos

Perfeito 👌
Abaixo está o **Modelo Entidade-Relacionamento (ME-R)** no **mesmo formato do exemplo da imagem**, com chaves primárias sublinhadas e mantendo os nomes originais do seu conjunto de dados (incluindo `host_id` e `host_name`).

---

# Modelo Entidade-Relacionamento (ME-R)

## **ENTIDADES:**
* HOST
* PROPERTY
* LOCATION
* REVIEW

## **ATRIBUTOS:**

**HOST**: (<ins>host_id</ins>, host_name, host_response_time, host_response_rate, host_is_superhost, host_listings_count)

**PROPERTY**: (<ins>idProperty</ins>, property_type, room_type, accommodates, bathrooms, bedrooms, beds, bed_type, price,
security_deposit, cleaning_fee, guests_included, extra_people, minimum_nights, instant_bookable,
is_business_travel_ready, cancellation_policy, n_amenities, host_id)

**LOCATION**: (latitude, longitude)

**REVIEW**: (<ins>idReview</ins>, number_of_reviews, review_scores_rating, review_scores_accuracy,
review_scores_cleanliness, review_scores_checkin, review_scores_communication,
review_scores_location, review_scores_value, ano, mes, host_id)



## **RELACIONAMENTOS:**

**PROPERTY – pertence – HOST**
Um HOST pode ter vários imóveis (PROPERTY), e cada PROPERTY pertence a um único HOST.
**Cardinalidade:** 1:N

**PROPERTY – está_em – LOCATION**
Uma LOCATION pode conter vários imóveis (PROPERTY), mas cada PROPERTY pertence a uma única LOCATION.
**Cardinalidade:** 1:N

**REVIEW – refere_se – PROPERTY**
Uma PROPERTY pode ter várias avaliações (REVIEW), e cada REVIEW pertence a uma única PROPERTY.
**Cardinalidade:** 1:N

---

Deseja que eu gere **esse mesmo MER em `.drawio`** (com as chaves sublinhadas e ligações 1:N visuais)?

# Dicionário de Dados (DD)

## Tabela: `hosts`

| Campo            | Tipo lógico  | Descrição                   | Restrições  |
| ---------------- | ------------ | --------------------------- | ----------- |
| `host_id`        | INT / UUID   | Identificador único do host | PK          |
| `response_time`  | VARCHAR(30)  | Tempo médio de resposta     | NOT NULL    |
| `response_rate`  | DECIMAL(5,2) | Taxa percentual de resposta | CHECK 0–100 |
| `is_superhost`   | BOOLEAN      | Indica status de Superhost  | NOT NULL    |
| `listings_count` | INT          | Quantidade de anúncios      | ≥ 0         |


## Tabela: `listings`

| Campo                                           | Tipo lógico  | Descrição                     | Restrições                               |
| ----------------------------------------------- | ------------ | ----------------------------- | ---------------------------------------- |
| `listing_id`                                    | INT / UUID   | Identificador do anúncio      | PK                                       |
| `host_id`                                       | INT / UUID   | Referência ao host            | FK → hosts                               |
| `property_type`, `room_type`, `bed_type`        | VARCHAR      | Categorias descritivas        | NOT NULL                                 |
| `accommodates`, `bathrooms`, `bedrooms`, `beds` | NUMERIC      | Capacidade e estrutura física | ≥ 0                                      |
| `latitude`, `longitude`                         | DECIMAL(9,6) | Coordenadas geográficas       | CHECK (-90 ≤ lat ≤ 90, -180 ≤ lon ≤ 180) |
| `n_amenities`                                   | INT          | Número total de amenidades    | Campo derivado                           |


## Tabela: `amenities`

| Campo          | Tipo lógico  | Descrição                  | Restrições |
| -------------- | ------------ | -------------------------- | ---------- |
| `amenity_id`   | INT          | Identificador da amenidade | PK         |
| `amenity_name` | VARCHAR(100) | Nome da amenidade          | UNIQUE     |


## Tabela: `listing_amenities`

| Campo        | Tipo lógico | Descrição           | Restrições |
| ------------ | ----------- | ------------------- | ---------- |
| `listing_id` | INT         | FK para `listings`  | PK, FK     |
| `amenity_id` | INT         | FK para `amenities` | PK, FK     |


## Tabela: `dates`

| Campo     | Tipo lógico | Descrição                      | Restrições |
| --------- | ----------- | ------------------------------ | ---------- |
| `date_id` | INT         | Identificador único do período | PK         |
| `year`    | SMALLINT    | Ano (ex.: 2019)                | NOT NULL   |
| `month`   | TINYINT     | Mês (1–12)                     | CHECK 1–12 |


## Tabela: `listing_monthly`

| Campo                                                       | Tipo lógico   | Descrição                             | Restrições    |
| ----------------------------------------------------------- | ------------- | ------------------------------------- | ------------- |
| `listing_id`                                                | INT           | FK para `listings`                    | PK, FK        |
| `date_id`                                                   | INT           | FK para `dates`                       | PK, FK        |
| `price`, `security_deposit`, `cleaning_fee`, `extra_people` | DECIMAL(10,2) | Preços e taxas                        | ≥ 0           |
| `guests_included`                                           | INT           | Número de hóspedes base               | ≥ 1           |
| `number_of_reviews`                                         | INT           | Quantidade total de avaliações        | ≥ 0           |
| `review_scores_*`                                           | DECIMAL(4,1)  | Conjunto de notas (0–10)              | CHECK 0–10    |
| `instant_bookable`, `is_business_travel_ready`              | BOOLEAN       | Políticas booleanas                   | —             |
| `cancellation_policy`                                       | VARCHAR(50)   | Tipo de política                      | ENUM restrito |
| `n_amenities`                                               | INT           | Número de amenidades (campo derivado) | ≥ 0           |

