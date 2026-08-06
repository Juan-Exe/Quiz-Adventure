extends Control


func _on_jugar_pressed() -> void:
	print("Jugar presionado - aqui cargaremos la escena del juego")


func _on_salir_pressed() -> void:
	get_tree().quit()
