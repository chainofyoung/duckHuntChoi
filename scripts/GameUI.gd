extends Control

@onready var player_list = $PanelContainer/VBoxContainer/PlayerList
@onready var seeker_label = $SeekerLabel
@onready var timer_label = $TimerLabel
@onready var hint_arrow = $HintArrow
@onready var transform_panel = $TransformPanel

signal transform_requested(form)

func _ready():
	GameManager.phase_changed.connect(_on_phase_changed)
	GameManager.hint_triggered.connect(_on_hint_triggered)
	
	# 변신 버튼 연결
	if transform_panel and transform_panel.has_node("HBoxContainer"):
		$TransformPanel/HBoxContainer/DuckButton.pressed.connect(func(): transform_requested.emit("duck"))
		$TransformPanel/HBoxContainer/BenchButton.pressed.connect(func(): transform_requested.emit("bench"))
		$TransformPanel/HBoxContainer/TrashButton.pressed.connect(func(): transform_requested.emit("trashcan"))

# 타이머 업데이트 함수 추가!
func update_timer(seconds: int):
	if not timer_label:
		return
	
	var minutes = seconds / 60
	var secs = seconds % 60
	timer_label.text = "남은 시간: %d:%02d" % [minutes, secs]

func update_prepare_timer(seconds: int):
	if not timer_label:
		return
	
	timer_label.text = "준비: %d초" % seconds

func add_player(id: int, nickname: String, is_seeker: bool = false):
	var label = Label.new()
	label.name = "Player_" + str(id)
	
	if is_seeker:
		label.text = "🔍 " + nickname + " (술래)"
		label.add_theme_color_override("font_color", Color.RED)
	else:
		label.text = "🦆 " + nickname
	
	player_list.add_child(label)

func remove_player(id: int):
	var label = player_list.get_node_or_null("Player_" + str(id))
	if label:
		label.queue_free()

func update_seeker(nickname: String):
	seeker_label.text = "🔍 술래: " + nickname
	seeker_label.visible = true

func _on_phase_changed(phase):
	if not timer_label or not transform_panel:
		return
	
	match phase:
		GameManager.Phase.PREPARE:
			timer_label.text = "준비: 30초"
			if transform_panel:
				transform_panel.visible = true
		GameManager.Phase.PLAYING:
			timer_label.text = "남은 시간: 3:00"
			if transform_panel:
				transform_panel.visible = false

func _on_hint_triggered(direction: Vector3):
	if not hint_arrow:
		return
	
	hint_arrow.visible = true
	hint_arrow.rotation = Vector2(direction.x, direction.z).angle()
	
	await get_tree().create_timer(3.0).timeout
	hint_arrow.visible = false

func clear_players():
	for child in player_list.get_children():
		child.queue_free()
