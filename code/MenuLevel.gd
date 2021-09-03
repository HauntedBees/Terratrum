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

onready var tween := $Tween
onready var main := $Main
onready var mask := $Main/Mask
var mode = DisplayMode.StoryLevel
var chapter_num := 0	# StoryLevel
var label_text := ""	# StoryChapter, MainMenu
var subtitle_text := ""	# StoryChapter, MainMenu
var mode_name := ""		# Other
var level_num: int = 0
var level: Levels.LevelInfo = null
var best_score: PlayerData.BestScore = null
var characters := []
var selected_character := "Mole"
var active := false
var info_panel: Node2D = null
onready var base_y := position.y

func _ready():
	var my_mask = int(pow(2.0, level_num))
	mask.range_item_cull_mask = my_mask
	mask.hide()
	match mode:
		DisplayMode.StoryChapter, DisplayMode.MainMenu:
			info_panel = $StoryInfo
			$Main/CompletionInfo.text = subtitle_text
			$Main/Label.text = label_text
		DisplayMode.StoryLevel:
			info_panel = $StoryInfo
			level = Levels.get_specific_story_level(chapter_num, level_num)
			best_score = PlayerData.get_story_score(0, 0)
			$Main/CompletionInfo.text = level.desc#"%s" % ["X" if best_score == null else "O"]
			$Main/Label.text = "%s-%s: %s" % [chapter_num + 1, level_num + 1, level.name]
		DisplayMode.Other:
			info_panel = $StoryInfo# $OtherInfo
			level = Levels.get_specific_level(mode_name, level_num)
			best_score = PlayerData.get_standard_score("%s-%s" % [mode_name, level_num])
			$Main/CompletionInfo.text = "%s" % ["X" if best_score == null else "O"]
			$Main/Label.text = level.name
	info_panel.light_mask = my_mask
	for child in info_panel.get_children():
		child.light_mask = my_mask
	draw_characters(my_mask)

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

func show_additional_details(new_y: float):
	if active: return
	active = true
	tween.interpolate_property(self, "position", position, Vector2(position.x, new_y), Consts.LEVEL_OPEN_TIME / 2, Tween.TRANS_LINEAR)
	tween.start()
	yield(tween, "tween_completed")
	info_panel.show()
	mask.show()
	tween.interpolate_property(main, "position", main.position, Vector2(main.position.x, main.position.y - MOVE_Y), Consts.LEVEL_OPEN_TIME / 2, Tween.TRANS_LINEAR)
	tween.start()
	
func hide_additional_details():
	if !active: return
	tween.interpolate_property(main, "position", main.position, Vector2(main.position.x, main.position.y + MOVE_Y), Consts.LEVEL_CLOSE_TIME / 2, Tween.TRANS_LINEAR)
	tween.start()
	yield(tween, "tween_completed")
	info_panel.hide()
	mask.hide()
	tween.interpolate_property(self, "position", position, Vector2(position.x, base_y), Consts.LEVEL_CLOSE_TIME / 2, Tween.TRANS_LINEAR)
	tween.start()
	yield(tween, "tween_completed")
	active = false

func draw_characters(my_mask: int):
	if level == null : return
	var container := $StoryInfo/CharSel# if mode == DisplayMode.StoryLevel else $OtherInfo
	var x := 0
	var y := 0
	for character in level.available_characters:
		var c: CharSel = char_sel.instance()
		c.character = character
		c.light_mask = my_mask
		c.get_child(0).light_mask = my_mask
		c.position = Vector2(x, y)
		container.add_child(c)
		c.connect("char_change", self, "choose_character", [character])
		if characters.size() == 0:
			c.toggle_select(true)
			selected_character = character
		characters.append(c)
		x += 100

func choose_character(character: String):
	selected_character = character
	for c in characters:
		c.toggle_select(c.character == character)

func _on_StartButton_pressed():
	var level_info := Levels.FullLevelInfo.new(level, selected_character, get_metadata())
	if level_info.misc_metadata.has("cutscene"):
		SceneSwitcher.go_to_cutscene(level_info)
	else:
		SceneSwitcher.go_to_game(level_info)

func _on_select(event):
	if event is InputEventMouseButton && event.button_index == 1 && !event.pressed:
		emit_signal("chosen")

func blur():
	$Main/Label.material = blur_shader
	$Main/CompletionInfo.material = blur_shader
func unblur():
	$Main/Label.material = null
	$Main/CompletionInfo.material = null
