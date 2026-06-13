extends CharacterBody3D

@export var base_speed        : float = 5.0
@export var sprint_multiplier : float = 1.6

@export var max_butter        : int   = 6
@export var max_friction      : float = 16.0
@export var min_friction      : float = 1.5
@export var max_acceleration  : float = 16.0
@export var min_acceleration  : float = 2.0

@onready var player = $CartoonRaccoon

var butter_count : int = 0

var _friction : float = 0.0
var _accel    : float = 0.0

const GRAVITY    := 9.8
# angle 135 make it straight up and down, angle 90 makes it so that WASD matches with map angles
const ISO_ANGLE  := deg_to_rad(135.0)

func _ready() -> void:
	add_to_group("player")
	_update_physics_from_butter()

func _physics_process(delta: float) -> void:
	_update_physics_from_butter()

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var input_dir := _get_input_vector()

	if input_dir != Vector2.ZERO:
		var angle   := ISO_ANGLE
		var world_x := input_dir.x * cos(angle) - input_dir.y * sin(angle)
		var world_z := input_dir.x * sin(angle) + input_dir.y * cos(angle)
		var move_dir := Vector3(world_x, 0.0, world_z).normalized()

		var target_speed := base_speed * (sprint_multiplier if _is_sprinting() else 1.0)

		velocity.x = move_toward(velocity.x, move_dir.x * target_speed, _accel * delta * base_speed)
		velocity.z = move_toward(velocity.z, move_dir.z * target_speed, _accel * delta * base_speed)

		var target_angle := atan2(move_dir.x, move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 12.0 * delta)
		
		player.play_animation("Run" if _is_sprinting() else "Walk")
	else:
		velocity.x = move_toward(velocity.x, 0.0, _friction * delta * base_speed)
		velocity.z = move_toward(velocity.z, 0.0, _friction * delta * base_speed)
		player.stop_animations()

	move_and_slide()

func _get_input_vector() -> Vector2:
	return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

func _is_sprinting() -> bool:
	return Input.is_action_pressed("sprint")

func add_butter() -> void:
	butter_count = min(butter_count + 1, max_butter)
	_update_physics_from_butter()
	print("Butter collected: %d / %d" % [butter_count, max_butter])

func _update_physics_from_butter() -> void:
	var t  := float(butter_count) / float(max_butter) if max_butter > 0 else 0.0
	_friction = lerp(max_friction, min_friction, t)
	_accel    = lerp(max_acceleration, min_acceleration, t)
