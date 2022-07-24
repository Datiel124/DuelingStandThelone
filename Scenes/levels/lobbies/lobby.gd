extends "res://Scenes/World.gd"

func _ready() -> void:
	print("Connecting lobby signals...")
	NetworkLobby.connect('registeredPlayer', self, 'refreshLobby')
	#add de Host
	addPlayerToWorld(1)

func _process(delta: float) -> void:
	print(NetworkLobby.player_info)

func refreshLobby(id):
	addPlayerToWorld(id)
	for players in NetworkLobby.player_info:
		addPlayerToWorld(players)
