extends Node2D

@onready var textbox = $TextBox
@onready var timer = $Timer

var text_content: String = ""
var duration: float = 3.0
var next_level: int = 2
var can_skip: bool = false

func _ready() -> void:
	# Clear input buffer from previous scene
	get_tree().root.set_input_as_handled()
	
	# Delay allowing skips
	await get_tree().process_frame
	await get_tree().process_frame
	can_skip = true
	print("Cutscene ready, can_skip = true")

func setup(text: String, dur: float, level: int = 2) -> void:
	text_content = text
	duration = dur
	next_level = level
	textbox.text = text_content
	print("Cutscene setup called: ", text_content, " duration: ", dur, " next_level: ", next_level)
	
	if duration > 0:
		timer.start(duration)

func _input(event: InputEvent) -> void:
	# print("Input event: ", event, " can_skip: ", can_skip)
	if can_skip and event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			print("Skipping cutscene!")
			advance_to_next_scene()

func advance_to_next_scene() -> void:
	print("Advancing to level ", next_level)
	var next_scene = "res://scenes/levels/Level%d.tscn" % next_level
	get_tree().change_scene_to_file(next_scene)

func _on_timer_timeout() -> void:
	advance_to_next_scene()
