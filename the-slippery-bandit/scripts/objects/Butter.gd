extends Area3D

signal butter_collected

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.add_butter()
		emit_signal("butter_collected")
		queue_free()
