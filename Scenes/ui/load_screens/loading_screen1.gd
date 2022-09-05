extends Control

func _ready() -> void:
	GameFuncts.connect('load_progress_changed', self, 'change_progress')
	GameFuncts.connect('announce_goto', self, 'set_visible', [true])
	GameFuncts.connect('error_goto', self, 'set_viisble', [false])

func change_progress(value) -> void:
	$ColorRect/CenterContainer/VBoxContainer/ProgressBar.value = value * 100
	yield(get_tree(), 'idle_frame')
