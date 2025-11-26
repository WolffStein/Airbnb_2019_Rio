# 📘 Documento de Mnemônicos – Camada GOLD (Airbnb Rio)



## 1. Mnemônicos Gerais 

| Sigla | Descrição |
|-------|-----------|
| srk | surrogate key |
| fk | foreign key |
| id | identificador |
| nm | nome |
| dsc | descrição |
| qt | quantidade |
| vlr | valor monetário |
| pct | percentual |
| ano | ano |
| mes | mês |
| lat | latitude |
| lon | longitude |
| tp | tipo |
| dep | depósito |
| min | mínimo |
| inc | incluído |



---

## 2. Mnemônicos por Tabela

---

# DIM_HOSTS

| Atributo | Mnemônico | Descrição |
|----------|-----------|-----------|
| srk_host_id | srk_host | Surrogate key do host |
| host_id_original | host_orig | ID original do dataset |
| host_name | host_nm | Nome do anfitrião |
| host_response_time | host_resp_tm | Tempo médio de resposta |
| host_response_rate | host_resp_rt | Taxa de resposta |
| host_is_superhost | host_sph | Indica se é superhost |
| host_listings_count | host_lst_qt | Quantidade de listagens |

---

# DIM_PROPERTIES

| Atributo | Mnemônico | Descrição |
|----------|-----------|-----------|
| srk_property_id | srk_prop | Surrogate key da propriedade |
| srk_host_id | fk_host | FK para dim_hosts |
| srk_location_id | fk_loc | FK para dim_locations |
| property_type | prop_tp | Tipo de propriedade |
| room_type | room_tp | Tipo de quarto |
| bed_type | bed_tp | Tipo de cama |
| accommodates | acc_qt | Capacidade de hóspedes |
| bathrooms | bath_qt | Número de banheiros |
| bedrooms | bedroom_qt | Número de quartos |
| beds | beds_qt | Número de camas |
| instant_bookable | inst_book | Reserva instantânea |
| is_business_travel_ready | buss_ready | Adequado para viagens a trabalho |
| cancellation_policy | cancel_pol | Política de cancelamento |
| n_amenities | amen_qt | Quantidade de amenidades |

---

# DIM_LOCATIONS

| Atributo | Mnemônico | Descrição |
|----------|-----------|-----------|
| srk_location_id | srk_loc | Surrogate key da localização |
| latitude | lat | Latitude |
| longitude | lon | Longitude |

---

# DIM_REVIEWS

| Atributo | Mnemônico | Descrição |
|----------|-----------|-----------|
| srk_review_id | srk_rev | Surrogate key da review |
| srk_host_id | fk_host | FK para host |
| srk_property_id | fk_prop | FK para property |
| number_of_reviews | rev_qt | Quantidade de reviews |
| review_scores_rating | rt_gen | Nota geral |
| review_scores_accuracy | rt_acc | Precisão |
| review_scores_cleanliness | rt_cln | Limpeza |
| review_scores_checkin | rt_chn | Check-in |
| review_scores_communication | rt_com | Comunicação |
| review_scores_location | rt_loc | Localização |
| review_scores_value | rt_val | Custo-benefício |

---

# FACT_OCORRENCIAS

| Atributo | Mnemônico | Descrição |
|----------|-----------|-----------|
| srk_fact_id | srk_fact | Surrogate key da fato |
| srk_host_id | fk_host | FK → dim_hosts |
| srk_property_id | fk_prop | FK → dim_properties |
| srk_location_id | fk_loc | FK → dim_locations |
| srk_review_id | fk_rev | FK → dim_reviews |
| price | vlr_price | Preço da diária |
| security_deposit | vlr_dep | Depósito de segurança |
| cleaning_fee | vlr_fee_cln | Taxa de limpeza |
| guests_included | inc_qt | Hóspedes incluídos |
| minimum_nights | min_ngt | Noites mínimas |
| ano | ano | Ano |
| mes | mes | Mês |
