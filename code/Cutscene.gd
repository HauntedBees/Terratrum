extends Node2D

const IMG_PATH = "res://assets_old/dialog/%s.png"
onready var background := $bg
onready var left_character := $left
onready var right_character := $right
onready var from_info: Levels.FullLevelInfo = SceneSwitcher.get_carried_scene_data()
var scene := "S1-1"
var dialog := []
var idx := 0

func _ready():
	if from_info != null: scene = from_info.misc_metadata.key
	var file = File.new()
	file.open("res://json/dialog.json", file.READ)
	var content = file.get_as_text()
	var all_dialog = parse_json(content)
	dialog = all_dialog[scene]
	draw_frame()

func draw_frame():
	var me: Dictionary = dialog[idx]
	if me["left_img"] != "":
		left_character.show()
		left_character.texture = load(IMG_PATH % me["left_img"])
		left_character.modulate = Color.white if me["speaker_highlight"] == "L" else Color.darkgray
	else:
		left_character.hide()
	if me["right_img"] != "":
		right_character.show()
		right_character.texture = load(IMG_PATH % me["right_img"])
		right_character.modulate = Color.white if me["speaker_highlight"] == "R" else Color.darkgray
	else:
		right_character.hide()
	if me["bg_img"] != "":
		background.show()
		background.texture = load(IMG_PATH % me["bg_img"])
	else:
		background.hide()
	$Name.text = tr("NAME_%s" % [me["speaker"].to_upper()])
	$Text.bbcode_text = tr("TEXT_%s_%s" % [scene, idx])

func advance_cutscene():
	idx += 1
	if idx >= dialog.size():
		end_cutscene()
	else:
		draw_frame()

func _input(event):
	if event is InputEventMouseButton && !event.pressed:
		advance_cutscene()

func end_cutscene(): SceneSwitcher.go_to_game(from_info)
