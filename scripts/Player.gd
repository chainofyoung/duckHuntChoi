extends CharacterBody3D

@export var player_id: int = 1
@export var speed: float = 5.0
@export var rotation_speed: float = 10.0

var role = "hider"
var current_form = "human"
var can_transform = true
var is_frozen = false

@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D
@onready var model_container = $ModelContainer

var mouse_sensitivity = 0.003  # 조금 더 민감하게
var camera_distance = 5.0

# 우클릭 카메라 회전용
var is_rotating_camera = false

# 모바일 조이스틱 참조
var virtual_joystick = null
var jump_button = null

var bob_timer = 0.0


func _ready():
	add_to_group("player")
	
	if speed == 0 or speed == null:
		speed = 5.0
	
	set_multiplayer_authority(player_id)
	
	if is_multiplayer_authority():
		camera.current = true
		# 🆕 마우스 항상 보이게
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		load_model_for_role()
		
		call_deferred("_find_mobile_controls")
	else:
		camera_pivot.queue_free()
		load_model_for_role()
	
	GameManager.phase_changed.connect(_on_phase_changed)

func _find_mobile_controls():
	virtual_joystick = get_node_or_null("/root/Game/UI/VirtualJoystick")
	jump_button = get_node_or_null("/root/Game/UI/JumpButton")



func _input(event):
	if not is_multiplayer_authority():
		return
	
	# 우클릭으로 카메라 회전 모드 ON/OFF
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_rotating_camera = event.pressed
		
		# 🆕 좌클릭으로 잡기
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if role == "seeker" and not is_rotating_camera:
				try_catch_player()
	
	# 우클릭 누르고 있을 때만 마우스 움직임으로 카메라 회전
	if event is InputEventMouseMotion and is_rotating_camera:
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -1.3, 0.3)
		
		


func _physics_process(delta):
	if not is_multiplayer_authority():
		return
	
	if is_frozen:
		return
		
	if role != "seeker":
		bob_timer += delta * 2.0
		var bob_offset = sin(bob_timer) * 0.1
		model_container.position.y = bob_offset  
	else:
		model_container.position.y = 0
	
	var input_dir = _get_input_direction()
	
	var cam_basis = camera_pivot.global_transform.basis
	var cam_forward = -cam_basis.z
	var cam_right = cam_basis.x
	
	cam_forward.y = 0
	cam_right.y = 0
	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()
	
	var direction = (cam_forward * input_dir.y + cam_right * input_dir.x).normalized()
	
	if direction.length() > 0.1:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		var target_angle = atan2(direction.x, direction.z)
		model_container.rotation.y = lerp_angle(model_container.rotation.y, target_angle, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	if _is_jump_pressed() and is_on_floor():
		velocity.y = 5.0
	
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	
	move_and_slide()
	
	
	sync_position.rpc(global_position, model_container.rotation.y)
	
	

# 통합 입력 - PC는 WASD 사용
func _get_input_direction() -> Vector2:
	# 모바일: 조이스틱 우선
	if OS.has_feature("mobile") and virtual_joystick:
		var joy_input = virtual_joystick.get_value()
		if joy_input.length() > 0.1:
			return joy_input
	
	# PC: WASD 직접 체크
	var input = Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		input.y += 1
	if Input.is_key_pressed(KEY_S):
		input.y -= 1
	if Input.is_key_pressed(KEY_A):
		input.x -= 1
	if Input.is_key_pressed(KEY_D):
		input.x += 1
	
	return input.normalized()

func _is_jump_pressed() -> bool:
	# 모바일: 점프 버튼
	if OS.has_feature("mobile") and jump_button and jump_button.is_pressed():
		return true
	
	# PC: 스페이스바
	return Input.is_key_pressed(KEY_SPACE)

@rpc("any_peer", "unreliable")
func sync_position(pos: Vector3, rot_y: float):
	if is_multiplayer_authority():
		return
	global_position = pos
	model_container.rotation.y = rot_y

func set_role(new_role: String):
	role = new_role
	load_model_for_role()

			
#
func load_model_for_role():
	for child in model_container.get_children():
		model_container.remove_child(child)
		child.queue_free()
	
	await get_tree().process_frame
	
	var model_scene
	
	if role == "seeker":
		print("술래 모델 로드 중...")
		model_scene = load("res://models/characterMedium.fbx")
	else:
		print("오리 모델 로드 중...")
		model_scene = load("res://models/call_duck.glb")
	
	if model_scene:
		var model = model_scene.instantiate()
		model_container.add_child(model)
		
		print("모델 추가됨: ", model.name)
		
		#크기
		model.scale = Vector3(0.8, 0.8, 0.8)  # 둘 다 0.8
		model.position = Vector3.ZERO
	else:
		print("모델 로드 실패!")
		
		

func _on_phase_changed(phase):
	if phase == GameManager.Phase.PREPARE and role == "hider":
		can_transform = true
	elif phase == GameManager.Phase.PLAYING:
		can_transform = false

func transform_to(form: String):
	current_form = form
	
	if form != "duck":
		for child in model_container.get_children():
			child.queue_free()
		
		var mesh = MeshInstance3D.new()
		var material = StandardMaterial3D.new()
		
		match form:
			"bench":
				var box = BoxMesh.new()
				box.size = Vector3(2, 0.5, 1)
				mesh.mesh = box
				material.albedo_color = Color.SADDLE_BROWN
				is_frozen = true
			"trashcan":
				mesh.mesh = CylinderMesh.new()
				material.albedo_color = Color.GRAY
				is_frozen = true
			"rock":
				mesh.mesh = SphereMesh.new()
				material.albedo_color = Color.DIM_GRAY
				is_frozen = true
		
		mesh.set_surface_override_material(0, material)
		model_container.add_child(mesh)
	else:
		is_frozen = false
		load_model_for_role()
	
	sync_transform.rpc(form)

@rpc("any_peer", "call_local")
func sync_transform(form: String):
	if is_multiplayer_authority():
		return
	transform_to(form)

func try_catch_player():
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
			catch_player.rpc_id(1, target.name)

@rpc("any_peer", "call_remote")
func catch_player(target_name: String):
	if not multiplayer.is_server():
		return
	print("Caught: ", target_name)
