# Modelo Entidade-Relacionamento (MER)

## **ENTIDADES**

* HOST
* PROPERTY
* LOCATION
* REVIEW

## **ATRIBUTOS**

**HOST**: (<ins>id_host</ins>, host_id, host_name, host_response_time, host_response_rate, host_is_superhost, host_listings_count)

**PROPERTY**: (<ins>id_property</ins>, property_type, room_type, bed_type, accommodates, bathrooms, bedrooms, beds, instant_bookable, is_business_travel_ready, cancellation_policy)

**LOCATION**: (<ins>id_location</ins>, latitude, longitude)

**REVIEW**: (<ins>id_review</ins>, number_of_reviews, review_scores_rating, review_scores_accuracy, review_scores_cleanliness, review_scores_checkin, review_scores_communication, review_scores_location, review_scores_value)

## **RELACIONAMENTOS**

* **HOST (1) ——< PROPERTY (N)**
  * Um host pode possuir vários imóveis, mas cada imóvel pertence a um único host.

* **LOCATION (1) ——< PROPERTY (N)**
  * Uma localização pode conter vários imóveis, mas cada imóvel pertence a uma única localização.

* **HOST (1) ——< REVIEW (N)**
  * Um host pode receber várias avaliações, mas cada avaliação pertence a um único host.

---

# Dicionário de Dados (DD)

| **Entidade** | **Atributo**                | **Tipo de Dado** | **Tamanho / Formato** | **Nulo** | **Descrição**                                       |
| ------------ | --------------------------- | ---------------- | --------------------- | -------- | --------------------------------------------------- |
| **HOST**     | id_host                     | SERIAL           | —                     | NÃO      | Identificador interno da tabela                     |
|              | host_id                     | NUMERIC          | —                     | NÃO      | Identificador único do anfitrião                    |
|              | host_name                   | TEXT             | —                     | SIM      | Nome do anfitrião                                   |
|              | host_response_time          | TEXT             | —                     | SIM      | Tempo médio de resposta do anfitrião                |
|              | host_response_rate          | NUMERIC          | —                     | SIM      | Taxa de resposta em porcentagem                     |
|              | host_is_superhost           | BOOLEAN          | —                     | SIM      | Indica se o anfitrião é Superhost                   |
|              | host_listings_count         | NUMERIC          | —                     | SIM      | Quantidade de imóveis listados pelo anfitrião       |
| **PROPERTY** | id_property                 | SERIAL           | —                     | NÃO      | Identificador interno da tabela                     |
|              | property_type               | TEXT             | —                     | SIM      | Tipo de propriedade (ex.: apartamento, casa, etc.)  |
|              | room_type                   | TEXT             | —                     | SIM      | Tipo de quarto oferecido                            |
|              | bed_type                    | TEXT             | —                     | SIM      | Tipo de cama disponível                             |
|              | accommodates                | NUMERIC          | —                     | SIM      | Capacidade máxima de hóspedes                       |
|              | bathrooms                   | NUMERIC          | —                     | SIM      | Quantidade de banheiros                             |
|              | bedrooms                    | NUMERIC          | —                     | SIM      | Quantidade de quartos                               |
|              | beds                        | NUMERIC          | —                     | SIM      | Quantidade de camas                                 |
|              | instant_bookable            | BOOLEAN          | —                     | SIM      | Indica se a reserva pode ser feita instantaneamente |
|              | is_business_travel_ready    | BOOLEAN          | —                     | SIM      | Indica se é adequado para viagens a trabalho        |
|              | cancellation_policy         | TEXT             | —                     | SIM      | Política de cancelamento aplicada                   |
| **LOCATION** | id_location                 | SERIAL           | —                     | NÃO      | Identificador interno da tabela                     |
|              | latitude                    | NUMERIC          | —                     | SIM      | Coordenada geográfica de latitude                   |
|              | longitude                   | NUMERIC          | —                     | SIM      | Coordenada geográfica de longitude                  |
| **REVIEW**   | id_review                   | SERIAL           | —                     | NÃO      | Identificador interno da tabela                     |
|              | number_of_reviews           | NUMERIC          | —                     | SIM      | Total de avaliações recebidas                       |
|              | review_scores_rating        | NUMERIC          | —                     | SIM      | Nota geral média                                    |
|              | review_scores_accuracy      | NUMERIC          | —                     | SIM      | Nota de precisão                                    |
|              | review_scores_cleanliness   | NUMERIC          | —                     | SIM      | Nota de limpeza                                     |
|              | review_scores_checkin       | NUMERIC          | —                     | SIM      | Nota de check-in                                    |
|              | review_scores_communication | NUMERIC          | —                     | SIM      | Nota de comunicação                                 |
|              | review_scores_location      | NUMERIC          | —                     | SIM      | Nota de localização                                 |
|              | review_scores_value         | NUMERIC          | —                     | SIM      | Nota de custo-benefício                             |

# Diagrama Entidade Relacionamento (DER)
<img width="748" height="641" alt="Diagrama CorridigoLight png" src="https://github.com/user-attachments/assets/ed5c182a-37d3-4575-87b7-29559edb6515" />

# Diagrama Lógico de Dados (DLD) 
<img width="1127" height="896" alt="DLD" src="https://github.com/user-attachments/assets/c26726ad-96c0-4431-8d01-b30436ce9997" />

