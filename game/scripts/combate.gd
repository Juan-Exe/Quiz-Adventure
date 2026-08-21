extends Control

const BASE_URL := "http://127.0.0.1:8000"
const COLOR_CORRECTA := Color(0.2, 0.7, 0.3)
const COLOR_INCORRECTA := Color(0.75, 0.2, 0.2)
const SEGUNDOS_ANTES_DE_SIGUIENTE := 0.4
const DURACION_FADE := 0.15
const DIFICULTADES := ["facil", "intermedio", "dificil", "master"]

const DURACION_EMBESTIDA := 0.25
const DURACION_IMPACTO := 0.5

const HEROE_IDLE := preload("res://assets/sprites/heroe/heroe_idle.png")
const HEROE_ATAQUE := preload("res://assets/sprites/heroe/heroe_ataque.png")
const HEROE_HERIDO := preload("res://assets/sprites/heroe/heroe_herido.png")
const ENEMIGO_IDLE := preload("res://assets/sprites/enemigo/enemigo_idle.png")
const ENEMIGO_ATAQUE := preload("res://assets/sprites/enemigo/enemigo_ataque.png")
const ENEMIGO_HERIDO := preload("res://assets/sprites/enemigo/enemigo_herido.png")

## Escena de combate: pide una pregunta al backend, la muestra con sus
## 4 opciones, y al responder valida contra el backend marcando en
## verde/rojo el resultado. Elige tema al azar dentro de la dificultad
## actual y evita repetir preguntas ya usadas en esa combinacion.
## Las transiciones entre preguntas usan un fade suave. Tras una pausa
## breve, pasa a la siguiente pregunta automaticamente. La referencia
## del prototipo se puede ocultar con la tecla R mientras se ajusta
## el layout.

@onready var referencia: TextureRect = $ReferenciaPrototipo
@onready var enunciado_label: Label = $Enunciado
@onready var http_request: HTTPRequest = $HTTPRequest
@onready var respuestas_grid: GridContainer = $Respuestas
@onready var heroe: TextureRect = $Heroe
@onready var enemigo: TextureRect = $Enemigo
@onready var botones: Array[Button] = [
	$Respuestas/Respuesta1,
	$Respuestas/Respuesta2,
	$Respuestas/Respuesta3,
	$Respuestas/Respuesta4,
]

var heroe_posicion_original: Vector2
var enemigo_posicion_original: Vector2

const OPCIONES := ["a", "b", "c", "d"]

var pregunta_actual_id: int = -1
var peticion_en_curso: bool = false
var indice_elegido_actual: int = -1

var dificultad_actual: String = "facil"
var tema_actual: String = ""
# ya_usadas_por_combo["facil|musica"] = [1, 4, 9]
var ya_usadas_por_combo: Dictionary = {}
var temas_por_dificultad: Dictionary = {}
var dificultades_consultadas: int = 0


func _ready() -> void:
	heroe_posicion_original = heroe.position
	enemigo_posicion_original = enemigo.position
	http_request.request_completed.connect(_on_request_completed)
	for i in botones.size():
		botones[i].pressed.connect(_on_respuesta_pressed.bind(i))
		botones[i].mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_cargar_temas_y_empezar()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		referencia.visible = not referencia.visible


func _cargar_temas_y_empezar() -> void:
	for dificultad in DIFICULTADES:
		var http := HTTPRequest.new()
		add_child(http)
		var url := "%s/preguntas/temas/%s" % [BASE_URL, dificultad]
		http.request_completed.connect(
			_on_temas_recibidos.bind(dificultad, http), CONNECT_ONE_SHOT
		)
		http.request(url)


func _on_temas_recibidos(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	dificultad: String,
	http: HTTPRequest
) -> void:
	http.queue_free()
	dificultades_consultadas += 1

	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var temas: Variant = JSON.parse_string(body.get_string_from_utf8())
		if temas is Array and temas.size() > 0:
			temas_por_dificultad[dificultad] = temas

	# Cuando ya consultamos las 4 dificultades (tengan o no temas), arrancamos
	# con la primera dificultad de DIFICULTADES que si tenga contenido.
	if dificultades_consultadas == DIFICULTADES.size() and pregunta_actual_id == -1 and not peticion_en_curso:
		for dificultad_disponible in DIFICULTADES:
			if temas_por_dificultad.has(dificultad_disponible):
				dificultad_actual = dificultad_disponible
				break
		if tema_actual == "" and temas_por_dificultad.has(dificultad_actual):
			_elegir_siguiente_combo()
			pedir_pregunta()
		elif temas_por_dificultad.is_empty():
			enunciado_label.text = "No hay preguntas cargadas en el backend"


