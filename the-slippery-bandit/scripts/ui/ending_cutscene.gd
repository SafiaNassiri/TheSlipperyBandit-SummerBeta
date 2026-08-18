extends Node2D

@onready var textbox = $TextBox

var dialogue = [
	"[CLOTHING STORE]",
	"",
	"Rutabaga slides up to the counter\nwith his butter collection.",
	"",
	"CLERK: \"Sir... that's not money.\"",
	"",
	"[Rutabaga looks at the butter.\nThen at the jacket.]",
	"",
	"[He sets down the butter.\nPicks up the jacket.\nSlides out smoothly.]",
	"",
	"THE END"
]

var current_line = 0

func _ready() -> void:
	show_line()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		next_line()

func show_line() -> void:
	if current_line < dialogue.size():
		textbox.text = dialogue[current_line]
	else:
		# Go to main menu or credits
		get_tree().change_scene_to_file("res://scenes/menu.tscn")

func next_line() -> void:
	current_line += 1
	show_line()
