#extends Node3D
#
###### 로비와 게임ui 미리 로드시켜놓음 
#@onready var lobby_ui = preload("res://scenes/LobbyUI.tscn").instantiate()
#@onready var game_ui = preload("res://scenes/GameUI.tscn").instantiate()
#
#var local_player_nickname = ""
#var local_player_id = 0
#
#func _ready():
	#
	#var floor = $Floor
	#if floor:
		#floor.position.y = 0.8  # 발 안 보이게 올림
		#
		## 크기도 30x30으로
		#var mesh_instance = floor.get_node_or_null("MeshInstance3D")
		#if not mesh_instance and floor is MeshInstance3D:
			#mesh_instance = floor
		#
		#if mesh_instance and mesh_instance.mesh is BoxMesh:
			#mesh_instance.mesh.size = Vector3(30, 1, 30)
		#
		#var collision = floor.get_node_or_null("CollisionShape3D")
		#if collision and collision.shape is BoxShape3D:
			#collision.shape.size = Vector3(30, 1, 30)
	#
	#setup_water_floor()
	#create_invisible_walls()
#
	## 로비 UI
	#add_child(lobby_ui)
	#lobby_ui.start_game_requested.connect(_on_start_game_requested)
	#
	#multiplayer.connected_to_server.connect(_on_connected_to_server)
	#
	## 게임 UI
	#add_child(game_ui)
	#game_ui.visible = false
	#
	## 이벤트 연결
	#NetworkManager.player_connected.connect(_on_player_connected)
	#NetworkManager.player_disconnected.connect(_on_player_disconnected)
	#GameManager.game_started.connect(_on_game_started)
	#GameManager.phase_changed.connect(_on_phase_changed)
	#
	## 타이머 연결
	#GameManager.time_updated.connect(game_ui.update_timer)
	#GameManager.prepare_time_updated.connect(game_ui.update_prepare_timer)
#
#func _on_connected_to_server():
	## 클라이언트만 여기 들어옴 (서버는 이 신호 안 받음)
	#print("클라이언트 연결 성공 → 로컬 플레이어 스폰")
	#await get_tree().create_timer(0.2).timeout  # 약간의 네트워크 안정화 대기
	##spawn_local_player()
	#local_player_id = multiplayer.get_unique_id()
	#game_ui.add_player(local_player_id, local_player_nickname)
#
#func _on_start_game_requested(nickname: String):
	#local_player_nickname = nickname
	#NetworkManager.create_server()
	#
	#await get_tree().create_timer(1.0).timeout
	#
	#lobby_ui.visible = false
	#game_ui.visible = true
	#
	## 서버(호스트)는 여기서 직접 스폰 (connected_to_server 신호 안 오니까)
	#spawn_local_player()
	#local_player_id = multiplayer.get_unique_id()
	#game_ui.add_player(local_player_id, local_player_nickname)
	#
	#await get_tree().create_timer(1.0).timeout
	#if multiplayer.is_server():
		#GameManager.start_game()
		#
		#
#
#func setup_water_floor():
	#var floor = $Floor
	#if not floor:
		#return
	#
	#var mesh_instance = floor.get_node_or_null("MeshInstance3D")
	#if not mesh_instance:
	#
		#if floor is MeshInstance3D:
			#mesh_instance = floor
	#
	#if mesh_instance:
		## 물 재질 생성
		#var water_material = StandardMaterial3D.new()
		#water_material.albedo_color = Color(0.31, 0.70, 0.85, 0.85)  # 청록색 + 투명
		#water_material.metallic = 0.3
		#water_material.metallic_specular = 0.8
		#water_material.roughness = 0.2
		#water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		#
		#mesh_instance.material_override = water_material
		#
		#
