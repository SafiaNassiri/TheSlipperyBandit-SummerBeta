extends CanvasLayer

const CONFIG_FILE_PATH = "user://keybinds.cfg"
const VOLUME_CONFIG_PATH = "user://volume.cfg"

var config = ConfigFile.new()
var volume_config = ConfigFile.new()

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
	print("Keybinds saved at: ", ProjectSettings.globalize_path(CONFIG_FILE_PATH))
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.hide()
	
	# Load saved keybinds and volumes FIRST
	_load_keybinds()
	_load_volumes()
	
	# Setup audio
	_setup_slider(master_slider, master_value, BUS_MASTER)
	_setup_slider(music_slider, music_value, BUS_MUSIC)
	_setup_slider(sfx_slider, sfx_value, BUS_SFX)
	
	master_slider.value_changed.connect(func(v): _on_volume_changed(BUS_MASTER, v, master_value))
	music_slider.value_changed.connect(func(v): _on_volume_changed(BUS_MUSIC, v, music_value))
	sfx_slider.value_changed.connect(func(v): _on_volume_changed(BUS_SFX, v, sfx_value))
	
	# Only add defaults if config file doesn't exist
	var config_exists = config.load(CONFIG_FILE_PATH) == OK
	if not config_exists:
		_ensure_actions_exist()
	
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
	var keys_to_remove = []
	
	# Collect ALL keyboard events (including defaults)
	for event in events:
		if event is InputEventKey:
			keys_to_remove.append(event)
	
	# Remove all keyboard events
	for event in keys_to_remove:
		InputMap.action_erase_event(action, event)
	
	print("Cleared %d keyboard events from %s" % [keys_to_remove.size(), action])

func _ensure_actions_exist() -> void:
	for action in DEFAULTS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		
		# Always clear and re-add defaults on first load
		_clear_action_keys(action)
		_add_key_to_action(action, DEFAULTS[action])

func _load_keybinds() -> void:
	if config.load(CONFIG_FILE_PATH) != OK:
		print("No keybinds config found, using defaults")
		return
	
	print("Loading keybinds from config...")
	for action in DEFAULTS.keys():
		if config.has_section_key("keybinds", action):
			var keycode = config.get_value("keybinds", action)
			print("Loading %s: %s (%d)" % [action, OS.get_keycode_string(keycode), keycode])
			
			# Clear ALL existing keys for this action (including defaults)
			_clear_action_keys(action)
			
			# Add only the saved key
			_add_key_to_action(action, keycode)

func _save_keybinds() -> void:
	# Clear the old keybinds section completely
	if config.has_section("keybinds"):
		config.erase_section("keybinds")
	
	# Save all current keybinds fresh
	for action in DEFAULTS.keys():
		var events = InputMap.action_get_events(action)
		for event in events:
			if event is InputEventKey:
				config.set_value("keybinds", action, event.keycode)
				print("Saving %s: %s (%d)" % [action, OS.get_keycode_string(event.keycode), event.keycode])
				break
	
	config.save(CONFIG_FILE_PATH)
	print("Keybinds saved to file")

func _input(event: InputEvent) -> void:
	if _listening_for.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_rebind(_listening_for, event.keycode)
		_listening_for = ""
		get_tree().root.set_input_as_handled()

func show_settings() -> void:
	# Load saved keybinds (without adding defaults on top)
	_load_keybinds()
	
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

func _load_volumes() -> void:
	if volume_config.load(VOLUME_CONFIG_PATH) != OK:
		print("No volume config found, using defaults")
		return
	
	print("Loading saved volumes...")
	
	# Load Master
	if volume_config.has_section_key("volumes", "master"):
		var val = volume_config.get_value("volumes", "master")
		master_slider.value = val
		_on_volume_changed(BUS_MASTER, val, master_value)
	
	# Load Music
	if volume_config.has_section_key("volumes", "music"):
		var val = volume_config.get_value("volumes", "music")
		music_slider.value = val
		_on_volume_changed(BUS_MUSIC, val, music_value)
	
	# Load SFX
	if volume_config.has_section_key("volumes", "sfx"):
		var val = volume_config.get_value("volumes", "sfx")
		sfx_slider.value = val
		_on_volume_changed(BUS_SFX, val, sfx_value)

func _save_volumes() -> void:
	# Clear old section
	if volume_config.has_section("volumes"):
		volume_config.erase_section("volumes")
	
	# Save all volumes
	volume_config.set_value("volumes", "master", master_slider.value)
	volume_config.set_value("volumes", "music", music_slider.value)
	volume_config.set_value("volumes", "sfx", sfx_slider.value)
	
	volume_config.save(VOLUME_CONFIG_PATH)
	print("Volumes saved: Master=%d, Music=%d, SFX=%d" % [master_slider.value, music_slider.value, sfx_slider.value])

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
	
	# Check for duplicate actions
	for other_action in DEFAULTS.keys():
		if other_action == action:
			continue
		
		var events = InputMap.action_get_events(other_action)
		for event in events:
			if event is InputEventKey and event.keycode == keycode:
				print("ERROR: %s is already bound to %s" % [OS.get_keycode_string(keycode), other_action])
				_bind_buttons[action].text = "Already bound!"
				return
	
	print("Rebinding %s to %s (%d)" % [action, OS.get_keycode_string(keycode), keycode])
	
	# Clear and add
	_clear_action_keys(action)
	_add_key_to_action(action, keycode)
	
	# Update button immediately
	var key_string = OS.get_keycode_string(keycode)
	_bind_buttons[action].text = key_string  # Set directly
	print("Button updated to: %s" % key_string)
	
	# Verify it was added
	var events := InputMap.action_get_events(action)
	print("After rebind, events for %s: %s" % [action, events])

func _refresh_button_label(action: String) -> void:
	if not _bind_buttons.has(action):
		return
	
	var events := InputMap.action_get_events(action)
	var key_string := _find_key_string(action, events)
	_bind_buttons[action].text = key_string if key_string else "Unbound"

func _find_key_string(action: String, events: Array) -> String:
	# Simply find the FIRST keyboard event and show it (should only be one)
	for event in events:
		if event is InputEventKey:
			return OS.get_keycode_string(event.keycode)
	
	return ""  # No keyboard event found

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
	# Check if any action has multiple keyboard keys
	if not _validate_keybinds():
		print("ERROR: Cannot apply - some actions have multiple keys bound")
		return
	
	_save_keybinds()
	_save_volumes()
	
	hide_settings()
	if get_parent().has_method("show_pause"):
		get_parent().show_pause()

func _validate_keybinds() -> bool:
	for action in DEFAULTS.keys():
		var keyboard_count = 0
		var events = InputMap.action_get_events(action)
		
		for event in events:
			if event is InputEventKey:
				keyboard_count += 1
		
		# Only allow 1 keyboard key per action
		if keyboard_count > 1:
			print("ERROR: Action '%s' has %d keyboard keys bound (max 1 allowed)" % [action, keyboard_count])
			_bind_buttons[action].text = "ERROR: Multiple keys!"
			return false
	
	return true
