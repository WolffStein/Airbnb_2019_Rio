# Modelo Entidade-Relacionamento (MER)

## 1. Introdução

O Modelo Entidade-Relacionamento (MER) descreve de forma conceitual as principais **entidades, atributos e relacionamentos** do banco de dados do projeto *Airbnb Rio de Janeiro 2019*.
Objetiva representar a estrutura lógica dos dados coletados da plataforma, permitindo análise e normalização futura.

A modelagem parte do conjunto de dados extraidos na camada prata (`base_de_dados_prata.csv`), que contém informações sobre anfitriões, anúncios, avaliações, políticas de reserva e características das propriedades.
A camada prata é obtida executando a célula 39 do arquivo `AirBnB.ipynb` 

## 2. Modelo Entidade-Relacionamento (ME-R)

### **ENTIDADES:**
* HOST
* PROPERTY
* LOCATION
* REVIEW

### **ATRIBUTOS:**

**HOST**: (<ins>host_id</ins>, host_name, host_response_time, host_response_rate, host_is_superhost, host_listings_count)

**PROPERTY**: (<ins>property_id</ins>, property_type, room_type, accommodates, bathrooms, bedrooms, beds, bed_type,
price, security_deposit, cleaning_fee, guests_included, extra_people, minimum_nights,
instant_bookable, is_business_travel_ready, cancellation_policy, n_amenities,
host_id)

**LOCATION**: (latitude, longitude)

**REVIEW**
(<ins>review_id</ins>, number_of_reviews, review_scores_rating,
review_scores_accuracy, review_scores_cleanliness, review_scores_checkin,
review_scores_communication, review_scores_location, review_scores_value, ano, mes, dia host_id)

### **RELACIONAMENTOS:**

* HOST (1) ——< PROPERTY (N)
  * Um host pode possuir vários imóveis, mas cada imóvel pertence a um único host.

* HOST (1) ——< REVIEW (N)
  * Um host pode receber várias avaliações (uma para cada imóvel seu), mas cada review pertence a um host.

* LOCATION (1) ——< PROPERTY (N)
  * Uma localização pode ter vários imóveis, mas cada imóvel tem uma única localização.


# Dicionário de Dados (DD)

| **Entidade** | **Atributo**                | **Tipo de Dado** | **Tamanho / Formato** | **Nulo** | **Descrição**                                                |
| ------------ | --------------------------- | ---------------- | --------------------- | -------- | ------------------------------------------------------------ |
| **HOST**     | host_id                     | INT              | —                     | NÃO      | Identificador único do anfitrião                             |
|              | host_name                   | VARCHAR          | 100                   | NÃO      | Nome do anfitrião                                            |
|              | host_response_time          | VARCHAR          | 50                    | SIM      | Tempo médio de resposta do anfitrião                         |
|              | host_response_rate          | VARCHAR          | 10                    | SIM      | Taxa de resposta (ex.: “100%”)                               |
|              | host_is_superhost           | BOOLEAN             | —                    | NÃO      | Indica se é Superhost (t/f)                                  |
|              | host_listings_count         | INT              | —                     | SIM      | Quantidade de propriedades cadastradas                       |
| **PROPERTY** | property_id                 | INT              | —                     | NÃO      | Identificador do imóvel                                      |
|              | property_type               | VARCHAR          | 50                    | SIM      | Tipo de imóvel (ex.: “Apartment”, “Condominium”)             |
|              | room_type                   | VARCHAR          | 50                    | SIM      | Tipo de quarto oferecido                                     |
|              | accommodates                | INT              | —                     | SIM      | Capacidade máxima de hóspedes                                |
|              | bathrooms                   | DECIMAL          | 2,1                   | SIM      | Número de banheiros                                          |
|              | bedrooms                    | INT              | —                     | SIM      | Número de quartos                                            |
|              | beds                        | INT              | —                     | SIM      | Número de camas                                              |
|              | bed_type                    | VARCHAR          | 50                    | SIM      | Tipo de cama                                                 |
|              | price                       | DECIMAL          | 10,2                  | NÃO      | Valor da diária                                              |
|              | security_deposit            | DECIMAL          | 10,2                  | SIM      | Valor do depósito de segurança                               |
|              | cleaning_fee                | DECIMAL          | 10,2                  | SIM      | Taxa de limpeza                                              |
|              | guests_included             | INT              | —                     | SIM      | Número de hóspedes incluídos no preço base                   |
|              | extra_people                | DECIMAL          | 10,2                  | SIM      | Valor cobrado por hóspede adicional                          |
|              | minimum_nights              | INT              | —                     | SIM      | Número mínimo de noites exigido                              |
|              | maximum_nights              | INT              | —                     | SIM      | Número máximo de noites permitido                            |
|              | instant_bookable            | CHAR             | 1                     | SIM      | Indica se o imóvel pode ser reservado instantaneamente (t/f) |
|              | is_business_travel_ready    | CHAR             | 1                     | SIM      | Indica se é adequado para viagens a trabalho                 |
|              | cancellation_policy         | VARCHAR          | 100                   | SIM      | Política de cancelamento aplicada                            |
|              | n_amenities                 | INT              | —                     | SIM      | Quantidade de comodidades listadas                           |
|              | host_id                     | INT              | —                     | NÃO      | Chave estrangeira que referencia HOST                        |
| **LOCATION** | latitude                    | DECIMAL          | 10,6                  | NÃO      | Coordenada geográfica (latitude)                             |
|              | longitude                   | DECIMAL          | 10,6                  | NÃO      | Coordenada geográfica (longitude)                            |
| **REVIEW**   | review_id                   | INT              | —                     | NÃO      | Identificador da avaliação                                   |
|              | number_of_reviews           | INT              | —                     | SIM      | Total de avaliações recebidas                                |
|              | review_scores_rating        | DECIMAL          | 3,1                   | SIM      | Nota geral média                                             |
|              | review_scores_accuracy      | DECIMAL          | 3,1                   | SIM      | Nota de precisão                                             |
|              | review_scores_cleanliness   | DECIMAL          | 3,1                   | SIM      | Nota de limpeza                                              |
|              | review_scores_checkin       | DECIMAL          | 3,1                   | SIM      | Nota de check-in                                             |
|              | review_scores_communication | DECIMAL          | 3,1                   | SIM      | Nota de comunicação                                          |
|              | review_scores_location      | DECIMAL          | 3,1                   | SIM      | Nota de localização                                          |
|              | review_scores_value         | DECIMAL          | 3,1                   | SIM      | Nota de custo-benefício                                      |
|              | ano                         | INT              | 4                     | NÃO      | Ano da avaliação ou registro                                 |
|              | mes                         | INT              | 2                     | NÃO      | Mês da avaliação ou registro                                 |
|              | dia                         | INT              | 2                     | NÃO      | Dia da avaliação ou registro                                 |
|              | host_id                     | INT              | —                     | NÃO      | Chave estrangeira que referencia HOST                        |



