extends CanvasLayer

const ACTIONS := {
	"ui_up"    : "Panel/BindingsContainer/MoveUpRow/MoveUpButton",
	"ui_down"  : "Panel/BindingsContainer/MoveDownRow/MoveDownButton",
	"ui_left"  : "Panel/BindingsContainer/MoveLeftRow/MoveLeftButton",
	"ui_right" : "Panel/BindingsContainer/MoveRightRow/MoveRightButton",
	"sprint"   : "Panel/BindingsContainer/SprintRow/SprintButton",
	"interact" : "Panel/BindingsContainer/InteractRow/InteractButton",
}

const DEFAULTS := {
	"ui_up"    : KEY_W,
	"ui_down"  : KEY_S,
	"ui_left"  : KEY_A,
	"ui_right" : KEY_D,
	"sprint"   : KEY_SHIFT,
	"interact" : KEY_E,
}

var _listening_for : String = ""
var _buttons : Dictionary = {}

@onready var reset_button : Button = $Panel/ResetButton
@onready var back_button : Button = $Panel/BackButton
@onready var panel : Control = $Panel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.hide()
 
	# Wire up all binding buttons
	for action in ACTIONS.keys():
		var btn := get_node(ACTIONS[action]) as Button
		_buttons[action] = btn
		btn.pressed.connect(_on_bind_button_pressed.bind(action))
		_refresh_button_label(action)
 
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _input(event: InputEvent) -> void:
	if _listening_for.is_empty():
		return
	# Only accept keyboard input for rebinding
	if event is InputEventKey and event.pressed:
		_rebind(_listening_for, event.keycode)
		_listening_for = ""
		get_viewport().set_input_as_handled()

func show_settings() -> void:
	panel.show()

func hide_settings() -> void:
	panel.hide()
	_listening_for = ""

func _on_bind_button_pressed(action: String) -> void:
	_listening_for = action
	_buttons[action].text = "Press a key..."

func _rebind(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		push_error("Action does not exist: %s" % action)
		return
	# Remove all existing keyboard events for thsi action
	var events := InputMap.action_get_events(action)
	for event in events:
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	# Add new key event
	var new_event := InputEventKey.new()
	new_event.keycode = keycode
	InputMap.action_add_event(action, new_event)
	
	_refresh_button_label(action)

func _refresh_button_label(action: String) -> void:
	var events := InputMap.action_get_events(action)
	for event in events:
		if event is InputEventKey:
			_buttons[action].text = OS.get_keycode_string(event.keycode)
			return
	_buttons[action].text = "Unbound"

func _on_reset_pressed() -> void:
	for action in DEFAULTS.keys():
		# Clear existing keyboard bindings
		var events := InputMap.action_get_events(action)
		for event in events:
			if event is InputEventKey:
				InputMap.action_erase_event(action, event)
		# Add default keys
		var default_event := InputEventKey.new()
		default_event.keycode = DEFAULTS[action]
		InputMap.action_add_event(action, default_event)
		_refresh_button_label(action)

func _on_back_pressed() -> void:
	hide_settings()
	get_parent().show_pause()
