# 🏡 Airbnb_2019_Rio

Repositório voltado para **análise de dados** e **desenvolvimento de um banco de dados** baseado nas informações do **Airbnb do Rio de Janeiro em 2019**.  
O projeto utiliza **Jupyter Notebook** para exploração, tratamento e visualização dos dados.

---

## 🚀 Instruções de uso

### 1️⃣ Clonar o repositório
```bash
git clone https://github.com/WolffStein/Airbnb_2019_Rio.git
```

### 2️⃣ Acessar a pasta do projeto
```bash
cd Airbnb_2019_Rio
```

### 3️⃣ Instalar as dependências
Execute o notebook **`install.ipynb`** para instalar automaticamente todas as bibliotecas listadas no `requirements.txt`.

Ou, se preferir, instale manualmente:
```bash
pip install -r requirements.txt
```

### 4️⃣ Executar o projeto
Abra e rode o notebook principal:
```bash
AirBnB.ipynb
```


### 5️⃣ Levantar containers e popular bancos de dados
O comando abaixo constrói as imagens e inicia os containers:

```bash
docker compose up --build
```

Serão inicializados:

- 🐘 lakehouse_db → Banco PostgreSQL

- ⚙️ airbnb_etl → Script Python (populate_db.py) responsável por popular as tabelas

- 🌐 pgAdmin → Interface web para consulta e gerenciamento do banco

Acesse o pgAdmin em:
👉 http://localhost:5050
- __Login:__ admin@admin.com
- __Senha:__ admin

---

## 🧰 Tecnologias utilizadas
- **Python 3**
- **Jupyter Notebook**
- **Pandas**
- **NumPy**
- **Matplotlib / Seaborn / Plotly**
- **KaggleHub**

---

## 📊 Objetivo
Este projeto visa:
- Explorar e limpar os dados do Airbnb no Rio de Janeiro.
- Desenvolver um pequeno **banco de dados analítico**.
- Gerar **visualizações e insights** relevantes sobre o mercado local.

---

## 📁 Estrutura do repositório
```
Airbnb_2019_Rio/
├── etl/
│   ├── Dockerfile            # Imagem do container ETL
│   ├── populate_db.py        # Script de carga de dados
├── base_de_dados_prata.csv   # Camada prata (dados tratados)
├── docker-compose.yml        # Orquestração dos serviços
├── AirBnB.ipynb              # Notebook de exploração e limpeza
├── requirements.txt          # Dependências
└── data/                     # Volumes do PostgreSQL e pgAdmin

```

---

## ✨ Autores
**Edilberto Almeida Cantuária**  
[LinkedIn](https://www.linkedin.com/in/edilberto-cantuaria) • [GitHub](https://github.com/edilbertocantuaria)


**Wolfgang Friedrich Stein**
[LinkedIn](https://www.linkedin.com/in/wolfgang-friedrich-stein-5531571b5/) • [GitHub](https://github.com/WolffStein/Airbnb_2019_Rio)
