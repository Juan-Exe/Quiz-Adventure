# Quiz Adventure - Backend

API REST en FastAPI para la gestión de preguntas del juego (base del proyecto).
La lógica de puntaje, vidas y bonus (ver `Reglas Quiz adventure.xlsx`) se agregará en una siguiente fase.

## Requisitos

- Python 3.10+

## Instalación

```bash
cd backend
python -m venv venv
venv\Scripts\activate       # Windows
pip install -r requirements.txt
```

## Cargar preguntas de ejemplo

```bash
python seed.py
```

## Ejecutar el servidor

```bash
uvicorn app.main:app --reload
```

- API: http://127.0.0.1:8000
- Documentación interactiva: http://127.0.0.1:8000/docs

## Endpoints disponibles

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/preguntas` | Lista todas las preguntas |
| POST | `/preguntas` | Registra una pregunta nueva |
| GET | `/preguntas/{id}` | Obtiene una pregunta por id |
| PUT | `/preguntas/{id}` | Edita una pregunta |
| DELETE | `/preguntas/{id}` | Elimina una pregunta |
| GET | `/preguntas/aleatoria/{dificultad}/{tema}?ya_usadas=1,2,3` | Pregunta aleatoria sin revelar la respuesta correcta |
| GET | `/preguntas/temas/{dificultad}` | Temas disponibles para una dificultad |
| GET | `/preguntas/conteo/por-dificultad` | Conteo de preguntas por dificultad |

Dificultades válidas: `facil`, `intermedio`, `dificil`, `master`.

## Consumir desde Godot

Con el nodo `HTTPRequest`:

```gdscript
func pedir_pregunta(dificultad: String, tema: String):
    var url = "http://127.0.0.1:8000/preguntas/aleatoria/%s/%s" % [dificultad, tema]
    $HTTPRequest.request(url)

func _on_http_request_completed(result, response_code, headers, body):
    var json = JSON.parse_string(body.get_string_from_utf8())
    print(json)
```
