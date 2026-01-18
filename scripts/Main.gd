extends Node3D

@onready var lobby_ui = preload("res://scenes/LobbyUI.tscn").instantiate()
@onready var game_ui = preload("res://scenes/GameUI.tscn").instantiate()

var local_player_nickname = ""
var local_player_id = 0

func _ready():
	# 로비 UI
	add_child(lobby_ui)
	lobby_ui.start_game_requested.connect(_on_start_game_requested)
	
	# 게임 UI
	add_child(game_ui)
	game_ui.visible = false
	
	# 이벤트 연결
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	GameManager.game_started.connect(_on_game_started)
	GameManager.phase_changed.connect(_on_phase_changed)
	
	# 타이머 연결
	GameManager.time_updated.connect(game_ui.update_timer)
	GameManager.prepare_time_updated.connect(game_ui.update_prepare_timer)

func _on_start_game_requested(nickname: String):
	local_player_nickname = nickname
	NetworkManager.create_server()
	await get_tree().create_timer(2.0).timeout
	start_game()

func start_game():
	lobby_ui.visible = false
	game_ui.visible = true
	spawn_local_player()
	local_player_id = multiplayer.get_unique_id()
	game_ui.add_player(local_player_id, local_player_nickname)

func spawn_local_player():
	var player = preload("res://scenes/Player.tscn").instantiate()
	player.name = str(multiplayer.get_unique_id())
	player.player_id = multiplayer.get_unique_id()
	player.position = Vector3(randf_range(-5, 5), 1, randf_range(-5, 5))
	$Players.add_child(player)

func _on_player_connected(id: int):
	print("Player ", id, " connected")
	game_ui.add_player(id, "Player" + str(id))

func _on_player_disconnected(id: int):
	print("Player ", id, " disconnected")
	game_ui.remove_player(id)

func _on_game_started(seeker_id: int):
	var seeker_name = ""
	if seeker_id == local_player_id:
		seeker_name = local_player_nickname
	else:
		seeker_name = "Player" + str(seeker_id)
	
	game_ui.update_seeker(seeker_name)

func _on_phase_changed(phase):
	print("Phase changed: ", phase)
