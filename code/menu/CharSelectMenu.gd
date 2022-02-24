extends Node2D
signal back_press

onready var char_sel = $CharSelectGrid
var level: Levels.LevelInfo = null
var metadata := {}

func set_level(l: Levels.LevelInfo, m: Dictionary):
	level = l
	metadata = m
	$MenuGoBack.text = l.name # TODO: CHAPTERNUM-LEVELNUM prefix for story mode
	char_sel.set_characters(l.available_characters)

func _on_MenuGoBack_back_select(): emit_signal("back_press")

func _on_BeginButton_pressed():
	var level_info := Levels.FullLevelInfo.new(level, char_sel.selected_char, metadata)
	if level_info.misc_metadata.has("cutscene"):
		SceneSwitcher.go_to_cutscene(level_info)
	else:
		SceneSwitcher.go_to_game(level_info)
	
func blur(): pass
func unblur(): pass
