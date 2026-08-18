extends Node

var cutscene_data = {
	1: {
		"text": "BREAKING NEWS\n\nLocal butter thief strikes again.\nPolice baffled by the theft of dairy products.",
		"duration": 3.0
	},
	2: {
		"text": "BREAKING NEWS\n\nMystery bandit continues spree.\nNeighbors report missing butter nationwide.",
		"duration": 3.0
	},
	3: {
		"text": "BREAKING NEWS\n\nWave of butter thefts reaches epidemic levels.\nExperts remain stumped.",
		"duration": 3.0
	}
}

func play_news_cutscene(level: int) -> void:
	if cutscene_data.has(level):
		var data = cutscene_data[level]
		get_tree().change_scene_to_file("res://scenes/cutscenes/news_cutscene.tscn")
		# Wait multiple frames for scene to fully load and become current
		await get_tree().process_frame
		await get_tree().process_frame
		
		var current_scene = get_tree().current_scene
		if current_scene and current_scene.has_method("setup"):
			var next_level = level + 1
			current_scene.setup(data["text"], data["duration"], next_level)

func play_ending_cutscene() -> void:
	get_tree().change_scene_to_file("res://scenes/cutscenes/ending_cutscene.tscn")
