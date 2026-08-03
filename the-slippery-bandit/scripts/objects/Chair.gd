extends StaticBody3D

@export var knock_rotation : float = 90.0
@export var lean_surface_height : float = 0.0 
@export var chair_length : float = 2.6083364 
@export var anim_speed : float = 6.0

var _is_knocked : bool = false
var _player_nearby : bool = false
var _target_angle : float = 0.0
var _player_ref : Node3D = null   # keep a handle on the player while nearby

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
	
	var lean_angle := knock_rotation
	if lean_surface_height > 0.0:
		var ratio : float = clamp(lean_surface_height / chair_length, -1.0, 1.0)
		lean_angle = rad_to_deg(acos(ratio))
	
	# figure out which side the player is on, and fall away from them
	var lean_dir_sign := 1.0
	if _player_ref:
		var to_chair := global_transform.origin - _player_ref.global_transform.origin
		to_chair.y = 0.0
		if to_chair.length() > 0.001:
			to_chair = to_chair.normalized()
			var local_axis := global_transform.basis.x.normalized()  # swap to basis.y if wrong axis
			var side := local_axis.dot(to_chair)
			if side != 0.0:
				lean_dir_sign = sign(side)
	
	_target_angle = rotation_degrees.z + (lean_angle * lean_dir_sign)
	
	$CollisionShape3D.disabled = true
	
	var ramp := get_node_or_null("RampCollision") as StaticBody3D
	if ramp:
		ramp.process_mode = Node.PROCESS_MODE_INHERIT
		ramp.visible = true

func _on_player_entered_range(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		_player_ref = body

func _on_player_exited_range(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		_player_ref = null
