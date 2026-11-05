-- AgroVision SQL Analytics - Dados de exemplo
SELECT setseed(0.42);

INSERT INTO produtores (nome, cpf_cnpj, email, telefone) VALUES
 ('João Pereira',        '123.456.789-00',     'joao@agro.com',     '(47) 99999-0001'),
 ('Maria Souza',         '987.654.321-00',     'maria@agro.com',    '(54) 99999-0002'),
 ('Agro Sul Ltda',       '12.345.678/0001-90', 'contato@agrosul.com','(44) 99999-0003'),
 ('Fazendas Cerrado SA', '98.765.432/0001-10', 'ti@cerrado.com',    '(62) 99999-0004');

INSERT INTO fazendas (produtor_id, nome, cidade, estado, regiao, area_ha) VALUES
 (1, 'Fazenda Boa Vista',     'Jaraguá do Sul', 'SC', 'Sul',          320.50),
 (1, 'Fazenda Santa Clara',   'Guaramirim',     'SC', 'Sul',          210.00),
 (2, 'Fazenda Vale Verde',    'Passo Fundo',    'RS', 'Sul',          540.75),
 (3, 'Fazenda Terra Seca',    'Barreiras',      'BA', 'Nordeste',     880.00),
 (3, 'Fazenda Horizonte',     'Londrina',       'PR', 'Sul',          450.20),
 (4, 'Fazenda Sol Nascente',  'Sorriso',        'MT', 'Centro-Oeste', 1200.00),
 (4, 'Fazenda Três Lagoas',   'Rio Verde',      'GO', 'Centro-Oeste', 760.30),
 (2, 'Fazenda Areia Branca',  'Petrolina',      'PE', 'Nordeste',     390.00);

INSERT INTO talhoes (fazenda_id, nome, cultura, area_ha)
SELECT f.id, 'Talhão ' || g, (ARRAY['Soja','Milho','Trigo','Café','Feijão'])[1 + (f.id + g) % 5],
       ROUND((f.area_ha / 3)::numeric, 2)
FROM fazendas f CROSS JOIN generate_series(1,3) g;

-- 1 sensor por talhão (alguns inativos / em manutenção)
INSERT INTO sensores (talhao_id, codigo, status, instalado_em)
SELECT t.id, 'SNS-' || LPAD(t.id::text, 4, '0'),
       CASE WHEN t.id IN (5, 14, 20) THEN 'inativo'
            WHEN t.id IN (9, 23)     THEN 'manutencao'
            ELSE 'ativo' END,
       CURRENT_DATE - (t.id * 10)
FROM talhoes t;

-- 7 dias de leituras horárias para sensores ativos
INSERT INTO leituras (sensor_id, talhao_id, fazenda_id, umidade, temperatura, lida_em)
SELECT s.id, t.id, t.fazenda_id,
       GREATEST(1, LEAST(99, ROUND(((ARRAY[45,38,52,18,30,22,48,16])[t.fazenda_id] + (random()*10 - 5))::numeric, 2))),
       ROUND(((ARRAY[24,26,22,34,28,33,25,36])[t.fazenda_id] + (random()*4 - 2))::numeric, 2),
       h
FROM sensores s
JOIN talhoes t ON t.id = s.talhao_id
CROSS JOIN generate_series(date_trunc('hour', NOW()) - INTERVAL '7 days', date_trunc('hour', NOW()), INTERVAL '1 hour') h
WHERE s.status = 'ativo';

-- Alertas ativos gerados a partir das médias das últimas 24h
INSERT INTO alertas (fazenda_id, talhao_id, sensor_id, tipo, nivel, mensagem)
SELECT fazenda_id, talhao_id, sensor_id, 'baixa_umidade',
       CASE WHEN AVG(umidade) < 20 THEN 'critico' ELSE 'medio' END,
       'Umidade média de ' || ROUND(AVG(umidade),1) || '% nas últimas 24h'
FROM leituras WHERE lida_em >= NOW() - INTERVAL '24 hours'
GROUP BY fazenda_id, talhao_id, sensor_id HAVING AVG(umidade) < 25;

INSERT INTO alertas (fazenda_id, talhao_id, sensor_id, tipo, nivel, mensagem)
SELECT fazenda_id, talhao_id, sensor_id, 'alta_temperatura',
       CASE WHEN AVG(temperatura) > 35 THEN 'critico' ELSE 'medio' END,
       'Temperatura média de ' || ROUND(AVG(temperatura),1) || '°C nas últimas 24h'
FROM leituras WHERE lida_em >= NOW() - INTERVAL '24 hours'
GROUP BY fazenda_id, talhao_id, sensor_id HAVING AVG(temperatura) > 32;

-- Alertas históricos já resolvidos
INSERT INTO alertas (fazenda_id, talhao_id, tipo, nivel, status, mensagem, criado_em, resolvido_em) VALUES
 (1, 1, 'baixa_umidade',   'baixo',   'resolvido', 'Umidade abaixo do ideal', NOW() - INTERVAL '5 days', NOW() - INTERVAL '4 days'),
 (3, 7, 'sensor_offline',  'medio',   'resolvido', 'Sensor sem comunicação',  NOW() - INTERVAL '6 days', NOW() - INTERVAL '5 days'),
 (5, 13,'alta_temperatura','baixo',   'resolvido', 'Pico de temperatura',     NOW() - INTERVAL '3 days', NOW() - INTERVAL '2 days');

-- Alertas de sensores fora de operação
INSERT INTO alertas (fazenda_id, talhao_id, sensor_id, tipo, nivel, mensagem)
SELECT t.fazenda_id, t.id, s.id, 'sensor_offline', 'medio', 'Sensor ' || s.codigo || ' sem enviar leituras'
FROM sensores s JOIN talhoes t ON t.id = s.talhao_id WHERE s.status = 'inativo';
