# Modelo Entidade-Relacionamento (MER)

## 1. Introdução

O Modelo Entidade-Relacionamento (MER) descreve de forma conceitual as principais **entidades, atributos e relacionamentos** do banco de dados do projeto *Airbnb Rio de Janeiro 2019*.
Objetiva representar a estrutura lógica dos dados coletados da plataforma, permitindo análise e normalização futura.

A modelagem parte do conjunto de dados extraidos na camada prata (`base_de_dados_prata.csv`), que contém informações sobre anfitriões, anúncios, avaliações, políticas de reserva e características das propriedades.
A camada prata é obtida executando a célula 39 do arquivo `AirBnB.ipynb` 

## 2. Entidades e Atributos

### **Host**

**Descrição:** Representa o proprietário ou administrador responsável por um ou mais anúncios.

| Atributo         | Tipo conceitual     | Descrição                                        |
| ---------------- | ------------------- | ------------------------------------------------ |
| `host_id`        | Identificador       | Identificador único do anfitrião                 |
| `response_time`  | Texto categórico    | Tempo médio de resposta (ex.: within an hour)  |
| `response_rate`  | Numérico percentual | Taxa de resposta (%)                             |
| `is_superhost`   | Booleano            | Indica se o anfitrião é Superhost              |
| `listings_count` | Numérico inteiro    | Quantidade total de anúncios ativos do anfitrião |

**Observação:** cada Host pode ter **múltiplos anúncios (1:N)**.

### **Listing**

**Descrição:** Representa uma acomodação (anúncio) cadastrada na plataforma.

| Atributo                        | Tipo conceitual  | Descrição                                     |
| ------------------------------- | ---------------- | --------------------------------------------- |
| `listing_id`                    | Identificador    | Identificador único do anúncio                |
| `property_type`                 | Texto categórico | Tipo de propriedade (ex.: *Apartment, House*) |
| `room_type`                     | Texto categórico | Tipo de quarto (ex.: *Entire home/apt*)       |
| `bed_type`                      | Texto categórico | Tipo de cama principal                        |
| `accommodates`                  | Numérico inteiro | Número máximo de hóspedes                     |
| `bathrooms`, `bedrooms`, `beds` | Numérico         | Quantidades físicas do imóvel                 |
| `latitude`, `longitude`         | Numérico         | Localização geográfica                        |
| `n_amenities`                   | Numérico inteiro | Número total de amenidades ofertadas          |

**Relacionamentos:**

* **1:N com Host**
* **N:M com Amenity**
* **1:N com ListingMonthly**

### **Amenity**

**Descrição:** Representa uma amenidade (comodidade) oferecida nos anúncios.

| Atributo       | Tipo conceitual | Descrição                                           |
| -------------- | --------------- | --------------------------------------------------- |
| `amenity_id`   | Identificador   | Identificador da amenidade                          |
| `amenity_name` | Texto           | Nome da amenidade (ex.: *Wi-Fi*, *Kitchen*, *Pool*) |

**Relacionamento:** N:M com `Listing` via tabela associativa `ListingAmenity`.


### **ListingAmenity**

**Descrição:** Entidade associativa que representa o relacionamento N:M entre *Listing* e *Amenity*.

| Atributo     | Tipo conceitual | Descrição              |
| ------------ | --------------- | ---------------------- |
| `listing_id` | FK              | Referência ao anúncio  |
| `amenity_id` | FK              | Referência à amenidade |

**Chave Primária:** composta (`listing_id`, `amenity_id`).

###  **Date**

**Descrição:** Representa o período (ano/mês) de referência do conjunto de dados.

| Atributo  | Tipo conceitual  | Descrição                             |
| --------- | ---------------- | ------------------------------------- |
| `date_id` | Identificador    | Código único do período (e.g. 201904) |
| `year`    | Numérico inteiro | Ano de referência                     |
| `month`   | Numérico inteiro | Mês de referência (1–12)              |

**Relacionamento:** 1:N com `ListingMonthly`.

### **ListingMonthly**

**Descrição:** Representa o retrato mensal de cada anúncio, contendo preços, notas de avaliação e políticas de reserva.
Cada instância corresponde à combinação `(listing_id, date_id)`.

| Atributo                                           | Tipo conceitual  | Descrição                                              |
| -------------------------------------------------- | ---------------- | ------------------------------------------------------ |
| `listing_id`                                       | FK               | Identificador do anúncio                               |
| `date_id`                                          | FK               | Identificador do período                               |
| `price`                                            | Numérico real    | Preço da diária                                        |
| `security_deposit`, `cleaning_fee`, `extra_people` | Numérico real    | Taxas e valores adicionais                             |
| `guests_included`                                  | Inteiro          | Número de hóspedes incluídos no valor base             |
| `number_of_reviews`                                | Inteiro          | Total de avaliações acumuladas                         |
| `review_scores_*`                                  | Numérico real    | Conjunto de notas (rating, cleanliness, location etc.) |
| `instant_bookable`                                 | Booleano         | Indica se o imóvel pode ser reservado instantaneamente |
| `is_business_travel_ready`                         | Booleano         | Indica se o anúncio atende critérios corporativos      |
| `cancellation_policy`                              | Texto categórico | Política de cancelamento                               |
| `n_amenities`                                      | Inteiro          | Quantidade total de amenidades (campo derivado)        |

**Relacionamentos:**

* 1:N com `Listing`
* 1:N com `Date`


## 3. Relacionamentos e Cardinalidades

| Relacionamento               | Entidades | Cardinalidade                                                             |
| ---------------------------- | --------- | ------------------------------------------------------------------------- | 
| `Host` – `Listing`           | 1:N       | Um host possui vários anúncios; cada anúncio pertence a um único host     |           
| `Listing` – `ListingMonthly` | 1:N       | Cada anúncio possui vários registros mensais                              |           
| `Date` – `ListingMonthly`    | 1:N       | Cada mês agrega vários registros de anúncios                              |           
| `Listing` – `Amenity`        | N:M       | Um anúncio pode ter várias amenidades e vice-versa (via `ListingAmenity`) |           


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

