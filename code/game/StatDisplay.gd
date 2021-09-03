extends Node2D

const hud_text = preload("res://scenes/game/HUDText.tscn")
const Y_OFFSET := 70

onready var full_level_info: Levels.FullLevelInfo = SceneSwitcher.get_carried_scene_data()
var display_score := true
var score_node: HUDText
var display_depth := true
var depth_node: HUDText
var display_time := true
var time_node: HUDText
var display_lives := true
var lives_node: HUDText
var max_depth := 0
var max_time := 0.0

func _ready():
	if full_level_info != null:
		var level := full_level_info.level
		max_depth = level.max_depth
		max_time = level.time_limit
	var nodes := []
	if display_score:
		score_node = create_hud_text("int", tr("HUD_SCORE"))
		nodes.append(score_node)
	if display_depth:
		depth_node = create_hud_text_depth("depth", tr("HUD_DEPTH"))
		nodes.append(depth_node)
	if display_time:
		if max_time > 0.0:
			time_node = create_hud_text("time", tr("HUD_TIME"), max_time)
		else:
			time_node = create_hud_text("time", tr("HUD_TIME"))
		nodes.append(time_node)
	if display_lives:
		lives_node = create_hud_text("int", tr("HUD_LIVES"))
		nodes.append(lives_node)
	for i in nodes.size():
		nodes[i].position.y = i * Y_OFFSET
		add_child(nodes[i])

func create_hud_text_depth(type: String, label: String) -> HUDText:
	var ht := create_hud_text(type, label, 0)
	ht.max_value = max_depth
	return ht

func create_hud_text(type: String, label: String, default_val = 0) -> HUDText:
	var ht: HUDText = hud_text.instance()
	ht.type = type
	ht.label = label
	ht.value = default_val
	return ht

func _on_update_ui_value(key: String, value):
	match key:
		"score": score_node.set_value(value)
		"depth": depth_node.set_value(value)
		"time": time_node.set_value(value)
		"lives": lives_node.set_value(value)
