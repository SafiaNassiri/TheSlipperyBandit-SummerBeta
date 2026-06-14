extends Control

# Flavour lines — picks one randomly
const CAUGHT_LINES: Array[String] = [
	"The VACooms wins this round.",
	"Rutabaga did not escape.",
	"The gold bars were not worth it.\n(They were never gold bars.)",
	"The VACooms has no mercy.",
	"You slid directly into it. Impressive.",
]

@onready var subtitle_label : Label  = $SubtitleLabel
@onready var retry_button   : Button = $ButtonContainer/RetryButton
@onready var menu_button    : Button = $ButtonContainer/MainMenuButton

func _ready() -> void:
	subtitle_label.text = CAUGHT_LINES[randi() % CAUGHT_LINES.size()]

	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _on_retry_pressed() -> void:
	GameManager.start_level(GameManager.current_level)

func _on_menu_pressed() -> void:
	GameManager.go_to_main_menu()
