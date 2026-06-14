extends Control

const FLAVOR_LINES: Array[String] = [
	"Rutabaga tallies his gold bars.\nThey are not gold bars.",
	"Another successful operation.",
	"The jacket is getting closer.",
	"Nobody saw a thing.\n(The VACooms saw everything.)",
	"Rutabaga is very smart and good at crimes.",
]

@onready var butter_label     : Label  = $StatsContainer/ButterLabel
@onready var secret_label     : Label  = $StatsContainer/SecretLabel
@onready var flavor_label     : Label  = $SubtitleLabel
@onready var next_btn         : Button = $ButtonContainer/NextLevelButton
@onready var replay_btn       : Button = $ButtonContainer/ReplayButton
@onready var menu_btn         : Button = $ButtonContainer/MainMenuButton

func _ready() -> void:
	butter_label.text = "Butter collected: %d / %d" % [
		GameManager.butter_collected,
		GameManager.butter_total
	]
	secret_label.text = "Secret found: %s" % ("✓" if GameManager.secret_found else "✗")
	flavor_label.text = FLAVOR_LINES[randi() % FLAVOR_LINES.size()]

	# Hide Next Level button if this was the last level
	var is_final_level: bool = GameManager.current_level >= GameManager.total_levels
	next_btn.visible = not is_final_level

	next_btn.pressed.connect(_on_next_pressed)
	replay_btn.pressed.connect(_on_replay_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)

func _on_next_pressed() -> void:
	GameManager.start_level(GameManager.current_level + 1)

func _on_replay_pressed() -> void:
	GameManager.start_level(GameManager.current_level)

func _on_menu_pressed() -> void:
	GameManager.go_to_main_menu()
