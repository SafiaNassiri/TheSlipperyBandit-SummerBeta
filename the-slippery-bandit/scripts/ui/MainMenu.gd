extends Control

@onready var play_button : Button = $ButtonContainer/PlayButton
@onready var settings_button : Button = $ButtonContainer/SettingsButton
@onready var level_select_button : Button = $ButtonContainer/LevelSelectButton
@onready var quit_button : Button = $ButtonContainer/QuitButton
@onready var settings_menu = $SettingsMenu

func _ready() -> void:
	get_tree().paused = false

	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	level_select_button.pressed.connect(_on_level_select_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	GameManager.start_level(1)

func _on_settings_pressed() -> void:
	settings_menu.show_settings()

func _on_level_select_pressed() -> void:
	GameManager.go_to_level_select()

func _on_quit_pressed() -> void:
	GameManager.quit_game()
