extends Node

# Level tracking
var current_level: int = 1
var total_levels: int = 3

# Tracks which levels are unlocked (level 1 always unlocked)
var unlocked_levels: Array[int] = [1]

# Butter tracking (set by each level scene when it ends)
var butter_collected: int = 0
var butter_total: int = 0
var secret_found: bool = false

const SCENE_MAIN_MENU    = "res://scenes/menus/MainMenu.tscn"
const SCENE_LEVEL_SELECT = "res://scenes/menus/LevelSelect.tscn"
const SCENE_GAME_OVER    = "res://scenes/menus/GameOver.tscn"
const SCENE_WIN          = "res://scenes/menus/WinScreen.tscn"
const SCENE_LEVELS = {
	1: "res://scenes/levels/Level1.tscn",
	2: "res://scenes/levels/Level2.tscn",
	3: "res://scenes/levels/Level3.tscn",
}

func go_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)

func go_to_level_select() -> void:
	get_tree().change_scene_to_file(SCENE_LEVEL_SELECT)

func start_level(level_num: int) -> void:
	current_level = level_num
	if SCENE_LEVELS.has(level_num):
		get_tree().change_scene_to_file(SCENE_LEVELS[level_num])
	else:
		push_error("GameManager: No scene registered for level %d" % level_num)

func level_complete(collected: int, total: int, secret: bool) -> void:
	butter_collected = collected
	butter_total     = total
	secret_found     = secret
	# Unlock next level
	var next = current_level + 1
	if next <= total_levels and next not in unlocked_levels:
		unlocked_levels.append(next)
	get_tree().change_scene_to_file(SCENE_WIN)

func level_failed() -> void:
	get_tree().change_scene_to_file(SCENE_GAME_OVER)

func quit_game() -> void:
	get_tree().quit()
