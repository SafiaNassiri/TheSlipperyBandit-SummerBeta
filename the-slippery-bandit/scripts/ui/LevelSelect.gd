extends Control

const LEVEL_NAMES := ["Home 1", "Home 2", "Home 3"]
const LEVEL_DESCS := [
	"A quiet starter home.\nOne VACooms. Easy pickings.",
	"Bigger kitchen.\nMore butter. More danger.",
	"Full house.\nThree VACooms. Good luck.",
]

@onready var level_grid : GridContainer = $CenterContainer/LevelGrid
@onready var back_button : Button = $BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_build_level_cards()

func _build_level_cards() -> void:
	for i in range(1, GameManager.total_levels + 1):
		var card := _make_card(i)
		level_grid.add_child(card)

func _make_card(level_num: int) -> PanelContainer:
	var unlocked : bool = level_num in GameManager.unlocked_levels

	# Card container
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(240, 160)

	# Inner layout
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	# Lock icon or level number
	var icon_label := Label.new()
	icon_label.text = "🧈 %d" % level_num if unlocked else "🔒"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(icon_label)

	# Level name
	var name_label := Label.new()
	var idx := level_num - 1
	name_label.text = LEVEL_NAMES[idx] if idx < LEVEL_NAMES.size() else "Home %d" % level_num
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = LEVEL_DESCS[idx] if (unlocked and idx < LEVEL_DESCS.size()) else "???"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# Play button
	var play_btn := Button.new()
	play_btn.text = "Play" if unlocked else "Locked"
	play_btn.disabled = not unlocked
	if unlocked:
		var level_index := level_num
		play_btn.pressed.connect(func(): GameManager.start_level(level_index))
	vbox.add_child(play_btn)

	return card

func _on_back_pressed() -> void:
	GameManager.go_to_main_menu()
