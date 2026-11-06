#🌱 AgroVision SQL Analytics

Sistema de monitoramento de propriedades rurais utilizando PostgreSQL, SQL avançado, FastAPI e Dashboard interativo com Chart.js.
![Dashboard AgroVision](<docs/dashboard.png>)
📋 Sobre o Projeto

O AgroVision SQL Analytics foi desenvolvido para simular um ambiente real de monitoramento agrícola através da coleta, armazenamento e análise de dados provenientes de sensores instalados em propriedades rurais.

A aplicação permite monitorar indicadores agrícolas, visualizar métricas em dashboards interativos, gerar alertas automáticos e analisar informações através de consultas SQL avançadas.

🎯 Competências Demonstradas

✅ SQL Avançado

✅ PostgreSQL

✅ Modelagem de Banco de Dados

✅ FastAPI (API REST)

✅ Integração Frontend e Backend

✅ Chart.js

✅ Dashboards Interativos

✅ Análise de Dados

✅ Git e GitHub

✅ Docker

📊 Dashboard
Indicadores
Total de Fazendas
Total de Sensores
Alertas Ativos
Umidade Média
Temperatura Média
Talhões Críticos
Gráficos
📈 Umidade Média por Fazenda
📊 Temperatura Média por Fazenda
🚨 Alertas por Região
🕒 Histórico de Sensores
Recursos
Atualização automática a cada 30 segundos
API REST integrada
Dados em tempo real
Interface responsiva
🗄️ Modelo de Dados

Relacionamentos principais:

Plain Text
Produtores
↓
Fazendas
↓
Talhões
↓
Sensores
↓
Leituras
 
Alertas

Documentação do modelo:

Plain Text
docs/modelo-er.md
⚙️ Requisitos
Ambiente Validado

O projeto foi desenvolvido e testado utilizando:

Plain Text
Python 3.13.5
FastAPI 0.115.0
Uvicorn 0.30.6
PostgreSQL
psycopg2-binary 2.9.10
Requisitos Mínimos
Plain Text
Python 3.13+
PostgreSQL
Git
Pip
🚀 Instalação
1. Clonar o Repositório
Shell
git clone https://github.com/alexandreWaltrichRocha/agrovision-sql-dashboard.git
 
cd agrovision-sql-dashboard
2. Criar Ambiente Virtual
Shell
python -m venv venv
Windows
Shell
venv\Scripts\activate
Linux / Mac
Shell
source venv/bin/activate
3. Instalar Dependências
Shell
pip install -r requirements.txt
4. Configuração

Criar arquivo .env:

Shell
env não tem suporte total. O realce de sintaxe é baseado em Shell.
DATABASE_URL=postgresql://usuario:senha@localhost:5432/agrovision

Ou copie:

Shell
cp .env.example .env

e ajuste conforme necessário.

🐘 Banco de Dados
Utilizando Docker
Shell
docker compose up -d
Utilizando PostgreSQL Local
SQL
CREATE DATABASE agrovision;
 
Criar Estruturas
Shell
python -m app.init_db
 

ou

Shell
psql -d agrovision -f sql/schema.sql -f sql/inserts.sql
▶️ Executar Aplicação
Shell
python -m uvicorn app.main:app --reload
🌐 Acessos
Dashboard
Plain Text
http://localhost:8000
Swagger
Plain Text
http://localhost:8000/docs
OpenAPI
Plain Text
http://localhost:8000/openapi.json
🔗 Endpoints Disponíveis
Resumo
HTTP
GET /api/resumo
Umidade por Fazenda
HTTP
GET /api/umidade-por-fazenda
Temperatura por Fazenda
HTTP
GET /api/temperatura-por-fazenda
Alertas por Região
HTTP
GET /api/alertas-por-regiao
Top Fazendas com Alertas
HTTP
GET /api/top-fazendas-alertas
Talhões Críticos
HTTP
GET /api/talhoes-criticos
Listagem de Alertas
HTTP
GET /api/alertas
Resolver Alerta
HTTP
PATCH /api/alertas/{id}/resolver
Sensores
HTTP
GET /api/sensores
 
Histórico de Sensores
HTTP
GET /api/sensores/{id}/historico
Nova Leitura
HTTP
POST /api/leituras
📈 Consultas SQL

O projeto utiliza recursos avançados do PostgreSQL:

JOINs
GROUP BY
HAVING
ORDER BY
CTE (Common Table Expressions)
Window Functions
RANK()
Funções Analíticas
Agregações Estatísticas
Exemplo
SQL
SELECT f.nome,
COUNT(a.id) AS total_alertas
FROM fazendas f
JOIN alertas a
ON f.id = a.fazenda_id
GROUP BY f.nome
ORDER BY total_alertas DESC
LIMIT 10;
 
📁 Estrutura do Projeto
Plain Text
agrovision-sql-dashboard/
│
├── app/
│ ├── main.py
│ ├── database.py
│ ├── models.py
│ ├── routes.py
│ └── init_db.py
│
├── dashboard/
│ ├── index.html
│ ├── css/
│ └── js/
│
├── sql/
│ ├── schema.sql
│ ├── inserts.sql
│ └── consultas.sql
│
├── docs/
│ └── modelo-er.md
│
├── docker-compose.yml
├── requirements.txt
├── .env.example
└── README.md
🛠️ Tecnologias
Python
FastAPI
PostgreSQL
SQL
psycopg2
HTML5
CSS3
JavaScript
Chart.js
Docker
Git
GitHub


Diferenciais Técnicos

Arquitetura API REST com FastAPI
Persistência em PostgreSQL
Dashboard em JavaScript e Chart.js
Consultas SQL avançadas com Window Functions
Estrutura pronta para escalabilidade
Integração Frontend + Backend
Ambiente isolado com Virtual Environment
Configuração via Docker


🎓 Objetivo Acadêmico e Profissional

Este projeto foi desenvolvido para demonstrar conhecimentos práticos em:

Desenvolvimento Backend
APIs REST
Modelagem de Banco de Dados
SQL Avançado
Visualização de Dados
Integração Full Stack
Análise de Dados Agrícolas
Boas Práticas de Desenvolvimento
👨‍💻 Autor

Alexandre Waltrich Rocha

GitHub:

Plain Text
https://github.com/alexandreWaltrichRocha
📄 Licença

Projeto desenvolvido para fins educacionais, acadêmicos e demonstração de portfólio.