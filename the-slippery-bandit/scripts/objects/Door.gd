extends StaticBody3D

@export var open_rotation : float = 90.0
@export var anim_speed : float = 5.0

var _is_open : bool = false
var _player_nearby : bool = false
var _target_angle : float = 0.0
var _closed_angle : float = 0.0

func _ready() -> void:
	_closed_angle = rotation_degrees.y
	_target_angle = _closed_angle
	
	var zone := get_node_or_null("InteractZone") as Area3D
	if zone: 
		zone.body_entered.connect(_on_player_entered_range)
		zone.body_exited.connect(_on_player_exited_range)

func _physics_process(delta: float) -> void:
	rotation_degrees.y = lerp(rotation_degrees.y, _target_angle, anim_speed * delta)
	
	if _player_nearby and Input.is_action_just_pressed("interact"):
		var player := get_tree().get_first_node_in_group("player")
		if player and global_position.distance_to(player.global_position) < 3.0:
			_toggle()
		else:
			_player_nearby = false

func _toggle() -> void:
	_is_open = not _is_open
	_target_angle = (_closed_angle + open_rotation) if _is_open else _closed_angle
	
	$CollisionShape3D.disabled  = _is_open

func _on_player_entered_range(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true

func _on_player_exited_range(body: Node3D) -> void:
	if body.is_in_group("palyer"):
		_player_nearby = false
