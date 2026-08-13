import random

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session

from .. import models, schemas
from ..database import get_db

router = APIRouter(prefix="/preguntas", tags=["preguntas"])


@router.get("", response_model=list[schemas.Pregunta])
def listar_preguntas(db: Session = Depends(get_db)):
    return db.query(models.Pregunta).all()


@router.post("", response_model=schemas.Pregunta, status_code=201)
def registrar_pregunta(pregunta: schemas.PreguntaCreate, db: Session = Depends(get_db)):
    nueva = models.Pregunta(**pregunta.model_dump())
    db.add(nueva)
    db.commit()
    db.refresh(nueva)
    return nueva


@router.get("/{pregunta_id}", response_model=schemas.Pregunta)
def obtener_pregunta(pregunta_id: int, db: Session = Depends(get_db)):
    pregunta = db.get(models.Pregunta, pregunta_id)
    if not pregunta:
        raise HTTPException(status_code=404, detail="Pregunta no encontrada")
    return pregunta


@router.put("/{pregunta_id}", response_model=schemas.Pregunta)
def editar_pregunta(
    pregunta_id: int, cambios: schemas.PreguntaUpdate, db: Session = Depends(get_db)
):
    pregunta = db.get(models.Pregunta, pregunta_id)
    if not pregunta:
        raise HTTPException(status_code=404, detail="Pregunta no encontrada")

    for campo, valor in cambios.model_dump().items():
        setattr(pregunta, campo, valor)

    db.commit()
    db.refresh(pregunta)
    return pregunta


@router.delete("/{pregunta_id}", status_code=204)
def eliminar_pregunta(pregunta_id: int, db: Session = Depends(get_db)):
    pregunta = db.get(models.Pregunta, pregunta_id)
    if not pregunta:
        raise HTTPException(status_code=404, detail="Pregunta no encontrada")

    db.delete(pregunta)
    db.commit()


@router.get("/aleatoria/{dificultad}/{tema}", response_model=schemas.PreguntaParaJugar)
def pregunta_aleatoria(
    dificultad: schemas.Dificultad,
    tema: str,
    ya_usadas: str = "",
    db: Session = Depends(get_db),
):
    """Devuelve una pregunta al azar de un tema+dificultad sin revelar la correcta.

    `ya_usadas` es una lista de ids separados por coma (ej. "1,4,9") para no repetir.
    """
    excluir_ids = [int(i) for i in ya_usadas.split(",") if i.strip().isdigit()]

    query = db.query(models.Pregunta).filter(
        models.Pregunta.tema == tema,
        models.Pregunta.dificultad == dificultad,
    )
    if excluir_ids:
        query = query.filter(models.Pregunta.id.notin_(excluir_ids))

    candidatas = query.all()
    if not candidatas:
        raise HTTPException(
            status_code=404, detail="No hay preguntas disponibles para ese tema/dificultad"
        )

    pregunta = random.choice(candidatas)
    return schemas.PreguntaParaJugar(
        id=pregunta.id,
        tema=pregunta.tema,
        dificultad=pregunta.dificultad,
        enunciado=pregunta.enunciado,
        respuestas={
            "a": pregunta.respuesta_a,
            "b": pregunta.respuesta_b,
            "c": pregunta.respuesta_c,
            "d": pregunta.respuesta_d,
        },
    )


@router.post("/{pregunta_id}/responder", response_model=schemas.ResultadoIntento)
def responder_pregunta(
    pregunta_id: int, intento: schemas.RespuestaIntento, db: Session = Depends(get_db)
):
    pregunta = db.get(models.Pregunta, pregunta_id)
    if not pregunta:
        raise HTTPException(status_code=404, detail="Pregunta no encontrada")

    return schemas.ResultadoIntento(
        correcta=intento.opcion == pregunta.correcta,
        opcion_correcta=pregunta.correcta,
    )


@router.get("/temas/{dificultad}")
def temas_por_dificultad(dificultad: schemas.Dificultad, db: Session = Depends(get_db)):
    temas = (
        db.query(models.Pregunta.tema)
        .filter(models.Pregunta.dificultad == dificultad)
        .distinct()
        .all()
    )
    return [t[0] for t in temas]


@router.get("/conteo/por-dificultad")
def conteo_por_dificultad(db: Session = Depends(get_db)):
    filas = (
        db.query(models.Pregunta.dificultad, func.count(models.Pregunta.id))
        .group_by(models.Pregunta.dificultad)
        .all()
    )
    conteo = {"facil": 0, "intermedio": 0, "dificil": 0, "master": 0}
    for dificultad, cantidad in filas:
        conteo[dificultad] = cantidad
    return conteo
