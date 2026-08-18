extends CharacterBody3D

@export var base_speed        : float = 5.0
@export var sprint_multiplier : float = 1.6

@export var max_butter        : int   = 6
@export var max_friction      : float = 20.0    # INCREASED for snappier when clean
@export var min_friction      : float = 0.3     # LOWERED for dramatic slide (was 0.8)
@export var max_acceleration  : float = 20.0    # INCREASED for snappier turning when clean
@export var min_acceleration  : float = 0.5     # LOWERED for harder turning when buttery (was 1.0)

@onready var player = $CartoonRaccoon

var butter_count : int = 0
var _friction : float = 0.0
var _accel    : float = 0.0
var _is_sliding : bool = false

const GRAVITY    := 9.8
# angle 135 make it straight up and down, angle 90 makes it so that WASD matches with map angles
const ISO_ANGLE  := deg_to_rad(135.0)

func _ready() -> void:
	add_to_group("player")
	_update_physics_from_butter()

func set_max_butter(amount: int) -> void:
	max_butter = amount
	_update_physics_from_butter()

func _physics_process(delta: float) -> void:
	_update_physics_from_butter()

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var input_dir := _get_input_vector()
	var is_moving := input_dir != Vector2.ZERO

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
		_is_sliding = false
	else:
		# Decelerate with friction based on butter
		velocity.x = move_toward(velocity.x, 0.0, _friction * delta * base_speed)
		velocity.z = move_toward(velocity.z, 0.0, _friction * delta * base_speed)
		# Check if actually sliding (has velocity but no input)
		var current_speed = Vector2(velocity.x, velocity.z).length()
		if current_speed > 0.1:
			_is_sliding = true
			player.play_animation("Slide" if butter_count > 0 else "Walk")
		else:
			_is_sliding = false
			player.stop_animations()

	move_and_slide()

func _get_input_vector() -> Vector2:
	return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

func _is_sprinting() -> bool:
	return Input.is_action_pressed("sprint")

func add_butter() -> void:
	butter_count = min(butter_count + 1, max_butter)
	_update_physics_from_butter()
	print("Butter collected: %d / %d - Slide distance: %.2f" % [butter_count, max_butter, _calculate_slide_distance()])

func _update_physics_from_butter() -> void:
	var t  := float(butter_count) / float(max_butter) if max_butter > 0 else 0.0
	_friction = lerp(max_friction, min_friction, t)
	_accel    = lerp(max_acceleration, min_acceleration, t)

func _calculate_slide_distance() -> float:
	if _friction <= 0:
		return 0.0
	# Rough estimate of how long to decelerate from base_speed to near-zero
	var time_to_stop := (base_speed * base_speed) / (2.0 * _friction * base_speed)
	return base_speed * time_to_stop
