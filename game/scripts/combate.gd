extends Control

## Escena de combate: por ahora solo el enunciado de la pregunta
## y los 4 botones de respuesta. La referencia del prototipo se
## puede ocultar con la tecla R mientras se ajusta el layout.

@onready var referencia: TextureRect = $ReferenciaPrototipo
@onready var enunciado_label: Label = $Enunciado
@onready var botones: Array[Button] = [
	$Respuestas/Respuesta1,
	$Respuestas/Respuesta2,
	$Respuestas/Respuesta3,
	$Respuestas/Respuesta4,
]


func _ready() -> void:
	for i in botones.size():
		botones[i].pressed.connect(_on_respuesta_pressed.bind(i))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		referencia.visible = not referencia.visible


func mostrar_pregunta(enunciado: String, opciones: Array[String]) -> void:
	enunciado_label.text = enunciado
	for i in botones.size():
		botones[i].text = opciones[i]


func _on_respuesta_pressed(indice: int) -> void:
	print("Respuesta seleccionada: %d - %s" % [indice, botones[indice].text])
