from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from . import models
from .database import engine
from .routes import preguntas

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Quiz Adventure API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(preguntas.router)

STATIC_DIR = Path(__file__).parent / "static"
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")


@app.get("/")
def root():
    return {"status": "ok", "servicio": "Quiz Adventure API"}


@app.get("/admin")
def admin_panel():
    return FileResponse(STATIC_DIR / "admin.html")
