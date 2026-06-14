extends Camera3D

@export var follow_speed : float = 8.0
@export var height       : float = 25.0
@export var distance     : float = 25.0

@export var shake_duration : float = 0.4
@export var shake_intensity : float = 0.3

@export var zoom_duration : float = 1.2
@export var zoom_target_size : float = 3.0 # smaller = more zoom in

var _target : Node3D = null
var _shake_timer : float = 0.0
var _base_offset : Vector3 = Vector3.ZERO
var _zooming : bool = false

func _ready() -> void:
	_target = get_tree().get_first_node_in_group("player")
	make_current()
	
	if _target:
		global_position = _get_desired_position()
	
	look_at(_target.global_position if _target else Vector3.ZERO, Vector3.UP)

func _physics_process(delta: float) -> void:
	if not _target or _zooming:
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

func death_zoom() -> void:
	_zooming = true
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_EXPO)
	# Zoom in by shrinking orthographic size
	tween.tween_property(self, "size", zoom_target_size, zoom_duration)
	await tween.finished
	_zooming = false
