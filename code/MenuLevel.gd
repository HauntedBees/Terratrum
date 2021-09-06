extends Node2D
class_name MenuLevel

signal chosen
const blur_shader = preload("res://shaders/blur.tres")
const char_sel = preload("res://scenes/menu/CharSel.tscn")
const MOVE_Y := 200

enum DisplayMode {
	MainMenu,
	StoryChapter,
	StoryLevel,
	Other
}

onready var main := $Main
var mode = DisplayMode.StoryLevel
var chapter_num := 0	# StoryLevel
var label_text := ""	# StoryChapter, MainMenu
var subtitle_text := ""	# StoryChapter, MainMenu
var mode_name := ""		# Other
var level_num: int = 0
var level: Levels.LevelInfo = null
var best_score: PlayerData.BestScore = null
var selected_character := "Mole"
onready var base_y := position.y

func _ready():
	match mode:
		DisplayMode.StoryChapter, DisplayMode.MainMenu:
			$Main/CompletionInfo.text = subtitle_text
			$Main/Label.text = label_text
		DisplayMode.StoryLevel:
			level = Levels.get_specific_story_level(chapter_num, level_num)
			best_score = PlayerData.get_story_score(0, 0)
			$Main/CompletionInfo.text = level.desc#"%s" % ["X" if best_score == null else "O"]
			$Main/Label.text = "%s-%s: %s" % [chapter_num + 1, level_num + 1, level.name]
		DisplayMode.Other:
			level = Levels.get_specific_level(mode_name, level_num)
			best_score = PlayerData.get_standard_score("%s-%s" % [mode_name, level_num])
			$Main/CompletionInfo.text = "%s" % ["X" if best_score == null else "O"]
			$Main/Label.text = level.name

func _on_select(event):
	if event is InputEventMouseButton && event.button_index == 1 && !event.pressed:
		emit_signal("chosen")

func get_metadata():
	match mode:
		DisplayMode.StoryLevel:
			return {
				mode = "STORY",
				chapter = chapter_num,
				level = level_num,
				key = "S%s-%s" % [chapter_num + 1, level_num + 1],
				cutscene = true
			}
	return {}

func blur():
	$Main/Label.material = blur_shader
	$Main/CompletionInfo.material = blur_shader
func unblur():
	$Main/Label.material = null
	$Main/CompletionInfo.material = null
