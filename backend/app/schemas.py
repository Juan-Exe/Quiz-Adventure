from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict

Dificultad = Literal["facil", "intermedio", "dificil", "master"]
Opcion = Literal["a", "b", "c", "d"]


class PreguntaBase(BaseModel):
    tema: str
    enunciado: str
    respuesta_a: str
    respuesta_b: str
    respuesta_c: str
    respuesta_d: str
    correcta: Opcion
    dificultad: Dificultad


class PreguntaCreate(PreguntaBase):
    pass


class PreguntaUpdate(PreguntaBase):
    pass


class Pregunta(PreguntaBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    created_at: datetime


class PreguntaParaJugar(BaseModel):
    """Vista de la pregunta sin revelar la respuesta correcta."""

    id: int
    tema: str
    dificultad: Dificultad
    enunciado: str
    respuestas: dict[Opcion, str]
