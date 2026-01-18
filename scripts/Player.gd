extends CharacterBody3D

@export var player_id: int = 1
@export var speed: float = 5.0

var role = "hider"
var current_form = "human"
var can_transform = true
var is_frozen = false  # 사물일 때 움직임 제한

@onready var camera = $Camera3D
@onready var mesh = $MeshInstance3D

func _ready():
	if speed == 0 or speed == null:
		speed = 5.0
		
	add_to_group("player") 
	
	set_multiplayer_authority(player_id)
	
	if is_multiplayer_authority():
		camera.current = true
		
		# 변신 UI 연결
		if role == "hider":
			setup_transform_ui()
	else:
		camera.queue_free()
	
	# 게임 단계 이벤트
	GameManager.phase_changed.connect(_on_phase_changed)
#
#func _physics_process(delta):
	#if not is_multiplayer_authority():
		#return
	#
	## 사물로 변신했으면 움직일 수 없음
	#if is_frozen:
		#return
	#
	## 움직임
	#var input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	#velocity.x = input.x * speed
	#velocity.z = input.y * speed
	#
	#move_and_slide()
	#
	## 위치 동기화
	#sync_position.rpc(global_position, rotation.y)
	
	
func _physics_process(delta):
	if not is_multiplayer_authority():
		return
	
	if is_frozen:
		return
	
	# 움직임
	var input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity.x = input.x * speed
	velocity.z = input.y * speed
	
	# 점프 추가!
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = 5.0
	
	# 중력
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	
	move_and_slide()
	
	# 술래일 때 마우스 클릭으로 잡기
	if role == "seeker" and Input.is_action_just_pressed("ui_select"):
		try_catch_player()
	
	sync_position.rpc(global_position, rotation.y)

func try_catch_player():
	# 레이캐스트로 클릭한 플레이어 찾기
	var camera_3d = get_viewport().get_camera_3d()
	if not camera_3d:
		return
	
	var from = camera_3d.project_ray_origin(get_viewport().get_mouse_position())
	var to = from + camera_3d.project_ray_normal(get_viewport().get_mouse_position()) * 100
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	if result:
		var target = result.collider
		if target.is_in_group("player"):
			# 잡았다!
			catch_player.rpc_id(1, target.name)  # 서버에게 알림

@rpc("any_peer", "call_remote")
func catch_player(target_name: String):
	if not multiplayer.is_server():
		return
	
	# TODO: 잡기 처리
	print("Caught: ", target_name)

@rpc("any_peer", "unreliable")
func sync_position(pos: Vector3, rot_y: float):
	if is_multiplayer_authority():
		return
	global_position = pos
	rotation.y = rot_y

func set_role(new_role: String):
	role = new_role
	if role == "seeker":
		mesh.get_active_material(0).albedo_color = Color.RED

func _on_phase_changed(phase):
	if phase == GameManager.Phase.PREPARE and role == "hider":
		can_transform = true
	elif phase == GameManager.Phase.PLAYING:
		can_transform = false

func transform_to(form: String):
	current_form = form
	
	# 모델 변경
	match form:
		"human":
			mesh.mesh = CapsuleMesh.new()
			mesh.get_active_material(0).albedo_color = Color.WHITE
			is_frozen = false
		"duck":
			#mesh.mesh = CapsuleMesh.new()
			#mesh.get_active_material(0).albedo_color = Color.YELLOW
			#is_frozen = false
			var scene = load("res://models/call_duck.glb")
			mesh = scene.instantiate()
			add_child(mesh)
		"bench":
			mesh.mesh = BoxMesh.new()
			mesh.mesh.size = Vector3(2, 0.5, 1)
			mesh.get_active_material(0).albedo_color = Color.SADDLE_BROWN
			is_frozen = true
		"trashcan":
			mesh.mesh = CylinderMesh.new()
			mesh.get_active_material(0).albedo_color = Color.GRAY
			is_frozen = true
			#ss
		"rock":
			mesh.mesh = SphereMesh.new()
			mesh.get_active_material(0).albedo_color = Color.DIM_GRAY
			is_frozen = true
	
	# 동기화
	sync_transform.rpc(form)

@rpc("any_peer", "call_local")
func sync_transform(form: String):
	if is_multiplayer_authority():
		return
	transform_to(form)

func setup_transform_ui():
	# 변신 UI는 나중에 추가
	pass
