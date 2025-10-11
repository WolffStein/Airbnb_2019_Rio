# Modelo Entidade-Relacionamento (ME-R)

## ENTIDADES:

* HOST
* LISTING
* AMENITY
* LISTING_AMENITY
* DATE
* LISTING_MONTHLY

---

## ATRIBUTOS:

**HOST** (`idHost`, `responseTime`, `responseRate`, `isSuperhost`, `listingsCount`)

**LISTING** (`idListing`, `idHost`, `propertyType`, `roomType`, `bedType`, `accommodates`, `bathrooms`, `bedrooms`, `beds`, `latitude`, `longitude`, `nAmenities`)

**AMENITY** (`idAmenity`, `amenityName`)

**LISTING_AMENITY** (`idListing`, `idAmenity`)

**DATE** (`idDate`, `year`, `month`)

**LISTING_MONTHLY** (`idListing`, `idDate`, `price`, `securityDeposit`, `cleaningFee`, `extraPeople`, `guestsIncluded`, `numberOfReviews`, `reviewScoresRating`, `reviewScoresAccuracy`, `reviewScoresCleanliness`, `reviewScoresCheckin`, `reviewScoresCommunication`, `reviewScoresLocation`, `reviewScoresValue`, `instantBookable`, `isBusinessTravelReady`, `cancellationPolicy`, `nAmenities`)

---

## RELACIONAMENTOS:

**LISTING** – *pertence a* – **HOST**
Um LISTING pertence a um HOST, e um HOST pode possuir nenhum ou vários LISTINGS.
**Cardinalidade:** n:1

**LISTING_MONTHLY** – *atualiza-se em* – **DATE**
Cada LISTING_MONTHLY refere-se a uma única DATE, e uma DATE pode conter vários LISTING_MONTHLY.
**Cardinalidade:** n:1

**LISTING** – *possui* – **LISTING_MONTHLY**
Um LISTING pode ter vários registros em LISTING_MONTHLY, mas cada LISTING_MONTHLY está vinculado a apenas um LISTING.
**Cardinalidade:** 1:n

**LISTING** – *possui* – **AMENITY**
Um LISTING pode possuir várias AMENITY, e uma AMENITY pode estar presente em vários LISTINGS.
**Entidade associativa:** LISTING_AMENITY (`idListing`, `idAmenity`)
**Cardinalidade:** n:m

**DATE** – *associa-se a* – **LISTING_MONTHLY**
Cada DATE representa um período (mês/ano) que agrupa vários registros de LISTING_MONTHLY.
**Cardinalidade:** 1:n

**Resumo das Cardinalidades:**

| Relacionamento            | Cardinalidade | 
| ------------------------- | ---- | 
| HOST – LISTING            | 1:N  |               
| LISTING – LISTING_MONTHLY | 1:N  |               
| DATE – LISTING_MONTHLY    | 1:N  |               
| LISTING – AMENITY         | N:M  |               
