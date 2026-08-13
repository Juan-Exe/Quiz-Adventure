extends Control

const BASE_URL := "http://127.0.0.1:8000"
const COLOR_CORRECTA := Color(0.2, 0.7, 0.3)
const COLOR_INCORRECTA := Color(0.75, 0.2, 0.2)

## Escena de combate: pide una pregunta al backend, la muestra con sus
## 4 opciones, y al responder valida contra el backend marcando en
## verde/rojo el resultado. La referencia del prototipo se puede
## ocultar con la tecla R mientras se ajusta el layout.

@onready var referencia: TextureRect = $ReferenciaPrototipo
@onready var enunciado_label: Label = $Enunciado
@onready var http_request: HTTPRequest = $HTTPRequest
@onready var botones: Array[Button] = [
	$Respuestas/Respuesta1,
	$Respuestas/Respuesta2,
	$Respuestas/Respuesta3,
	$Respuestas/Respuesta4,
]

const OPCIONES := ["a", "b", "c", "d"]

var pregunta_actual_id: int = -1
var respondiendo: bool = false


func _ready() -> void:
	for i in botones.size():
		botones[i].pressed.connect(_on_respuesta_pressed.bind(i))
	pedir_pregunta()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		referencia.visible = not referencia.visible


func pedir_pregunta(dificultad: String = "facil", tema: String = "musica") -> void:
	respondiendo = false
	_restaurar_botones()
	enunciado_label.text = "Cargando pregunta..."
	for boton in botones:
		boton.disabled = true

	var url := "%s/preguntas/aleatoria/%s/%s" % [BASE_URL, dificultad, tema]
	http_request.request_completed.connect(_on_pregunta_recibida, CONNECT_ONE_SHOT)
	var error := http_request.request(url)
	if error != OK:
		enunciado_label.text = "Error al pedir la pregunta"


func _on_pregunta_recibida(
	result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		enunciado_label.text = "No se pudo cargar la pregunta (¿backend corriendo?)"
		return

	var json: Variant = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		enunciado_label.text = "Respuesta invalida del backend"
		return

	pregunta_actual_id = json["id"]
	enunciado_label.text = json["enunciado"]

	var respuestas: Dictionary = json["respuestas"]
	for i in botones.size():
		botones[i].text = respuestas[OPCIONES[i]]
		botones[i].disabled = false


func _on_respuesta_pressed(indice: int) -> void:
	if respondiendo or pregunta_actual_id == -1:
		return
	respondiendo = true
	for boton in botones:
		boton.disabled = true

	var url := "%s/preguntas/%d/responder" % [BASE_URL, pregunta_actual_id]
	var cuerpo := JSON.stringify({"opcion": OPCIONES[indice]})
	var headers := ["Content-Type: application/json"]

	http_request.request_completed.connect(
		_on_resultado_recibido.bind(indice), CONNECT_ONE_SHOT
	)
	var error := http_request.request(url, headers, HTTPClient.METHOD_POST, cuerpo)
	if error != OK:
		enunciado_label.text = "Error al enviar la respuesta"


func _on_resultado_recibido(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	indice_elegido: int
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		enunciado_label.text = "Error al validar la respuesta"
		return

	var json: Variant = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		return

	var correcta: bool = json["correcta"]
	var opcion_correcta: String = json["opcion_correcta"]
	var indice_correcto := OPCIONES.find(opcion_correcta)

	if correcta:
		_pintar_boton(indice_elegido, COLOR_CORRECTA)
	else:
		_pintar_boton(indice_elegido, COLOR_INCORRECTA)
		_pintar_boton(indice_correcto, COLOR_CORRECTA)


func _pintar_boton(indice: int, color: Color) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.border_width_left = 3
	estilo.border_width_top = 3
	estilo.border_width_right = 3
	estilo.border_width_bottom = 3
	estilo.border_color = color.lightened(0.2)
	botones[indice].add_theme_stylebox_override("disabled", estilo)


func _restaurar_botones() -> void:
	for boton in botones:
		boton.remove_theme_stylebox_override("disabled")
