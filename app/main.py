import pathlib
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from app.routes import router

app = FastAPI(title="AgroVision SQL Analytics", version="1.0.0",
              description="API de monitoramento de propriedades rurais")
app.include_router(router)


@app.get("/health")
def health():
    return {"status": "ok"}


DASH = pathlib.Path(__file__).resolve().parent.parent / "dashboard"
app.mount("/", StaticFiles(directory=DASH, html=True), name="dashboard")
