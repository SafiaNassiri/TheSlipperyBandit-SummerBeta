extends CanvasLayer

@onready var panel          : Control = $Panel
@onready var resume_button  : Button  = $Panel/ButtonContainer/ResumeButton
@onready var restart_button : Button  = $Panel/ButtonContainer/RestartButton
@onready var menu_button    : Button  = $Panel/ButtonContainer/MainMenuButton

var is_paused: bool = false

func _ready() -> void:
	panel.hide()
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
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

func _on_restart_pressed() -> void:
	get_tree().paused = false
	GameManager.start_level(GameManager.current_level)

func _on_menu_pressed() -> void:
	GameManager.go_to_main_menu()

func show_pause() -> void:
	_pause()
