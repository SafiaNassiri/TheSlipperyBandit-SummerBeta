extends Node3D

const SPEED := 4.2
const HALF_DIST := 8.6
const GAP := 3

@onready var _raccoon: Node3D = $Raccoon
@onready var _camera: Camera3D = $Camera3D

var _chasers: Array[Node3D] = []

var _dir := 1.0
var _x := -HALF_DIST

func _ready() -> void:
	for n in $Chasers.get_children():
		_chasers.append(n)
	var ap := _raccoon.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap:
		ap.play("Run")
	_place()

func _process(delta: float) -> void:
	_x += _dir * SPEED * delta
	if absf(_x) > HALF_DIST:
		_dir = -_dir
		_x = clampf(_x, -HALF_DIST, HALF_DIST)
	_place()

func _place() -> void:
	_raccoon.position.x = _x
	_raccoon.rotation_degrees.y = 90 * _dir
	for i in _chasers.size():
		_chasers[i].position.x = _x - _dir * GAP * float(i + 1)
		_chasers[i].rotation_degrees.y = 90 * _dir
