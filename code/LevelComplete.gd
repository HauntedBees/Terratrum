extends Node2D
onready var game_info: Levels.FullLevelInfo = SceneSwitcher.get_carried_scene_data()
func _ready():
	if game_info == null: return
	var play_info: Player.PlayInfo = game_info.play_data
	var response := PlayerData.submit_standard_score(game_info.misc_metadata.key, play_info.score, int(play_info.play_time), play_info.max_depth, !play_info.gamed_over)
	$ScoreLabel.text = "Score: %s \n %s \n %s \n %s" % [
		play_info.score, 
		"BEST TIME" if response.time else "",
		"HIGH SCORE" if response.score else "",
		"DEEPEST PLUNGE" if response.depth else ""
	]
func _on_Button_pressed(): SceneSwitcher.go_to_level_select({} if game_info == null else game_info.misc_metadata)
