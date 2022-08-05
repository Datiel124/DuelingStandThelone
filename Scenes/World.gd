extends Node

func _ready() -> void:
	#check if online
	get_tree().connect('server_disconnected', get_tree(), 'change_scene', ['res://Scenes/ui/menu/Main-Menu.tscn'])
	get_tree().connect('server_disconnected', Network, 'terminatePeer')
	if get_tree().get_network_connected_peers().size() > 0:
		#do stuff when user is online
		pass
	else:
		#do stuff when user is offline
		if get_tree().network_peer :
			if $Players.get_children().size() > 0:
				#player already exists in map for debugging purpsoes
				return
			var player = addPlayerToWorld(get_tree().get_network_unique_id())
#			player.global_transform.origin = 
			player.global_transform.origin = GameFuncts.get_map_spawns()[0].global_transform.origin
		else:
			Network.createClient("192.168.0.0", 0)
			var player = addPlayerToWorld(get_tree().get_network_unique_id())
			player.global_transform.origin = GameFuncts.get_map_spawns()[0].global_transform.origin
	pass

func addPlayerToWorld(id) -> Player:
	if !$Players.has_node(str(id)):
		var pl = NetworkLobby.instance_player(id)
		$Players.add_child(pl)
		return pl
	return null
