extends StaticBody3D

@export var knock_rotation : float = -60.0
@export var anim_speed : float = 6.0
@onready var interact_prompt = $InteractPrompt

var _is_knocked : bool = false
var _player_nearby : bool = false
var _target_angle : float = 0.0

func _ready() -> void:
	_target_angle = rotation_degrees.z
	var zone := get_node_or_null("InteractZone") as Area3D
	if zone:
		zone.body_entered.connect(_on_player_entered_range)
		zone.body_exited.connect(_on_player_exited_range)
	
	var ramp := get_node_or_null("RampCollision") as StaticBody3D
	if ramp:
		ramp.process_mode = Node.PROCESS_MODE_DISABLED
		ramp.visible = false

func _physics_process(delta: float) -> void:
	rotation_degrees.z = lerp(rotation_degrees.z, _target_angle, anim_speed * delta)
	
	if not _is_knocked and _player_nearby and Input.is_action_just_pressed("interact"):
		_knock_over()

func _knock_over() -> void:
	_is_knocked = true
	_target_angle = rotation_degrees.z + knock_rotation
	$CollisionShape3D.disabled = true

	var ramp := get_node_or_null("RampCollision") as StaticBody3D
	if ramp:
		ramp.process_mode = Node.PROCESS_MODE_INHERIT
		ramp.visible = true

func _on_player_entered_range(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		interact_prompt.visible = true

func _on_player_exited_range(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		interact_prompt.visible = false
