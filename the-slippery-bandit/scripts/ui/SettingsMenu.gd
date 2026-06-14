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

@onready var overlay : ColorRect = $Overlay
@onready var window_panel : PanelContainer = $Overlay/Window

# AUDIO
@onready var master_slider : HSlider = $Overlay/Window/Layout/TabBar/Audio/MasterRow/MasterSlider
@onready var master_value : Label = $Overlay/Window/Layout/TabBar/Audio/MasterRow/MasterValue
@onready var music_slider : HSlider = $Overlay/Window/Layout/TabBar/Audio/MusicRow/MusicSlider
@onready var music_value : Label = $Overlay/Window/Layout/TabBar/Audio/MusicRow/MusicValue
@onready var sfx_slider : HSlider = $Overlay/Window/Layout/TabBar/Audio/SFXRow/SFXSlider
@onready var sfx_value : Label = $Overlay/Window/Layout/TabBar/Audio/SFXRow/SFXValue

# CONTROLS
@onready var reset_button : Button = $Overlay/Window/Layout/TabBar/Controls/ResetButton
@onready var back_button : Button = $Overlay/Window/Layout/Header/CloseButton
@onready var apply_button : Button = $Overlay/Window/Layout/Footer/ApplyButton

var _listening_for : String = ""
var _bind_buttons : Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.hide()
 	
	# AUDIO SLIDERS
	_setup_slider(master_slider, master_value, BUS_MASTER)
	_setup_slider(music_slider, music_value, BUS_MUSIC)
	_setup_slider(sfx_slider, sfx_value, BUS_SFX)
	
	master_slider.value_changed.connect(func(v): _on_volume_changed(BUS_MASTER, v, master_value))
	music_slider.value_changed.connect(func(v): _on_volume_changed(BUS_MUSIC, v, music_value))
	sfx_slider.value_changed.connect(func(v): _on_volume_changed(BUS_SFX, v, sfx_value))
	
	# CONTROLS
	_build_bind_buttons() 
	reset_button.pressed.connect(_on_reset_pressed)
	
	back_button.pressed.connect(_on_back_pressed)
	apply_button.pressed.connect(_on_apply_pressed)

func _input(event: InputEvent) -> void:
	if _listening_for.is_empty():
		return
	# Only accept keyboard input for rebinding
	if event is InputEventKey and event.pressed and not event.echo:
		_rebind(_listening_for, event.keycode)
		_listening_for = ""
		get_viewport().set_input_as_handled()

func show_settings() -> void:
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
	if value == 0.0:
		AudioServer.set_bus_mute(bus,true)
	else:
		AudioServer.set_bus_mute(bus, false)
		AudioServer.set_bus_volume_db(bus, linear_to_db(value / 100.0))

# CONTROLS
func _build_bind_buttons() -> void:
	var controls_tab := $Overlay/Window/Layout/TabBar/Controls
	for action in ACTIONS.keys():
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = ACTIONS[action]
		lbl.custom_minimum_size.x = 120
		var btn := Button.new()
		btn.custom_minimum_size.x = 140
		btn.pressed.connect(_on_bind_button_pressed.bind(action, btn))
		row.add_child(lbl)
		row.add_child(btn)
		controls_tab.add_child(row)
		controls_tab.move_child(row, controls_tab.get_child_count() - 2)
		_bind_buttons[action] = btn
		_refresh_button_label(action)

func _on_bind_button_pressed(action: String) -> void:
	_listening_for = action
	_bind_buttons[action].text = "Press a key..."

func _rebind(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		push_error("Action does not exist: %s" % action)
		return
	# Remove all existing keyboard events for this action
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
	if not _bind_buttons.has(action):
		return
	
	var events := InputMap.action_get_events(action)
	for event in events:
		if event is InputEventKey:
			_bind_buttons[action].text = OS.get_keycode_string(event.keycode)
			return
	_bind_buttons[action].text = "Unbound"

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
	var parent = get_parent()
	if parent.has_method("show_pause"):
		parent.show_pause()

func _on_apply_pressed() -> void:
	hide_settings()
	var parent = get_parent()
	if parent.has_method("show_pause"):
		parent.show_pause()
