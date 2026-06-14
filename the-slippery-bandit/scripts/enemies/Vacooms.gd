extends CharacterBody3D

@export var move_speed: float = 2.5
@export var detection_radius: float = 3.0
@export var waypoint_tolerance: float = 0.3
@export var waypoints: Array[NodePath] = []

enum State {PATROL, CAUGHT}
var _state: State = State.PATROL

var _waypoint_nodes: Array[Node3D] = []
var _current_waypoint_index: int = 0
var _player: Node3D = null
var _caught_triggered: bool = false

const GRAVITY := 9.8

func _ready() -> void:
	for path in waypoints:
		var node := get_node_or_null(path)
		if node is Node3D:
			_waypoint_nodes.append(node)
	
	if _waypoint_nodes.is_empty():
		push_warning("VACooms: No waypoints assigned! Add waypoint Node#ds and assign them in the Inspector.")
	
	var zone := get_node_or_null("DetectionZone") as Area3D
	if zone:
		zone.body_entered.connect(_on_detection_zone_body_entered)
	
	_player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	match _state:
		State.PATROL:
			_patrol(delta)
		State.CAUGHT:
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
	move_and_slide()

func _patrol(delta: float) -> void:
	if _waypoint_nodes.is_empty():
		return
	
	var target_pos: Vector3 = _waypoint_nodes[_current_waypoint_index].global_position
	target_pos.y = global_position.y
	
	var direction := (target_pos - global_position)
	var distance := direction.length()
	
	if distance < waypoint_tolerance:
		_current_waypoint_index = (_current_waypoint_index + 1) % _waypoint_nodes.size()
	else:
		var move_dir := direction.normalized()
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
		var angle := atan2(move_dir.x, move_dir.z)
		rotation.y = lerp_angle(rotation.y, angle, 10.0 * delta)

func _on_detection_zone_body_entered(body: Node3D) -> void:
	if _caught_triggered:
		return
	if body.is_in_group("player"):
		_trigger_catch()

func _trigger_catch() -> void:
	_caught_triggered = true
	_state = State.CAUGHT
	velocity = Vector3.ZERO
	
	# Trigger camera shake
	var cam := get_tree().get_first_node_in_group("isometric_camera")
	if cam :
		cam.shake()
	
	# When caugh tanimation is added
	var anim := get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim and anim.has_animation("caught"):
		anim.play("caught")
		await anim.animation_finished
	else:
		await get_tree().create_timer(0.8).timeout
	
	GameManager.level_failed()
