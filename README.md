# 🌱 AgroVision SQL Analytics

Sistema de monitoramento de propriedades rurais: **PostgreSQL + SQL avançado + FastAPI + Dashboard (Chart.js)**.

Projeto desenvolvido para demonstrar competências em:

✔ SQL Avançado (JOINs, CTE, Window Functions, agregações)
✔ PostgreSQL
✔ Modelagem de Banco de Dados
✔ FastAPI (API REST)
✔ Dashboards com Chart.js
✔ Análise de Dados
✔ Git e GitHub

O sistema permite monitorar indicadores agrícolas (umidade, temperatura, alertas e sensores) através de consultas SQL e visualizações em dashboard.

## Dashboard

- **Cards:** Total de Fazendas · Total de Sensores · Alertas Ativos · Umidade Média · Temperatura Média · Talhões Críticos
- **Gráficos:** 📈 Umidade por fazenda · 📊 Temperatura por fazenda · 🚨 Alertas por região · 🕒 Histórico de sensores (selecionável)
- **Tabelas:** Talhões críticos e alertas ativos (com botão *Resolver*)
- Atualização automática a cada 30 s

## Modelo de dados

`produtores → fazendas → talhoes → sensores → leituras` e `alertas` (ligados a fazenda/talhão/sensor).
Diagrama ER em [`docs/modelo-er.md`](docs/modelo-er.md) (Mermaid, renderizado pelo GitHub).

## Como executar

```bash
# 1. Banco PostgreSQL (opção Docker)
docker compose up -d
# ou use um PostgreSQL local e crie o banco:  CREATE DATABASE agrovision;

# 2. Dependências
python -m venv venv && source venv/bin/activate      # Windows: venv\Scripts\activate
pip install -r requirements.txt

# 3. Configuração
cp .env.example .env        # ajuste DATABASE_URL se necessário

# 4. Criar tabelas e popular com dados de exemplo
python -m app.init_db
# (alternativa: psql -d agrovision -f sql/schema.sql -f sql/inserts.sql)

# 5. Subir API + dashboard
uvicorn app.main:app --reload
```

- Dashboard: http://localhost:8000
- Documentação da API (Swagger): http://localhost:8000/docs

## Endpoints

| Método | Rota | Descrição |
|---|---|---|
| GET | `/api/resumo` | Indicadores dos cards |
| GET | `/api/umidade-por-fazenda` | Média de umidade por fazenda |
| GET | `/api/temperatura-por-fazenda` | Média de temperatura por fazenda |
| GET | `/api/alertas-por-regiao` | Alertas ativos por região |
| GET | `/api/top-fazendas-alertas` | Top 10 fazendas com mais alertas |
| GET | `/api/talhoes-criticos` | Talhões com umidade < 25% ou temp. > 32°C (24h) |
| GET | `/api/alertas?status=&nivel=&limit=50&offset=0` | Lista paginada de alertas (`status=` vazio = todos) |
| PATCH | `/api/alertas/{id}/resolver` | Resolve um alerta |
| GET | `/api/sensores?status=` | Lista de sensores |
| GET | `/api/sensores/{id}/historico?horas=48` | Histórico de leituras |
| POST | `/api/leituras` | Registra nova leitura de um sensor ativo |

## Consultas SQL

Todas em [`sql/consultas.sql`](sql/consultas.sql): top fazendas com alertas, média de umidade, sensores ativos,
alertas críticos, talhões críticos, alertas por região, **ranking com `RANK() OVER (PARTITION BY ...)`**,
**média móvel com CTE + window function** e resumo por produtor.

```sql
SELECT f.nome, COUNT(a.id) AS total_alertas
FROM fazendas f JOIN alertas a ON f.id = a.fazenda_id
GROUP BY f.nome ORDER BY total_alertas DESC LIMIT 10;
```

## Estrutura

```
agrovision-sql-dashboard/
├── app/        main.py · database.py · models.py · routes.py · init_db.py
├── sql/        schema.sql · inserts.sql · consultas.sql
├── dashboard/  index.html · css/ · js/
├── docs/       modelo-er.md
├── docker-compose.yml · requirements.txt · .env.example
└── README.md
```

## Tecnologias

HTML · CSS · JavaScript · Chart.js · Python · FastAPI · PostgreSQL · psycopg2 · Git/GitHub
