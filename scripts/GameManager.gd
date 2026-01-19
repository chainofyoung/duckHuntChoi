extends Node

enum Phase { LOBBY, PREPARE, PLAYING, RESULTS }

var current_phase = Phase.LOBBY
var seeker_id = -1
var ai_players = []
var time_remaining = 180
var prepare_time = 30
var hint_timer = 0

signal phase_changed(phase)
signal game_started(seeker_id)
signal hint_triggered(direction)
signal time_updated(seconds) 
signal prepare_time_updated(seconds) 


func _ready():
	if multiplayer.is_server():
		NetworkManager.player_connected.connect(_on_player_connected)
		
		# 테스트: 5초 후 자동 시작
		#await get_tree().create_timer(5.0).timeout
		#if NetworkManager.get_player_count() == 1:
			#print("테스트 모드: AI만으로 시작")
			#start_game()


func _process(delta):
	if not multiplayer.is_server() or current_phase != Phase.PLAYING:
		return
	
	# 힌트 타이머 (30초마다)
	hint_timer += delta
	if hint_timer >= 30.0:
		hint_timer = 0
		give_hint_to_seeker()



func _on_player_connected(id):
	#if NetworkManager.get_player_count() >= 3 and current_phase == Phase.LOBBY:
		#await get_tree().create_timer(5.0).timeout
		#start_game()
		
	if NetworkManager.get_player_count() >= 2 and current_phase == Phase.LOBBY:
		await get_tree().create_timer(5.0).timeout
		start_game()

#func start_game():
	#if not multiplayer.is_server():
		#return
	#
	#print("🎮 Starting game!")
	#
	## 술래 선정
	#var player_ids = NetworkManager.players.keys()
	#player_ids.append(1)
	#seeker_id = player_ids.pick_random()
	#
	## AI 생성
	#spawn_ai_players(20)
	#
	## 준비 단계
	#current_phase = Phase.PREPARE
	#prepare_time = 30
	#rpc("set_phase", Phase.PREPARE, seeker_id)
	#emit_signal("phase_changed", Phase.PREPARE)
	#emit_signal("game_started", seeker_id)
	#
	## 준비 타이머
	#start_prepare_timer()
	
func start_game():
	if not multiplayer.is_server():
		return
	
	print("게임시작#@#@#!")
	
	# 술래 선정
	var player_ids = NetworkManager.players.keys()
	player_ids.append(1)
	seeker_id = player_ids.pick_random()
	
	# 모든 플레이어에게 역할 할당
	for pid in player_ids:
		if pid == seeker_id:
			assign_role.rpc_id(pid, "seeker")
		else:
			assign_role.rpc_id(pid, "hider")
	
	# AI 생성
	spawn_ai_players(80)
	
	# 준비 단계
	current_phase = Phase.PREPARE
	prepare_time = 30
	rpc("set_phase", Phase.PREPARE, seeker_id)
	emit_signal("phase_changed", Phase.PREPARE)
	emit_signal("game_started", seeker_id)
	
	start_prepare_timer()

func start_prepare_timer():
	var timer = Timer.new()
	add_child(timer)
	timer.add_to_group("prepare_timer")  
	timer.wait_time = 1.0
	timer.timeout.connect(_on_prepare_tick)
	timer.start()

func _on_prepare_tick():
	if not multiplayer.is_server():
		return
	
	prepare_time -= 1
	rpc("update_prepare_time", prepare_time)
	
	if prepare_time <= 0:
		var timers = get_tree().get_nodes_in_group("prepare_timer")
		for t in timers:
			t.queue_free()
		start_playing()

func start_playing():
	if not multiplayer.is_server():
		return
	
	current_phase = Phase.PLAYING
	time_remaining = 180
	hint_timer = 0
	
	rpc("set_phase", Phase.PLAYING, seeker_id)
	emit_signal("phase_changed", Phase.PLAYING)
	
	# 게임 타이머
	start_game_timer()

func start_game_timer():
	var timer = Timer.new()
	timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	add_child(timer)
	timer.add_to_group("game_timer")
	timer.wait_time = 1.0
	timer.timeout.connect(_on_game_tick)
	timer.start()

func _on_game_tick():
	if not multiplayer.is_server():
		return
	
	time_remaining -= 1
	rpc("update_time", time_remaining)
	
	if time_remaining <= 0:
		end_game("hiders")


func spawn_ai_players(count: int):
	for i in range(count):
		var ai = preload("res://scenes/AIPlayer.tscn").instantiate()
		ai.name = "AI_" + str(i)
		ai.position = Vector3(randf_range(-12, 12), 1.8, randf_range(-12, 12))  # 🆕 y=1.8
		
		get_tree().root.get_node("Main/Players").add_child(ai)
		ai_players.append(ai)
		
		var forms = ["duck", "duck", "duck", "duck", "duck", "duck", "bench", "trashcan", "rock"]
		ai.transform_to(forms.pick_random())
		

func give_hint_to_seeker():
	# 술래 위치 찾기
	var seeker_pos = Vector3.ZERO
	var seeker_node = get_tree().root.get_node_or_null("Main/Players/" + str(seeker_id))
	if seeker_node:
		seeker_pos = seeker_node.global_position
	
	# 가장 가까운 진짜 플레이어 찾기
	var closest_player = null
	var closest_dist = 999999.0
	
	for player_id in NetworkManager.players.keys():
		if player_id == seeker_id:
			continue
		
		var player_node = get_tree().root.get_node_or_null("Main/Players/" + str(player_id))
		if player_node:
			var dist = seeker_pos.distance_to(player_node.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest_player = player_node
	
	if closest_player:
		var direction = (closest_player.global_position - seeker_pos).normalized()
		rpc("show_hint", direction)

func end_game(winner: String):
	current_phase = Phase.RESULTS
	rpc("show_results", winner)

@rpc("authority", "call_local")
func set_phase(phase: int, new_seeker_id: int):
	current_phase = phase
	seeker_id = new_seeker_id
	emit_signal("phase_changed", phase)

@rpc("authority", "call_local")
func update_time(time: int):
	time_remaining = time
	emit_signal("time_updated", time)

@rpc("authority", "call_local")
func update_prepare_time(time: int):
	prepare_time = time
	emit_signal("prepare_time_updated", time)

@rpc("authority", "call_local")
func show_hint(direction: Vector3):
	emit_signal("hint_triggered", direction)

@rpc("authority", "call_local")
func show_results(winner: String):
	print("Game over! Winner: ", winner)

#@rpc("authority", "call_remote")
#func assign_role(new_role: String):
	#var player_node = get_tree().root.get_node("Main/Players/" + str(multiplayer.get_unique_id()))
	#if player_node:
		#player_node.set_role(new_role)

@rpc("authority", "call_remote")
func assign_role(new_role: String):
	var player_node = get_tree().root.get_node("Main/Players/" + str(multiplayer.get_unique_id()))
	if player_node:
		player_node.set_role(new_role)