func _elegir_siguiente_combo() -> void:
	var temas: Array = temas_por_dificultad.get(dificultad_actual, [])
	if temas.is_empty():
		return
	tema_actual = temas[randi() % temas.size()]


func _clave_combo() -> String:
	return "%s|%s" % [dificultad_actual, tema_actual]


func pedir_pregunta() -> void:
	if peticion_en_curso:
		return
	if tema_actual == "":
		return
	peticion_en_curso = true
	for boton in botones:
		boton.disabled = true

	var usadas: Array = ya_usadas_por_combo.get(_clave_combo(), [])
	var ya_usadas_str := ",".join(usadas.map(func(id): return str(id)))

	var url := "%s/preguntas/aleatoria/%s/%s" % [BASE_URL, dificultad_actual, tema_actual.uri_encode()]
	if ya_usadas_str != "":
		url += "?ya_usadas=%s" % ya_usadas_str

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
	if result != HTTPRequest.RESULT_SUCCESS:
		peticion_en_curso = false
		enunciado_label.text = "Error de conexion con el backend"
		return

	if response_code == 404:
		# Se agotaron las preguntas de este tema+dificultad: probamos otro tema.
		peticion_en_curso = false
		_reintentar_con_otro_tema()
		return

	if response_code != 200:
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


func _reintentar_con_otro_tema() -> void:
	var temas: Array = temas_por_dificultad.get(dificultad_actual, [])
	var otros := temas.filter(func(t): return t != tema_actual)
	if otros.size() > 0:
		tema_actual = otros[randi() % otros.size()]
	else:
		# Ya no quedan preguntas nuevas en ninguna combinacion de esta dificultad.
		ya_usadas_por_combo.erase(_clave_combo())
	pedir_pregunta()


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

	var clave := _clave_combo()
	if not ya_usadas_por_combo.has(clave):
		ya_usadas_por_combo[clave] = []
	ya_usadas_por_combo[clave].append(pregunta_actual_id)

	if correcta:
		_pintar_boton(indice_elegido_actual, COLOR_CORRECTA)
		await _secuencia_ataque_heroe()
	else:
		_pintar_boton(indice_elegido_actual, COLOR_INCORRECTA)
		_pintar_boton(indice_correcto, COLOR_CORRECTA)
		await _secuencia_ataque_enemigo()

	await get_tree().create_timer(SEGUNDOS_ANTES_DE_SIGUIENTE).timeout
	_elegir_siguiente_combo()
	pedir_pregunta()


func _secuencia_ataque_heroe() -> void:
	var destino := Vector2(
		enemigo_posicion_original.x - heroe.size.x * 0.6, heroe_posicion_original.y
	)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(heroe, "position", destino, DURACION_EMBESTIDA)
	await tween.finished

	heroe.texture = HEROE_ATAQUE
	enemigo.texture = ENEMIGO_HERIDO
	await get_tree().create_timer(DURACION_IMPACTO).timeout

	var tween_vuelta := create_tween()
	tween_vuelta.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_vuelta.tween_property(heroe, "position", heroe_posicion_original, DURACION_EMBESTIDA)
	await tween_vuelta.finished

	heroe.texture = HEROE_IDLE
	enemigo.texture = ENEMIGO_IDLE


func _secuencia_ataque_enemigo() -> void:
	var destino := Vector2(
		heroe_posicion_original.x + heroe.size.x * 0.6, enemigo_posicion_original.y
	)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(enemigo, "position", destino, DURACION_EMBESTIDA)
	await tween.finished

	enemigo.texture = ENEMIGO_ATAQUE
	heroe.texture = HEROE_HERIDO
	await get_tree().create_timer(DURACION_IMPACTO).timeout

	var tween_vuelta := create_tween()
	tween_vuelta.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_vuelta.tween_property(enemigo, "position", enemigo_posicion_original, DURACION_EMBESTIDA)
	await tween_vuelta.finished

	enemigo.texture = ENEMIGO_IDLE
	heroe.texture = HEROE_IDLE


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
