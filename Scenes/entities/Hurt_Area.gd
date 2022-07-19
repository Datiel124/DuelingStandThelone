extends Area

export var damage : float = 10
export var ticktime : float = 0.25

func _ready() -> void:
	$painrate.start(ticktime)

func _on_painrate_timeout() -> void:
	var bodies = get_overlapping_bodies()
	for victims in bodies:
		if victims.has_method("Damage"):
			victims.Damage(damage)
	pass # Replace with function body.
