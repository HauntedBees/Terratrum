extends Node2D
class_name Menu

var BASIC_DIFFICULTY_CURVE := [
	Levels.ChunkInfo.new(4, 0, 0),
	Levels.ChunkInfo.new(2, 0, 0),
	Levels.ChunkInfo.new(3, 1, 1)
]
func _on_StartGame_pressed():
	SceneSwitcher.go_to_game(Levels.FullLevelInfo.new(Levels.get_specific_level("debug", 0), "Mole"))

func _on_StartGame2_pressed():
	SceneSwitcher.go_to_game(Levels.FullLevelInfo.new(Levels.get_specific_level("debug", 0), "Mole"))

func _on_RandGame_pressed():
	SceneSwitcher.go_to_game(Levels.FullLevelInfo.new(Levels.get_specific_level("debug", 0), "Mole"))

func _on_EasyGame_pressed():
	SceneSwitcher.go_to_game(Levels.FullLevelInfo.new(Levels.get_specific_level("debug", 0), "Mole"))
