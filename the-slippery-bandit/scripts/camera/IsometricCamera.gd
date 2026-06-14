extends Camera3D

@export var follow_speed : float = 8.0
@export var height       : float = 25.0
@export var distance     : float = 25.0

@export var shake_duration : float = 0.4
@export var shake_intensity : float = 0.3

var _target : Node3D = null
var _shake_timer : float = 0.0
var _base_offset : Vector3 = Vector3.ZERO

func _ready() -> void:
	_target = get_tree().get_first_node_in_group("player")
	make_current()
	
	if _target:
		global_position = _get_desired_position()
	
	look_at(_target.global_position if _target else Vector3.ZERO, Vector3.UP)

func _physics_process(delta: float) -> void:
	if not _target:
		return
	global_position = global_position.lerp(_get_desired_position(), follow_speed * delta)
	look_at(_target.global_position, Vector3.UP)
	
	if _shake_timer > 0.0:
		_shake_timer -= delta
		var intensity := shake_intensity * (_shake_timer / shake_duration)
		h_offset = randf_range(-intensity, intensity)
		v_offset = randf_range(-intensity, intensity)
	else:
		h_offset = 0.0
		v_offset = 0.0

func _get_desired_position() -> Vector3:
	return _target.global_position + Vector3(-distance, height, -distance)

func shake() -> void:
	_shake_timer = shake_duration
