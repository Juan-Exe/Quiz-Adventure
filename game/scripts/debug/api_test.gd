extends Control

const BASE_URL := "http://127.0.0.1:8000"

@onready var http_request: HTTPRequest = $HTTPRequest
@onready var resultado_label: Label = $CenterContainer/VBoxContainer/ResultadoLabel


func _on_pedir_pregunta_pressed() -> void:
	resultado_label.text = "Pidiendo pregunta..."
	var url := BASE_URL + "/preguntas/aleatoria/facil/musica"
	var error := http_request.request(url)
	if error != OK:
		resultado_label.text = "Error al iniciar la peticion: %s" % error


func _on_http_request_request_completed(
	result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		resultado_label.text = "Fallo de conexion (result=%s). ¿Esta el backend corriendo?" % result
		return

	if response_code != 200:
		resultado_label.text = "Backend respondio con error %s" % response_code
		return

	var json: Variant = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		resultado_label.text = "Respuesta invalida del backend"
		return

	var respuestas: Dictionary = json["respuestas"]
	var texto := "%s\n\nA) %s\nB) %s\nC) %s\nD) %s" % [
		json["enunciado"],
		respuestas["a"], respuestas["b"], respuestas["c"], respuestas["d"]
	]
	resultado_label.text = texto
