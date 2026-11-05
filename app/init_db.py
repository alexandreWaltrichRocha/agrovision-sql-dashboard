"""Cria o schema e popula o banco:  python -m app.init_db"""
import pathlib
import psycopg2
from app.database import DATABASE_URL

SQL_DIR = pathlib.Path(__file__).resolve().parent.parent / "sql"

if __name__ == "__main__":
    conn = psycopg2.connect(DATABASE_URL)
    with conn, conn.cursor() as cur:
        for nome in ("schema.sql", "inserts.sql"):
            cur.execute((SQL_DIR / nome).read_text(encoding="utf-8"))
            print(f"✔ {nome} executado")
    conn.close()
    print("Banco pronto!")
