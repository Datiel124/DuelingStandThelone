extends Area

export var damage : int = 10

func _on_painrate_timeout() -> void:
	var bodies = get_overlapping_bodies()
	for victims in bodies:
		if victims.has_method("Damage"):
			victims.Damage(damage)
	pass # Replace with function body.
