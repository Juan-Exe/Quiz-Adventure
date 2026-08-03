from sqlalchemy import Column, DateTime, Integer, String, Text, func

from .database import Base


class Pregunta(Base):
    __tablename__ = "preguntas"

    id = Column(Integer, primary_key=True, index=True)
    tema = Column(String(100), nullable=False, index=True)
    enunciado = Column(Text, nullable=False)
    respuesta_a = Column("respuestaA", String(255), nullable=False)
    respuesta_b = Column("respuestaB", String(255), nullable=False)
    respuesta_c = Column("respuestaC", String(255), nullable=False)
    respuesta_d = Column("respuestaD", String(255), nullable=False)
    correcta = Column(String(1), nullable=False)
    dificultad = Column(String(20), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
