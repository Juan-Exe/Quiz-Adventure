extends Control

const BASE_URL := "http://127.0.0.1:8000"
const COLOR_CORRECTA := Color(0.2, 0.7, 0.3)
const COLOR_INCORRECTA := Color(0.75, 0.2, 0.2)
const SEGUNDOS_ANTES_DE_SIGUIENTE := 1.0
const DURACION_FADE := 0.15

## Escena de combate: pide una pregunta al backend, la muestra con sus
## 4 opciones, y al responder valida contra el backend marcando en
## verde/rojo el resultado. Las transiciones entre preguntas usan un
## fade suave. Tras una pausa breve, pasa a la siguiente pregunta
## automaticamente. La referencia del prototipo se puede ocultar con
## la tecla R mientras se ajusta el layout.

@onready var referencia: TextureRect = $ReferenciaPrototipo
@onready var enunciado_label: Label = $Enunciado
@onready var http_request: HTTPRequest = $HTTPRequest
@onready var respuestas_grid: GridContainer = $Respuestas
@onready var botones: Array[Button] = [
	$Respuestas/Respuesta1,
	$Respuestas/Respuesta2,
	$Respuestas/Respuesta3,
	$Respuestas/Respuesta4,
]

const OPCIONES := ["a", "b", "c", "d"]

var pregunta_actual_id: int = -1
var peticion_en_curso: bool = false
var indice_elegido_actual: int = -1


func _ready() -> void:
	http_request.request_completed.connect(_on_request_completed)
	for i in botones.size():
		botones[i].pressed.connect(_on_respuesta_pressed.bind(i))
		botones[i].mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pedir_pregunta()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		referencia.visible = not referencia.visible


func pedir_pregunta(dificultad: String = "facil", tema: String = "musica") -> void:
	if peticion_en_curso:
		return
	peticion_en_curso = true
	for boton in botones:
		boton.disabled = true

	var url := "%s/preguntas/aleatoria/%s/%s" % [BASE_URL, dificultad, tema]
	var error := http_request.request(url)
	if error != OK:
		peticion_en_curso = false


func _on_respuesta_pressed(indice: int) -> void:
	if peticion_en_curso or pregunta_actual_id == -1:
		return
	peticion_en_curso = true
	indice_elegido_actual = indice
	for boton in botones:
		boton.disabled = true

	var url := "%s/preguntas/%d/responder" % [BASE_URL, pregunta_actual_id]
	var cuerpo := JSON.stringify({"opcion": OPCIONES[indice]})
	var headers := ["Content-Type: application/json"]

	var error := http_request.request(url, headers, HTTPClient.METHOD_POST, cuerpo)
	if error != OK:
		peticion_en_curso = false


func _on_request_completed(
	result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		peticion_en_curso = false
		enunciado_label.text = "Error de conexion con el backend"
		return

	var json: Variant = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		peticion_en_curso = false
		return

	if json.has("respuestas"):
		_mostrar_pregunta_animada(json)
	elif json.has("correcta"):
		peticion_en_curso = false
		_procesar_resultado(json)


func _mostrar_pregunta_animada(json: Dictionary) -> void:
	_restaurar_botones()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(enunciado_label, "modulate:a", 0.0, DURACION_FADE)
	tween.tween_property(respuestas_grid, "modulate:a", 0.0, DURACION_FADE)
	tween.chain().tween_callback(func():
		pregunta_actual_id = json["id"]
		enunciado_label.text = json["enunciado"]
		var respuestas: Dictionary = json["respuestas"]
		for i in botones.size():
			botones[i].text = respuestas[OPCIONES[i]]
			botones[i].disabled = false
		peticion_en_curso = false
	)
	tween.chain().set_parallel(true)
	tween.tween_property(enunciado_label, "modulate:a", 1.0, DURACION_FADE)
	tween.tween_property(respuestas_grid, "modulate:a", 1.0, DURACION_FADE)


func _procesar_resultado(json: Dictionary) -> void:
	var correcta: bool = json["correcta"]
	var opcion_correcta: String = json["opcion_correcta"]
	var indice_correcto := OPCIONES.find(opcion_correcta)

	if correcta:
		_pintar_boton(indice_elegido_actual, COLOR_CORRECTA)
	else:
		_pintar_boton(indice_elegido_actual, COLOR_INCORRECTA)
		_pintar_boton(indice_correcto, COLOR_CORRECTA)

	await get_tree().create_timer(SEGUNDOS_ANTES_DE_SIGUIENTE).timeout
	pedir_pregunta()


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