#func start_game():
	#lobby_ui.visible = false
	#game_ui.visible = true
	#
	#var my_id = multiplayer.get_unique_id()
	#var existing_player = $Players.get_node_or_null(str(my_id))
	#
	#if not existing_player:
		## 없으면 생성
		#spawn_local_player()
	#else:
		## 있으면 그냥 사용
		#print("기존 플레이어 사용")
	#
	#local_player_id = multiplayer.get_unique_id()
	#game_ui.add_player(local_player_id, local_player_nickname)
#
	#
#func spawn_local_player():
	#var my_id_str = str(multiplayer.get_unique_id())
	#
	#if $Players.has_node(my_id_str):
		#print("이미 내 플레이어 존재 → 스킵")
		#var existing = $Players.get_node(my_id_str)
		#existing.position = Vector3(randf_range(-12, 12), 1.8, randf_range(-12, 12))  # 🆕 y=1.8
		#return
	#
	#print("🔍 spawn_local_player 호출!")
	#var player = preload("res://scenes/Player.tscn").instantiate()
	#player.name = my_id_str
	#player.player_id = multiplayer.get_unique_id()
	#player.set_multiplayer_authority(multiplayer.get_unique_id())
	#
	#player.position = Vector3(randf_range(-12, 12), 1.8, randf_range(-12, 12))  # 🆕 y=1.8
	#$Players.add_child(player)
#
#
	#
#
#func _on_player_connected(id: int):
	#print("Player ", id, " connected")
	#game_ui.add_player(id, "Player" + str(id))
#
#func _on_player_disconnected(id: int):
	#print("Player ", id, " disconnected")
	#game_ui.remove_player(id)
#
#func _on_game_started(seeker_id: int):
	#var seeker_name = ""
	#if seeker_id == local_player_id:
		#seeker_name = local_player_nickname
	#else:
		#seeker_name = "Player" + str(seeker_id)
	#
	#game_ui.update_seeker(seeker_name)
#
#func _on_phase_changed(phase):
	#print("Phase changed: ", phase)
	#
#
#func create_invisible_walls():
	#var wall_size = 15.0 
	#var wall_height = 15.0
	#
	#var walls = [
		#{pos = Vector3(0, wall_height/2, wall_size), size = Vector3(wall_size*2, wall_height, 1)},   # 북쪽 (30 넓이)
		#{pos = Vector3(0, wall_height/2, -wall_size), size = Vector3(wall_size*2, wall_height, 1)},  # 남쪽
		#{pos = Vector3(wall_size, wall_height/2, 0), size = Vector3(1, wall_height, wall_size*2)},   # 동쪽 (30 넓이)
		#{pos = Vector3(-wall_size, wall_height/2, 0), size = Vector3(1, wall_height, wall_size*2)}   # 서쪽
	#]
	#
	#for wall_data in walls:
		#var wall = StaticBody3D.new()
		#wall.name = "InvisibleWall"
		#
		#var collision = CollisionShape3D.new()
		#var shape = BoxShape3D.new()
		#shape.size = wall_data.size
		#collision.shape = shape
		#
		#wall.add_child(collision)
		#wall.position = wall_data.pos
		#
		#add_child(wall)
		
		
extends Node3D

@onready var lobby_ui = preload("res://scenes/LobbyUI.tscn").instantiate()
@onready var game_ui = preload("res://scenes/GameUI.tscn").instantiate()

var local_player_nickname = ""
var local_player_id = 0
var is_trying_to_join = false

