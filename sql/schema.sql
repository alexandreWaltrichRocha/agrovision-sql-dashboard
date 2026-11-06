-- AgroVision SQL Analytics - Schema (PostgreSQL)
DROP TABLE IF EXISTS alertas, leituras, sensores, talhoes, fazendas, produtores CASCADE;

CREATE TABLE produtores (
    id        SERIAL PRIMARY KEY,
    nome      VARCHAR(120) NOT NULL,
    cpf_cnpj  VARCHAR(18)  NOT NULL UNIQUE,
    email     VARCHAR(120),
    telefone  VARCHAR(20),
    criado_em TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE fazendas (
    id          SERIAL PRIMARY KEY,
    produtor_id INT NOT NULL REFERENCES produtores(id) ON DELETE CASCADE,
    nome        VARCHAR(120) NOT NULL,
    cidade      VARCHAR(80)  NOT NULL,
    estado      CHAR(2)      NOT NULL,
    regiao      VARCHAR(20)  NOT NULL,
    area_ha     NUMERIC(10,2) NOT NULL CHECK (area_ha > 0)
);

CREATE TABLE talhoes (
    id         SERIAL PRIMARY KEY,
    fazenda_id INT NOT NULL REFERENCES fazendas(id) ON DELETE CASCADE,
    nome       VARCHAR(60) NOT NULL,
    cultura    VARCHAR(60) NOT NULL,
    area_ha    NUMERIC(10,2) NOT NULL CHECK (area_ha > 0)
);

CREATE TABLE sensores (
    id          SERIAL PRIMARY KEY,
    talhao_id   INT NOT NULL REFERENCES talhoes(id) ON DELETE CASCADE,
    codigo      VARCHAR(30) NOT NULL UNIQUE,
    tipo        VARCHAR(40) NOT NULL DEFAULT 'umidade_temperatura',
    status      VARCHAR(15) NOT NULL DEFAULT 'ativo'
                CHECK (status IN ('ativo','inativo','manutencao')),
    instalado_em DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE leituras (
    id          BIGSERIAL PRIMARY KEY,
    sensor_id   INT NOT NULL REFERENCES sensores(id) ON DELETE CASCADE,
    talhao_id   INT NOT NULL REFERENCES talhoes(id)  ON DELETE CASCADE,
    fazenda_id  INT NOT NULL REFERENCES fazendas(id) ON DELETE CASCADE,
    umidade     NUMERIC(5,2) NOT NULL CHECK (umidade BETWEEN 0 AND 100),
    temperatura NUMERIC(5,2) NOT NULL CHECK (temperatura BETWEEN -20 AND 70),
    lida_em     TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE alertas (
    id         SERIAL PRIMARY KEY,
    fazenda_id INT NOT NULL REFERENCES fazendas(id) ON DELETE CASCADE,
    talhao_id  INT REFERENCES talhoes(id)  ON DELETE SET NULL,
    sensor_id  INT REFERENCES sensores(id) ON DELETE SET NULL,
    tipo       VARCHAR(40) NOT NULL,
    nivel      VARCHAR(10) NOT NULL CHECK (nivel IN ('baixo','medio','critico')),
    status     VARCHAR(10) NOT NULL DEFAULT 'ativo' CHECK (status IN ('ativo','resolvido')),
    mensagem   TEXT NOT NULL,
    criado_em  TIMESTAMP NOT NULL DEFAULT NOW(),
    resolvido_em TIMESTAMP
);

CREATE INDEX idx_leituras_sensor_data  ON leituras (sensor_id, lida_em DESC);
CREATE INDEX idx_leituras_fazenda_data ON leituras (fazenda_id, lida_em DESC);
CREATE INDEX idx_leituras_talhao_data  ON leituras (talhao_id, lida_em DESC);
CREATE INDEX idx_leituras_lida_em      ON leituras (lida_em);
CREATE INDEX idx_alertas_status_nivel  ON alertas (status, nivel);
CREATE INDEX idx_alertas_fazenda       ON alertas (fazenda_id);
