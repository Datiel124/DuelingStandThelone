extends StateMachine

func _ready() -> void:
	add_state("IDLE")
	add_state("SHOOTING")
	set_state("IDLE")
