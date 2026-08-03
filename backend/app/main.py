from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

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


@app.get("/")
def root():
    return {"status": "ok", "servicio": "Quiz Adventure API"}
