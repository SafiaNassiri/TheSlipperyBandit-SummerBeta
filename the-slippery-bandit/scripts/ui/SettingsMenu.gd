extends CanvasLayer

const BUS_MASTER := 0
const BUS_MUSIC := 1
const BUS_SFX := 2

const ACTIONS := {
	"ui_up"    : "Move Up",
	"ui_down"  : "Move Down",
	"ui_left"  : "Move Left",
	"ui_right" : "Move Right",
	"sprint"   : "Sprint",
	"interact" : "Interact",
}

const DEFAULTS := {
	"ui_up"    : KEY_W,
	"ui_down"  : KEY_S,
	"ui_left"  : KEY_A,
	"ui_right" : KEY_D,
	"sprint"   : KEY_SHIFT,
	"interact" : KEY_E,
}

const ARROW_CODES := [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]
const PREFERRED_KEYS := {
	"ui_up": KEY_W,
	"ui_down": KEY_S,
	"ui_left": KEY_A,
	"ui_right": KEY_D,
	"sprint": KEY_SHIFT,
	"interact": KEY_E,
}

@onready var overlay : ColorRect = $Overlay
@onready var window_panel : PanelContainer = $Overlay/Window
@onready var master_slider : HSlider = $Overlay/Window/Layout/TabBar/Audio/MasterRow/MasterSlider
@onready var master_value : Label = $Overlay/Window/Layout/TabBar/Audio/MasterRow/MasterValue
@onready var music_slider : HSlider = $Overlay/Window/Layout/TabBar/Audio/MusicRow/MusicSlider
@onready var music_value : Label = $Overlay/Window/Layout/TabBar/Audio/MusicRow/MusicValue
@onready var sfx_slider : HSlider = $Overlay/Window/Layout/TabBar/Audio/SFXRow/SFXSlider
@onready var sfx_value : Label = $Overlay/Window/Layout/TabBar/Audio/SFXRow/SFXValue
@onready var reset_button : Button = $Overlay/Window/Layout/TabBar/Controls/ResetButton
@onready var back_button : Button = $Overlay/Window/Layout/Header/CloseButton
@onready var apply_button : Button = $Overlay/Window/Layout/Footer/ApplyButton

var _listening_for : String = ""
var _bind_buttons : Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.hide()
	
	_setup_slider(master_slider, master_value, BUS_MASTER)
	_setup_slider(music_slider, music_value, BUS_MUSIC)
	_setup_slider(sfx_slider, sfx_value, BUS_SFX)
	
	master_slider.value_changed.connect(func(v): _on_volume_changed(BUS_MASTER, v, master_value))
	music_slider.value_changed.connect(func(v): _on_volume_changed(BUS_MUSIC, v, music_value))
	sfx_slider.value_changed.connect(func(v): _on_volume_changed(BUS_SFX, v, sfx_value))
	
	_ensure_actions_exist()
	_build_bind_buttons()
	
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)
	apply_button.pressed.connect(_on_apply_pressed)

