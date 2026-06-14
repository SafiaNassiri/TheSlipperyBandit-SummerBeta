extends Node3D

@onready var hud : CanvasLayer = $HUD

var butter_total : int = 0
var butter_collected : int = 0
var secret_found : bool = false

func _ready() -> void:
	var butters := get_tree().get_nodes_in_group("butter")
	butter_total = butters.size()
	
	for butter in butters :
		butter.butter_collected.connect(_on_butter_collected)
	
	var secret := get_tree().get_first_node_in_group("secret")
	if secret:
		secret.secret_collected.connect(_on_secret_collected)
	
	if hud:
		hud.init(butter_total)

func _on_butter_collected() -> void:
	butter_collected += 1
	if hud:
		hud.on_butter_collected(butter_collected, butter_total)

func _on_secret_collected() -> void:
	secret_found = true
	if hud:
		hud.on_secret_found()

func on_player_exited() -> void:
	if butter_collected >= 1:
		GameManager.level_complete(butter_collected, butter_total, secret_found)
