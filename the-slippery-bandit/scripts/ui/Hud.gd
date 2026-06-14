extends CanvasLayer

@onready var butter_label : Label = $HUDContainer/TopLeft/ButterLabel
@onready var secret_label : Label = $HUDContainer/TopLeft/SecretLabel
@onready var level_label  : Label = $HUDContainer/TopRight/LevelLabel
@onready var timer_label  : Label = $HUDContainer/TopRight/TimerLabel

var _elapsed_time : float = 0.0
var _butter_collected : int = 0
var _butter_total : int = 0
var _secret_found : bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	level_label.text = "HOME %d" % GameManager.current_level
	_update_butter_dispaly()
	_update_secret_display()

func _process(delta: float) -> void:
	if not get_tree().paused:
		_elapsed_time += delta
		_update_timer_display()

func on_butter_collected(collected: int, total: int) -> void:
	_butter_collected = collected
	_butter_total = total
	_update_butter_dispaly()

func on_secret_found() -> void:
	_secret_found = true
	_update_secret_display()

func init(butter_total: int) -> void:
	_butter_total = butter_total
	_butter_collected = 0
	_update_butter_dispaly()

func _update_butter_dispaly() -> void:
	butter_label.text = "🧈 %d / %d" % [_butter_collected, _butter_total]

func _update_secret_display() -> void:
	secret_label.text = "★ %s" % ("FOUND" if _secret_found else "NOT FOUND")

func _update_timer_display() -> void:
	var minutes := int(_elapsed_time) / 60
	var seconds := int(_elapsed_time) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]
func get_elapsed_time() -> float:
	return _elapsed_time
