"""Carga preguntas base de ejemplo en la base de datos.

Ejecutar una sola vez: python seed.py
"""

from app.database import Base, SessionLocal, engine
from app.models import Pregunta

PREGUNTAS = [
    # FACIL
    ("videojuegos", "Cual es el personaje principal de Nintendo con gorra roja?", "Mario", "Sonic", "Link", "Crash", "a", "facil"),
    ("videojuegos", "En que saga aparece Master Chief?", "Halo", "Call of Duty", "Gears of War", "Battlefield", "a", "facil"),
    ("series", "Como se llama la ciudad de Los Simpson?", "Quahog", "Springfield", "Shelbyville", "South Park", "b", "facil"),
    ("series", "Cuantos amigos forman el grupo principal de Friends?", "4", "5", "6", "7", "c", "facil"),
    ("peliculas", "Quien dirigio Titanic?", "Steven Spielberg", "James Cameron", "Martin Scorsese", "Ridley Scott", "b", "facil"),
    ("peliculas", "Como se llama la saga del joven mago interpretado por Daniel Radcliffe?", "Narnia", "Percy Jackson", "Animales Fantasticos", "Harry Potter", "d", "facil"),
    ("cultura pop", "Cual es la identidad secreta de Clark Kent?", "Batman", "Iron Man", "Superman", "Flash", "c", "facil"),
    ("cultura pop", "En Star Wars, de que color es el sable de luz de Luke en Una Nueva Esperanza?", "Rojo", "Verde", "Azul", "Morado", "c", "facil"),
    ("musica", "Que banda tenia como vocalista a Freddie Mercury?", "Queen", "The Beatles", "U2", "Nirvana", "a", "facil"),
    ("musica", "Quien es conocida por la cancion Like a Virgin?", "Madonna", "Shakira", "Adele", "Cher", "a", "facil"),
    # INTERMEDIO
    ("videojuegos", "Que compania creo The Legend of Zelda?", "Sega", "Nintendo", "Capcom", "Konami", "b", "intermedio"),
    ("videojuegos", "Como se llama el protagonista de The Witcher 3?", "Geralt de Rivia", "Kratos", "Ezio Auditore", "Arthur Morgan", "a", "intermedio"),
    ("series", "Cual es el alias de Walter White en Breaking Bad?", "Saul", "Capitan Cook", "Heisenberg", "Tuco", "c", "intermedio"),
    ("series", "En que serie aparece el Trono de Hierro?", "Vikings", "The Witcher", "House of the Dragon", "Game of Thrones", "d", "intermedio"),
    ("peliculas", "Que pelicula gano el Oscar a Mejor Pelicula en 2020?", "1917", "Parasite", "Joker", "Ford v Ferrari", "b", "intermedio"),
    ("peliculas", "Que actor interpreta a Iron Man en el MCU?", "Chris Evans", "Mark Ruffalo", "Robert Downey Jr.", "Chris Hemsworth", "c", "intermedio"),
    ("cultura pop", "Cual es el nombre real de Baby Yoda en The Mandalorian?", "Yaddle", "Grogu", "Ahsoka", "Moff", "b", "intermedio"),
    ("cultura pop", "Cual es la ciudad principal de Batman?", "Metropolis", "Star City", "Gotham", "Central City", "c", "intermedio"),
    ("musica", "Cual es el album mas vendido de Michael Jackson?", "Bad", "Dangerous", "Thriller", "Off the Wall", "c", "intermedio"),
    ("musica", "De que pais es el duo Daft Punk?", "Alemania", "Francia", "Italia", "Reino Unido", "b", "intermedio"),
    # DIFICIL
    ("videojuegos", "Como se llama la IA antagonista de Portal?", "Cortana", "EDI", "GLaDOS", "Ava", "c", "dificil"),
    ("videojuegos", "Como se llama el mundo principal de Elden Ring?", "The Lands Between", "Lordran", "Yharnam", "Midgar", "a", "dificil"),
    ("series", "En Better Call Saul, cual es el apellido real de Jimmy?", "Goodman", "McGill", "Ehrmantraut", "Fring", "b", "dificil"),
    ("series", "Como se llama el vendedor del monorriel en el episodio clasico de Los Simpson?", "Troy McClure", "Gil Gunderson", "Lyle Lanley", "Fat Tony", "c", "dificil"),
    ("peliculas", "Quien dirigio Blade Runner 2049?", "Denis Villeneuve", "Christopher Nolan", "David Fincher", "Guillermo del Toro", "a", "dificil"),
    ("peliculas", "Que pelicula de Nolan (2000) gira alrededor de la perdida de memoria?", "Insomnia", "Following", "Memento", "Tenet", "c", "dificil"),
    ("cultura pop", "Que significa la sigla TVA en Loki?", "Time Variation Agency", "Time Variance Authority", "Temporal Vision Archive", "Time Void Alliance", "b", "dificil"),
    ("cultura pop", "Como se llama el martillo de Thor en Marvel?", "Stormbreaker", "Excalibur", "Leviatan", "Mjolnir", "d", "dificil"),
    ("musica", "Que banda publico el album OK Computer?", "Muse", "Radiohead", "Coldplay", "Blur", "b", "dificil"),
    ("musica", "Quien compuso Las Cuatro Estaciones?", "Mozart", "Bach", "Vivaldi", "Beethoven", "c", "dificil"),
]


def main():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        if db.query(Pregunta).count() > 0:
            print("Ya hay preguntas cargadas, no se vuelve a sembrar.")
            return

        for tema, enunciado, a, b, c, d, correcta, dificultad in PREGUNTAS:
            db.add(
                Pregunta(
                    tema=tema,
                    enunciado=enunciado,
                    respuesta_a=a,
                    respuesta_b=b,
                    respuesta_c=c,
                    respuesta_d=d,
                    correcta=correcta,
                    dificultad=dificultad,
                )
            )
        db.commit()
        print(f"{len(PREGUNTAS)} preguntas insertadas.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
