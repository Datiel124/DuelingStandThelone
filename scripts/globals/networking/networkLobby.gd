extends Node

func _ready():
	#Server signals. Called on the server host's machine aswell as other clients.
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	#Client signals. Called if trying to join a server as a client.
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	#Register me for debug.
	if 1==0:
		Network.createServer()
		player_info[get_tree().get_network_unique_id()] = my_info

#Info of other players. Associate ID to data
var player_info = {}
#Info we need to send to other players.
var my_info = {name = "PlayerAwesome", iconcolor = Color.orange}

#A log of my client's messages sent through the Chat feed.
var MessagesSent = [""]

func _player_connected(id):
	print("Say Hello To : " + str(id))
	#Send my info to the the new player.
	#Let's just use this opportunity to add ourselves too.
	player_info[get_tree().get_network_unique_id()] = my_info
	rpc_id(id, "register_player", my_info)

func _player_disconnected(id):
	print("Goodbye, " + str(id))
	#wait a couple frames before deleting information
	for wait in range(5):
		yield(get_tree(),"idle_frame")
	player_info.erase(id) 
	#Erase player from locally stored list.
	#Goodbye, player!

func _connected_ok():
	pass #Only called on clients.

func _server_disconnected():
	print("The server disconnected.")
	Network.terminatePeer()
	pass #Server kicked us. Show error and abort.

func _connected_fail():
	print("Failed to connect")
	pass #Failed to connect. Abort.
 
signal registeredPlayer(who)
#Make this a remote function so that other players can see who just joined.
remote func register_player(info):
	var id = get_tree().get_rpc_sender_id()
	#Store info.
	player_info[id] = info
	emit_signal("registeredPlayer", id)
#REMOTE keyword : rpc() will go via network and execute remotely.
#REMOTESYNC keyword : rpc() will go via network and execute remotely, and locally. (does normal function call)

signal finishedLoadingData(id)
remote func loadData(datapath):
	#Server - Tells everyone to load data, then waits for them to load it.
	var x = load(datapath)
	#Tell the server you finished loading your data.
	emit_signal("finishedLoadingData", get_tree().get_network_unique_id())
	rpc_id(1, "emit_signal", "finishedLoadingData", get_tree().get_network_unique_id())
	print("Finished loading data at " + str(datapath) + " !")
	return x
