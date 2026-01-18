extends CharacterBody3D

var current_form = "duck"
var is_ai = true
var move_timer = 0.0
var target_position = Vector3.ZERO

func _ready():
	add_to_group("ai")
	set_random_target()

func _physics_process(delta):
	# 오리만 움직임
	if current_form != "duck":
		return
	
	move_timer += delta
	
	# 2-5초마다 새 목표 설정
	if move_timer >= randf_range(2.0, 5.0):
		move_timer = 0.0
		
		# 30% 확률로 멈춤
		if randf() < 0.3:
			velocity = Vector3.ZERO
			return
		
		set_random_target()
	
	# 목표로 이동
	var direction = (target_position - global_position).normalized()
	velocity.x = direction.x * 2.0
	velocity.z = direction.z * 2.0
	
	# 중력
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	
	move_and_slide()
	
	# 목표 근처 도착하면 새 목표
	if global_position.distance_to(target_position) < 1.0:
		set_random_target()

func set_random_target():
	# Ground 안쪽으로만 (바닥 크기 50x50)
	target_position = Vector3(
		randf_range(-20, 20),
		1.0,
		randf_range(-20, 20)
	)

func transform_to(form: String):
	current_form = form
	
	var mesh_node = $MeshInstance3D
	
	match form:
		"duck":
			mesh_node.mesh = CapsuleMesh.new()
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color.YELLOW
			mesh_node.set_surface_override_material(0, mat)
		"bench":
			var box = BoxMesh.new()
			box.size = Vector3(2, 0.5, 1)
			mesh_node.mesh = box
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color.SADDLE_BROWN
			mesh_node.set_surface_override_material(0, mat)
		"trashcan":
			mesh_node.mesh = CylinderMesh.new()
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color.GRAY
			mesh_node.set_surface_override_material(0, mat)
		"rock":
			mesh_node.mesh = SphereMesh.new()
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color.DIM_GRAY
			mesh_node.set_surface_override_material(0, mat)
