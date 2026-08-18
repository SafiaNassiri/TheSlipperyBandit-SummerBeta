extends Node2D

@onready var textbox = $TextBox
@onready var timer = $Timer

var text_content: String = ""
var duration: float = 3.0

func _ready() -> void:
	# If called from cutscene manager
	pass

func setup(text: String, dur: float) -> void:
	text_content = text
	duration = dur
	textbox.text = text_content
	
	if duration > 0:
		timer.start(duration)
	else:
		# Wait for player input
		pass

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		advance_to_next_scene()

func advance_to_next_scene() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level_2.tscn")  # or next level

func _on_timer_timeout() -> void:
	advance_to_next_scene()
