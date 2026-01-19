extends CharacterBody3D

var current_form = "duck"
var is_ai = true
var move_timer = 0.0
var target_position = Vector3.ZERO
var is_moving = true  # 움직임 사 ㅇ태 

#물결
var bob_timer = 0.0
var bob_speed = 2.0  # 둥실 속도
var bob_height = 0.1  # 둥실 높이

@onready var model_container = $ModelContainer

func _ready():
	add_to_group("ai")
	load_duck_model()
	set_random_target()

#func load_duck_model():
	#for child in model_container.get_children():
		#child.queue_free()
	#
	#var duck_scene = load("res://models/call_duck.glb")
	#if duck_scene:
		#var duck = duck_scene.instantiate()
		#duck.scale = Vector3(3.0, 3.0, 3.0) 
		#model_container.add_child(duck)

func load_duck_model():
	for child in model_container.get_children():
		child.queue_free()
	
	var duck_scene = load("res://models/call_duck.glb")
	if duck_scene:
		var duck = duck_scene.instantiate()
		duck.scale = Vector3(0.8, 0.8, 0.8)  
		model_container.add_child(duck)

func _physics_process(delta):
	if current_form != "duck":
		velocity = Vector3.ZERO
		move_and_slide()
		return
	
	# 둥실둥실 효과
	bob_timer += delta * bob_speed
	var bob_offset = sin(bob_timer) * bob_height
	
	move_timer += delta
	
	if move_timer >= randf_range(2.0, 5.0):
		move_timer = 0.0
		
		if randf() < 0.3:
			is_moving = false
			velocity = Vector3.ZERO
		else:
			is_moving = true
			set_random_target()
	
	if is_moving:
		var direction = (target_position - global_position)
		direction.y = 0
		direction = direction.normalized()
		
		if direction.length() > 0.1:
			velocity.x = direction.x * 2.0
			velocity.z = direction.z * 2.0
			
			var target_angle = atan2(direction.x, direction.z)
			model_container.rotation.y = lerp_angle(
				model_container.rotation.y, 
				target_angle, 
				5.0 * delta
			)
	else:
		velocity.x = move_toward(velocity.x, 0, 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 5.0 * delta)
	
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	
	move_and_slide()
	
	model_container.position.y = bob_offset
	
	if global_position.distance_to(target_position) < 1.5:
		move_timer = 0
		if randf() < 0.5:
			is_moving = false
		else:
			set_random_target()

func set_random_target():
	target_position = Vector3(
		randf_range(-12, 12),  
		1.8, 
		randf_range(-12, 12)
	)



func transform_to(form: String):
	current_form = form
	
	for child in model_container.get_children():
		child.queue_free()
	
	if form == "duck":
		load_duck_model()
	else:
		# 사물로 변신하면 움직임 멈춤
		is_moving = false
		velocity = Vector3.ZERO
		
		var mesh = MeshInstance3D.new()
		var material = StandardMaterial3D.new()
		
		match form:
			"bench":
				var box = BoxMesh.new()
				box.size = Vector3(2, 0.5, 1)
				mesh.mesh = box
				material.albedo_color = Color.SADDLE_BROWN
			"trashcan":
				mesh.mesh = CylinderMesh.new()
				material.albedo_color = Color.GRAY
			"rock":
				mesh.mesh = SphereMesh.new()
				material.albedo_color = Color.DIM_GRAY
		
		mesh.set_surface_override_material(0, material)
		model_container.add_child(mesh)
