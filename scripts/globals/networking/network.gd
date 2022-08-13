extends Node

const DEFAULT_IP = "192.168.1.117"
const DEFAULT_PORT = 7777
const MAX_CLIENTS = 32

var server : NetworkedMultiplayerENet = null
var client : NetworkedMultiplayerENet = null

#Initializing as a Server, listening to the given port, with max number of peers.
func createServer(port = DEFAULT_PORT, maxclients = MAX_CLIENTS):
	print("Creating server in network.gd")
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(port, maxclients)
	get_tree().network_peer = peer
	server = peer

#Initializing as a Client, connecting to a given IP and port.
func createClient(ip, port):
	print("Creating client in network.gd")
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, port)
	get_tree().network_peer = peer 
	client = peer
#To get the previously set peer (Which can be both a server and a client),
#use get_tree().get_network_peer().
#To check if the tree is a server or a client,
#use get_tree().is_network_server()

signal upnp_completed(error)

var thread = null

func _upnp_setup(server_port):
	var upnp = UPNP.new()
	var err = upnp.discover()
	if err != OK:
		print("UPNP FAIL")
		push_error(str(err))
		emit_signal("upnp_completed", err)
		return
	if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(): 
		print("UPNP SUCCESS")
		upnp.add_port_mapping(server_port, server_port, ProjectSettings.get_setting("application/config/name"), "UDP")
		upnp.add_port_mapping(server_port, server_port, ProjectSettings.get_setting("application/config/name"), "TCP")
		emit_signal("upnp_completed", OK)

func startUPNP(port):
	thread = Thread.new()
	thread.start(self, "_upnp_setup", port)

func terminatePeer():
	if thread != null:
		thread.wait_to_finish()
		print("Closing UPNP")
		thread = null
	print_debug("TERMINATING PEER")
	
	NetworkLobby.player_info.clear()
	get_tree().network_peer = null
	if client != null:
		client.close_connection()
	elif server != null:
		server.close_connection()
	client = null
	server = null

#This function will allow me to refuse new players from joining at any time.
func setServerJoinable(state : bool):
	get_tree().set_refuse_new_network_connections(state)
#REMEMBER : To store the SceneTree.get_network_unique_id()
#SECURITY MEASURE? : I'm certain godot closes the connection automatically, but I'll do it here anyways.
func _notification(what):
	if what == NOTIFICATION_WM_QUIT_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		terminatePeer()

func _instance(thing : EncodedObjectAsID):
	thing = instance_from_id(thing.get_object_id())
	
