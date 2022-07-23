extends PopupPanel

func _on_HOST_pressed() -> void:
	hide()
	$HOSTdialogue.popup()
	pass # Replace with function body.

func _on_JOIN_pressed() -> void:
	hide()
	$JOINdialogue.popup()
	pass # Replace with function body.

