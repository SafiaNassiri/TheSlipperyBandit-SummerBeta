extends CanvasLayer

@onready var panel : Control = $Panel
@onready var resume_button : Button = $Panel/ButtonContainer/ResumeButton
@onready var restart_button : Button = $Panel/ButtonContainer/RestartButton
@onready var settings_button : Button = $Panel/ButtonContainer/SettingsButton
@onready var menu_button : Button  = $Panel/ButtonContainer/MainMenuButton
@onready var settings_menu = $SettingsMenu

var is_paused: bool = false
var settings_open := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.hide()
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _unhandled_input(event: InputEvent) -> void:
	print(event)
		
	if event.is_action_pressed("ui_cancel"):
		# If settings is open -> close settings first
		if settings_open:
			settings_open = false
			settings_menu.hide_settings()
			panel.show()
			return
		
		# otherwise toggle pause normally
		if is_paused:
			_on_resume_pressed()
		else:
			_pause()

func _pause() -> void:
	is_paused = true
	get_tree().paused = true
	panel.show()

func _on_resume_pressed() -> void:
	is_paused = false
	get_tree().paused = false
	panel.hide()
	settings_menu.hide_settings()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	GameManager.start_level(GameManager.current_level)

func _on_settings_pressed() -> void:
	settings_open = true
	panel.hide()
	settings_menu.show_settings()

func _on_menu_pressed() -> void:
	GameManager.go_to_main_menu()

func show_pause() -> void:
	_pause()
