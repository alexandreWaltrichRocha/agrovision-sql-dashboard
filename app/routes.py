from typing import Optional
from fastapi import APIRouter, HTTPException, Query
from app.database import query, execute
from app.models import LeituraCreate

router = APIRouter(prefix="/api")

UMIDADE_CRITICA = 25   # %
TEMP_CRITICA = 32      # °C


@router.get("/resumo")
def resumo():
    return query("""
        SELECT
          (SELECT COUNT(*) FROM fazendas)                                  AS total_fazendas,
          (SELECT COUNT(*) FROM sensores)                                  AS total_sensores,
          (SELECT COUNT(*) FROM sensores WHERE status = 'ativo')           AS sensores_ativos,
          (SELECT COUNT(*) FROM alertas WHERE status = 'ativo')            AS alertas_ativos,
          (SELECT COUNT(*) FROM alertas WHERE status='ativo' AND nivel='critico') AS alertas_criticos,
          (SELECT ROUND(AVG(umidade),2)     FROM leituras WHERE lida_em >= NOW() - INTERVAL '24 hours') AS umidade_media,
          (SELECT ROUND(AVG(temperatura),2) FROM leituras WHERE lida_em >= NOW() - INTERVAL '24 hours') AS temperatura_media,
          (SELECT COUNT(*) FROM (
              SELECT talhao_id FROM leituras WHERE lida_em >= NOW() - INTERVAL '24 hours'
              GROUP BY talhao_id HAVING AVG(umidade) < %s OR AVG(temperatura) > %s) x) AS talhoes_criticos
    """, (UMIDADE_CRITICA, TEMP_CRITICA))[0]


@router.get("/umidade-por-fazenda")
def umidade_por_fazenda():
    return query("""
        SELECT f.nome, ROUND(AVG(l.umidade),2) AS media_umidade
        FROM leituras l JOIN fazendas f ON f.id = l.fazenda_id
        GROUP BY f.nome ORDER BY f.nome""")


@router.get("/temperatura-por-fazenda")
def temperatura_por_fazenda():
    return query("""
        SELECT f.nome, ROUND(AVG(l.temperatura),2) AS media_temperatura
        FROM leituras l JOIN fazendas f ON f.id = l.fazenda_id
        GROUP BY f.nome ORDER BY f.nome""")


@router.get("/alertas-por-regiao")
def alertas_por_regiao():
    return query("""
        SELECT f.regiao, COUNT(*) AS total
        FROM alertas a JOIN fazendas f ON f.id = a.fazenda_id
        WHERE a.status = 'ativo' GROUP BY f.regiao ORDER BY total DESC""")


@router.get("/top-fazendas-alertas")
def top_fazendas_alertas():
    return query("""
        SELECT f.nome, COUNT(a.id) AS total_alertas
        FROM fazendas f JOIN alertas a ON f.id = a.fazenda_id
        GROUP BY f.nome ORDER BY total_alertas DESC LIMIT 10""")


@router.get("/talhoes-criticos")
def talhoes_criticos():
    return query("""
        SELECT f.nome AS fazenda, t.nome AS talhao, t.cultura,
               ROUND(AVG(l.umidade),2) AS umidade, ROUND(AVG(l.temperatura),2) AS temperatura
        FROM leituras l
        JOIN talhoes t  ON t.id = l.talhao_id
        JOIN fazendas f ON f.id = l.fazenda_id
        WHERE l.lida_em >= NOW() - INTERVAL '24 hours'
        GROUP BY f.nome, t.nome, t.cultura
        HAVING AVG(l.umidade) < %s OR AVG(l.temperatura) > %s
        ORDER BY umidade""", (UMIDADE_CRITICA, TEMP_CRITICA))


@router.get("/alertas")
def listar_alertas(status: Optional[str] = "ativo", nivel: Optional[str] = None,
                   limit: int = Query(50, le=500)):
    return query("""
        SELECT a.id, f.nome AS fazenda, t.nome AS talhao, a.tipo, a.nivel, a.status,
               a.mensagem, a.criado_em
        FROM alertas a
        JOIN fazendas f ON f.id = a.fazenda_id
        LEFT JOIN talhoes t ON t.id = a.talhao_id
        WHERE (%(status)s::text IS NULL OR a.status = %(status)s)
          AND (%(nivel)s::text  IS NULL OR a.nivel  = %(nivel)s)
        ORDER BY CASE a.nivel WHEN 'critico' THEN 1 WHEN 'medio' THEN 2 ELSE 3 END, a.criado_em DESC
        LIMIT %(limit)s""", {"status": status, "nivel": nivel, "limit": limit})


@router.patch("/alertas/{alerta_id}/resolver")
def resolver_alerta(alerta_id: int):
    r = execute("""UPDATE alertas SET status='resolvido', resolvido_em=NOW()
                   WHERE id=%s AND status='ativo' RETURNING id, status""", (alerta_id,))
    if not r:
        raise HTTPException(404, "Alerta não encontrado ou já resolvido")
    return r[0]


@router.get("/sensores")
def listar_sensores(status: Optional[str] = None):
    return query("""
        SELECT s.id, s.codigo, s.status, s.tipo, t.nome AS talhao, f.nome AS fazenda,
               (SELECT MAX(lida_em) FROM leituras l WHERE l.sensor_id = s.id) AS ultima_leitura
        FROM sensores s JOIN talhoes t ON t.id = s.talhao_id JOIN fazendas f ON f.id = t.fazenda_id
        WHERE (%(s)s::text IS NULL OR s.status = %(s)s) ORDER BY s.id""", {"s": status})


@router.get("/sensores/{sensor_id}/historico")
def historico_sensor(sensor_id: int, horas: int = Query(48, ge=1, le=168)):
    if not query("SELECT 1 FROM sensores WHERE id=%s", (sensor_id,)):
        raise HTTPException(404, "Sensor não encontrado")
    return query("""
        SELECT lida_em, umidade, temperatura FROM leituras
        WHERE sensor_id = %s AND lida_em >= NOW() - make_interval(hours => %s)
        ORDER BY lida_em""", (sensor_id, horas))


@router.post("/leituras", status_code=201)
def registrar_leitura(l: LeituraCreate):
    r = execute("""
        INSERT INTO leituras (sensor_id, talhao_id, fazenda_id, umidade, temperatura)
        SELECT s.id, t.id, t.fazenda_id, %s, %s
        FROM sensores s JOIN talhoes t ON t.id = s.talhao_id
        WHERE s.id = %s AND s.status = 'ativo' RETURNING id""",
        (l.umidade, l.temperatura, l.sensor_id))
    if not r:
        raise HTTPException(404, "Sensor inexistente ou não está ativo")
    return {"id": r[0]["id"], "mensagem": "Leitura registrada"}
