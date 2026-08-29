extends Node3D

@onready var hud : CanvasLayer = $HUD
@export var level_number : int = 1
@export var max_butter_in_level : int = 6 # change per level in inspector

var butter_total : int = 0
var butter_collected : int = 0
var secret_found : bool = false

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_max_butter(max_butter_in_level)
	
	var butters := get_tree().get_nodes_in_group("butter")
	butter_total = butters.size()
	
	for butter in butters :
		butter.butter_collected.connect(_on_butter_collected)
	
	var secret := get_tree().get_first_node_in_group("secret")
	if secret:
		secret.secret_collected.connect(_on_secret_collected)
	
	if hud:
		hud.init(butter_total, level_number)

func _on_butter_collected() -> void:
	butter_collected += 1
	if hud:
		hud.on_butter_collected(butter_collected, butter_total)

func _on_secret_collected() -> void:
	secret_found = true
	if hud:
		hud.on_secret_found()

func on_player_exited() -> void:
	if butter_collected == butter_total:
		GameManager.level_complete(butter_collected, butter_total, secret_found)
		
		await get_tree().process_frame
		
		if level_number < 3:  # Levels 1-2: show news cutscene
			CutsceneManager.play_news_cutscene(level_number)
		else:  # Level 3: show ending cutscene
			CutsceneManager.play_ending_cutscene()
