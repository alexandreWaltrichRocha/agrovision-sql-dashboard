-- AgroVision SQL Analytics - Consultas analíticas

-- 1. Top 10 fazendas com mais alertas
SELECT f.nome, COUNT(a.id) AS total_alertas
FROM fazendas f JOIN alertas a ON f.id = a.fazenda_id
GROUP BY f.nome ORDER BY total_alertas DESC LIMIT 10;

-- 2. Média de umidade por fazenda
SELECT f.nome, ROUND(AVG(l.umidade),2) AS media_umidade
FROM leituras l JOIN fazendas f ON f.id = l.fazenda_id
GROUP BY f.nome ORDER BY media_umidade;

-- 3. Sensores ativos
SELECT * FROM sensores WHERE status = 'ativo';

-- 4. Alertas críticos ativos
SELECT * FROM alertas WHERE nivel = 'critico' AND status = 'ativo';

-- 5. Talhões críticos (últimas 24h: umidade < 25% ou temperatura > 32°C)
SELECT f.nome AS fazenda, t.nome AS talhao, t.cultura,
       ROUND(AVG(l.umidade),2) AS umidade, ROUND(AVG(l.temperatura),2) AS temperatura
FROM leituras l
JOIN talhoes t  ON t.id = l.talhao_id
JOIN fazendas f ON f.id = l.fazenda_id
WHERE l.lida_em >= NOW() - INTERVAL '24 hours'
GROUP BY f.nome, t.nome, t.cultura
HAVING AVG(l.umidade) < 25 OR AVG(l.temperatura) > 32
ORDER BY umidade;

-- 6. Alertas ativos por região
SELECT f.regiao, COUNT(*) AS alertas_ativos
FROM alertas a JOIN fazendas f ON f.id = a.fazenda_id
WHERE a.status = 'ativo' GROUP BY f.regiao ORDER BY alertas_ativos DESC;

-- 7. Window function: ranking de fazendas por umidade média dentro de cada região
SELECT regiao, nome, media_umidade,
       RANK() OVER (PARTITION BY regiao ORDER BY media_umidade DESC) AS ranking_regiao
FROM (
  SELECT f.regiao, f.nome, ROUND(AVG(l.umidade),2) AS media_umidade
  FROM fazendas f JOIN leituras l ON l.fazenda_id = f.id GROUP BY f.regiao, f.nome
) x;

-- 8. CTE + window: média móvel de 6h da umidade de um sensor
WITH base AS (
  SELECT lida_em, umidade FROM leituras WHERE sensor_id = 1
)
SELECT lida_em, umidade,
       ROUND(AVG(umidade) OVER (ORDER BY lida_em ROWS BETWEEN 5 PRECEDING AND CURRENT ROW),2) AS media_movel_6h
FROM base ORDER BY lida_em DESC LIMIT 24;

-- 9. Produtores com total de fazendas e sensores
SELECT p.nome, COUNT(DISTINCT f.id) AS fazendas, COUNT(DISTINCT s.id) AS sensores
FROM produtores p
LEFT JOIN fazendas f ON f.produtor_id = p.id
LEFT JOIN talhoes t ON t.fazenda_id = f.id
LEFT JOIN sensores s ON s.talhao_id = t.id
GROUP BY p.nome ORDER BY sensores DESC;
