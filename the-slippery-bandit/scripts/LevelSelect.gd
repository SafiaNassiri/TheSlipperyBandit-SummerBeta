extends Control

@onready var level_grid  : GridContainer = $LevelGrid
@onready var back_button : Button        = $BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_build_level_buttons()

func _build_level_buttons() -> void:
	for i in range(1, GameManager.total_levels + 1):
		var btn := Button.new()

		if i in GameManager.unlocked_levels:
			btn.text = "Home %d" % i
			btn.disabled = false
			var level_index := i
			btn.pressed.connect(func(): GameManager.start_level(level_index))
		else:
			btn.text = "Home %d\n[Locked]" % i
			btn.disabled = true

		level_grid.add_child(btn)

func _on_back_pressed() -> void:
	GameManager.go_to_main_menu()
