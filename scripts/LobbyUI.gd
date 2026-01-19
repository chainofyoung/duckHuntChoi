#extends Control
#
#@onready var nickname_input = $VBoxContainer/LineEdit
#@onready var start_button = $VBoxContainer/Button
#@onready var matching_label = $MatchingLabel
#
#var dots = 0
#
#signal start_game_requested(nickname)
#
#func _ready():
	#start_button.pressed.connect(_on_start_pressed)
#
#func _on_start_pressed():
	#var nickname = nickname_input.text.strip_edges()
	#
	#if nickname == "":
		#nickname = "Player" + str(randi() % 1000)
	#
	## UI 전환
	#$VBoxContainer.visible = false
	#matching_label.visible = true
	#
	## 매칭 애니메이션
	#start_matching_animation()
	#
	#emit_signal("start_game_requested", nickname)
#
#func start_matching_animation():
	#var timer = Timer.new()
	#add_child(timer)
	#timer.wait_time = 0.5
	#timer.timeout.connect(_update_dots)
	#timer.start()
#
#func _update_dots():
	#dots = (dots + 1) % 4
	#matching_label.text = "매칭 중" + ".".repeat(dots)


extends Control

@onready var nickname_input = $VBoxContainer/LineEdit
@onready var start_button = $VBoxContainer/Button
@onready var matching_label = $MatchingLabel

var dots = 0
signal start_matchmaking(nickname)

func _ready():
	start_button.text = "매칭 시작" 
	start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed():
	var nickname = nickname_input.text.strip_edges()
	if nickname == "":
		nickname = "Player" + str(randi() % 1000)
	
	$VBoxContainer.visible = false
	matching_label.visible = true
	start_matching_animation()
	
	emit_signal("start_matchmaking", nickname)

func start_matching_animation():
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.5
	timer.timeout.connect(_update_dots)
	timer.start()

func _update_dots():
	dots = (dots + 1) % 4
	matching_label.text = "매칭 중" + ".".repeat(dots)
