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
var faded_walls: Dictionary = {}
var target_alpha: float = 0.2

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
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_transform.origin, _target.global_position)
	query.exclude = [_target]
	var result = space_state.intersect_ray(query)
	
	for wall in faded_walls.keys():
		if is_instance_valid(wall):
			_set_wall_transparency(wall.find_children("", "MeshInstance3D")[0], 1.0)
	faded_walls.clear()
	
	if result:
		var collider = result.collider as Node3D
		if collider.is_in_group("walls") or collider.name.contains("Wall"):
			_set_wall_transparency(collider.find_children("", "MeshInstance3D")[0], target_alpha)
			faded_walls[collider] = true

func _set_wall_transparency(wall: Node3D, alpha: float):
	if not wall is MeshInstance3D:
		return
	
	var mesh_instance: MeshInstance3D = wall as MeshInstance3D
	
	var material: StandardMaterial3D
	if mesh_instance.get_mesh().surface_get_material(0) is StandardMaterial3D:
		material = mesh_instance.get_mesh().surface_get_material(0).duplicate() as StandardMaterial3D
		mesh_instance.set_surface_override_material(0, material)
	else:
		material = mesh_instance.get_surface_override_material(0)
		if not material:
			material = StandardMaterial3D.new()
			mesh_instance.set_surface_override_material(0, material)
	
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	material.albedo_color.a = alpha
	

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
