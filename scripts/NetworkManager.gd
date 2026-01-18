extends Node

const PORT = 7777
const MAX_PLAYERS = 8

var peer = ENetMultiplayerPeer.new()
var players = {}
var is_server = false

signal player_connected(id)
signal player_disconnected(id)
signal server_started
signal connected_to_server

func create_server():
	peer.create_server(PORT, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	is_server = true
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
	print("✅ Server started on port ", PORT)
	emit_signal("server_started")

func join_server(address: String):
	peer.create_client(address, PORT)
	multiplayer.multiplayer_peer = peer
	is_server = false
	
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	
	print("🔍 Connecting to ", address)

func _on_player_connected(id):
	print("Player connected: ", id)
	players[id] = {"id": id, "ready": false}
	emit_signal("player_connected", id)

func _on_player_disconnected(id):
	print("Player disconnected: ", id)
	players.erase(id)
	emit_signal("player_disconnected", id)

func _on_connected_to_server():
	print("✅ Connected to server!")
	emit_signal("connected_to_server")

func _on_connection_failed():
	print("❌ Connection failed!")

func get_player_count() -> int:
	return players.size() + 1  # +1 for host