# HELPER: Create and add a key event to an action
func _add_key_to_action(action: String, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	# Don't set physical_keycode - let Godot figure it out
	InputMap.action_add_event(action, event)
	print("Added %s (%d) to %s" % [OS.get_keycode_string(keycode), keycode, action])

# HELPER: Clear all keyboard events from an action
func _clear_action_keys(action: String) -> void:
	var events := InputMap.action_get_events(action)
	var events_to_remove = []
	# Collect ALL non-gamepad events (keyboard only)
	for event in events:
		if event is InputEventKey:
			events_to_remove.append(event)
	# Remove them
	for event in events_to_remove:
		InputMap.action_erase_event(action, event)
	
	print("Cleared %d keyboard events from %s" % [events_to_remove.size(), action])

func _ensure_actions_exist() -> void:
	for action in DEFAULTS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		
		# Check if the DEFAULT key for this action exists
		var has_default_key = false
		var events = InputMap.action_get_events(action)
		for event in events:
			if event is InputEventKey and event.keycode == DEFAULTS[action]:
				has_default_key = true
				break
		
		# Only add default if this specific key doesn't exist
		if not has_default_key:
			_add_key_to_action(action, DEFAULTS[action])

func _input(event: InputEvent) -> void:
	if _listening_for.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_rebind(_listening_for, event.keycode)
		_listening_for = ""
		get_tree().root.set_input_as_handled()

func show_settings() -> void:
	_ensure_actions_exist()
	_build_bind_buttons()
	overlay.show()
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

func hide_settings() -> void:
	overlay.hide()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_listening_for = ""

# AUDIO
func _setup_slider(slider: HSlider, value_label: Label, bus: int) -> void:
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	var db := AudioServer.get_bus_volume_db(bus)
	var linear := db_to_linear(db) * 100.0
	slider.value = clampf(linear, 0.0, 100.0)
	value_label.text = "%d" % int(slider.value)

func _on_volume_changed(bus: int, value: float, label: Label) -> void:
	label.text = "%d" % int(value)
	AudioServer.set_bus_mute(bus, value == 0.0)
	if value > 0.0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(value / 100.0))

# CONTROLS
func _build_bind_buttons() -> void:
	var controls_tab := $Overlay/Window/Layout/TabBar/Controls
	for child in controls_tab.get_children():
		if child != reset_button:
			child.queue_free()
	
	for action in ACTIONS.keys():
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 40
		
		var lbl := Label.new()
		lbl.text = ACTIONS[action]
		lbl.custom_minimum_size.x = 150
		lbl.add_theme_font_size_override("font_size", 14)
		
		var btn := Button.new()
		btn.custom_minimum_size.x = 100
		btn.custom_minimum_size.y = 35
		btn.pressed.connect(_on_bind_button_pressed.bind(action, btn))
		
		row.add_child(lbl)
		row.add_child(btn)
		controls_tab.add_child(row)
		_bind_buttons[action] = btn
	
	await get_tree().process_frame
	for action in ACTIONS.keys():
		_refresh_button_label(action)

func _on_bind_button_pressed(action: String, btn: Button) -> void:
	_listening_for = action
	btn.text = "Press a key..."

func _rebind(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		push_error("Action does not exist: %s" % action)
		return
	
	print("Rebinding %s to %s (%d)" % [action, OS.get_keycode_string(keycode), keycode])
	_clear_action_keys(action)
	_add_key_to_action(action, keycode)
	
	# Verify it was added
	var events := InputMap.action_get_events(action)
	print("After rebind, events for %s: %s" % [action, events])
	
	_refresh_button_label(action)

func _refresh_button_label(action: String) -> void:
	if not _bind_buttons.has(action):
		return
	
	var events := InputMap.action_get_events(action)
	var key_string := _find_key_string(action, events)
	_bind_buttons[action].text = key_string if key_string else "Unbound"

func _find_key_string(action: String, events: Array) -> String:
	# Check for preferred key first (WASD)
	if action in PREFERRED_KEYS:
		for event in events:
			if event is InputEventKey and event.keycode == PREFERRED_KEYS[action]:
				return OS.get_keycode_string(event.keycode)
	
	# Check for any non-arrow key
	for event in events:
		if event is InputEventKey and event.keycode not in ARROW_CODES:
			return OS.get_keycode_string(event.keycode)
	
	# Fall back to any key (allows arrow keys)
	for event in events:
		if event is InputEventKey:
			return OS.get_keycode_string(event.keycode)
	
	return ""

func _on_reset_pressed() -> void:
	for action in DEFAULTS.keys():
		_clear_action_keys(action)
		_add_key_to_action(action, DEFAULTS[action])
		_refresh_button_label(action)

func _on_back_pressed() -> void:
	hide_settings()
	if get_parent().has_method("show_pause"):
		get_parent().show_pause()

func _on_apply_pressed() -> void:
	hide_settings()
		
	if get_parent().has_method("show_pause"):
		get_parent().show_pause()
