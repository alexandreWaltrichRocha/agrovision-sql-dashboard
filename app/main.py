import pathlib
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from app.routes import router
from app.database import close_pool


@asynccontextmanager
async def lifespan(_app):
    yield
    close_pool()

app = FastAPI(title="AgroVision SQL Analytics", version="1.0.0",
              description="API de monitoramento de propriedades rurais", lifespan=lifespan)
app.include_router(router)


@app.get("/health")
def health():
    return {"status": "ok"}


DASH = pathlib.Path(__file__).resolve().parent.parent / "dashboard"
app.mount("/", StaticFiles(directory=DASH, html=True), name="dashboard")