func _ready():
	# 로비 UI
	add_child(lobby_ui)
	lobby_ui.start_matchmaking.connect(_on_start_matchmaking)  # 🆕 시그널 변경
	
	# 게임 UI
	add_child(game_ui)
	game_ui.visible = false
	
	# 이벤트 연결
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	NetworkManager.connected_to_server.connect(_on_connected_to_server)  # 🆕 추가
	GameManager.game_started.connect(_on_game_started)
	GameManager.phase_changed.connect(_on_phase_changed)
	
	# 타이머 연결
	GameManager.time_updated.connect(game_ui.update_timer)
	GameManager.prepare_time_updated.connect(game_ui.update_prepare_timer)
	
	# 🆕 Floor 설정
	var floor = $Floor
	if floor:
		floor.position.y = 0.8
		
		var mesh_instance = floor.get_node_or_null("MeshInstance3D")
		if not mesh_instance and floor is MeshInstance3D:
			mesh_instance = floor
		
		if mesh_instance and mesh_instance.mesh is BoxMesh:
			mesh_instance.mesh.size = Vector3(30, 1, 30)
		
		var collision = floor.get_node_or_null("CollisionShape3D")
		if collision and collision.shape is BoxShape3D:
			collision.shape.size = Vector3(30, 1, 30)
	
	setup_water_floor()
	create_invisible_walls()

func _on_start_matchmaking(nickname: String):
	local_player_nickname = nickname
	
	print("🔍 매칭 시작: 먼저 서버 찾기...")
	

	is_trying_to_join = true
	NetworkManager.join_server("127.0.0.1")
	
	# 3초 대기 (서버 있으면 connected_to_server 신호 옴)
	await get_tree().create_timer(3.0).timeout
	
	#3초 안에 접속 안 되면 자동으로 Host
	if is_trying_to_join:
		print("⚠️ 서버 없음 → Host로 전환!")
		NetworkManager.create_server()
		
		await get_tree().create_timer(1.0).timeout
		start_game_ui()
		
		# Host는 다른 플레이어 기다림
		await get_tree().create_timer(5.0).timeout
		
		if multiplayer.is_server():
			GameManager.start_game()

func _on_connected_to_server():
	# 🆕 서버 발견! Join 성공
	is_trying_to_join = false

	
	await get_tree().create_timer(1.0).timeout
	start_game_ui()

func start_game_ui():
	lobby_ui.visible = false
	game_ui.visible = true
	
	spawn_local_player()
	local_player_id = multiplayer.get_unique_id()
	game_ui.add_player(local_player_id, local_player_nickname)

func spawn_local_player():
	var my_id_str = str(multiplayer.get_unique_id())
	
	if $Players.has_node(my_id_str):
		return
	
	print("🔍 플레이어 생성!")
	var player = preload("res://scenes/Player.tscn").instantiate()
	player.name = my_id_str
	player.player_id = multiplayer.get_unique_id()
	player.set_multiplayer_authority(multiplayer.get_unique_id())
	
	player.position = Vector3(randf_range(-12, 12), 1.8, randf_range(-12, 12))
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

func setup_water_floor():
	var floor = $Floor
	if not floor:
		return
	
	var mesh_instance = floor.get_node_or_null("MeshInstance3D")
	if not mesh_instance and floor is MeshInstance3D:
		mesh_instance = floor
	
	if mesh_instance:
		var water_material = StandardMaterial3D.new()
		water_material.albedo_color = Color(0.31, 0.70, 0.85, 0.85)
		water_material.metallic = 0.3
		water_material.metallic_specular = 0.8
		water_material.roughness = 0.2
		water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		mesh_instance.material_override = water_material


func create_invisible_walls():
	var wall_size = 15.0
	var wall_height = 10.0
	
	var walls = [
		{pos = Vector3(0, wall_height/2, wall_size), size = Vector3(wall_size*2, wall_height, 1)},
		{pos = Vector3(0, wall_height/2, -wall_size), size = Vector3(wall_size*2, wall_height, 1)},
		{pos = Vector3(wall_size, wall_height/2, 0), size = Vector3(1, wall_height, wall_size*2)},
		{pos = Vector3(-wall_size, wall_height/2, 0), size = Vector3(1, wall_height, wall_size*2)}
	]
	
	for wall_data in walls:
		var wall = StaticBody3D.new()
		wall.name = "InvisibleWall"
		
		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = wall_data.size
		collision.shape = shape
		
		wall.add_child(collision)
		wall.position = wall_data.pos
		
		add_child(wall)
	
	

	
