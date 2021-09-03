extends Node2D
signal back_press

const level_sel = preload("res://scenes/menu/MenuLevel.tscn")
onready var overlay := $Overlay
onready var tween := $Overlay/Tween
onready var click_layer := $ClickLayer
var levels := []
var level_nodes := []
var selected_idx := -1
var is_animating := false

func _ready(): set_chapter(0)

func set_mode(mode: String):
	clean_up()
	$MenuGoBack/Label.text = mode
	levels = Levels.get_available_mode_levels(mode)
	overlay.z_index = 1
	click_layer.z_index = 999
	overlay.modulate.a = 0
	for i in range(0, levels.size()):
		var level: Levels.LevelInfo = levels[i]
		var l = level_sel.instance()
		l.connect("chosen", self, "_on_level_selected", [l])
		l.level_num = i
		l.level = level
		l.mode = MenuLevel.DisplayMode.Other
		l.mode_name = mode
		l.position.y = Consts.MENU_TOP_HEIGHT + Consts.MENULEVEL_HEIGHT * i
		l.z_index = 0
		add_child(l)
		level_nodes.append(l)

func set_chapter(chapter: int):
	clean_up()
	$MenuGoBack/Label.text = "Chapter %s - %s" % [chapter + 1, "ASS"]
	levels = Levels.get_available_story_levels(chapter)
	overlay.z_index = 1
	click_layer.z_index = 999
	overlay.modulate.a = 0
	for i in range(0, levels.size()):
		var level: Levels.LevelInfo = levels[i]
		var l = level_sel.instance()
		l.connect("chosen", self, "_on_level_selected", [l])
		l.chapter_num = chapter
		l.level_num = i
		l.level = level
		l.position.y = Consts.MENU_TOP_HEIGHT + Consts.MENULEVEL_HEIGHT * i
		l.z_index = 0
		add_child(l)
		level_nodes.append(l)

func clean_up():
	if levels.size() == 0: return
	for ln in level_nodes:
		ln.queue_free()
	level_nodes = []
	levels = []

func _on_level_selected(sel: MenuLevel):
	if is_animating: return
	if selected_idx >= 0:
		close_open_level()
		return
	is_animating = true
	sel.z_index = 2
	sel.show_additional_details(450)
	tween.interpolate_property(overlay, "modulate:a", 0, 1, 0.25, Tween.TRANS_LINEAR)
	tween.start()
	yield(tween, "tween_completed")
	selected_idx = level_nodes.find(sel)
	click_layer.show()
	is_animating = false

func _on_outer_input(event):
	if event is InputEventMouseButton && event.button_index == 1 && selected_idx >= 0:
		close_open_level()

func close_open_level():
	if is_animating: return
	is_animating = true
	var sel: MenuLevel = level_nodes[selected_idx]
	sel.hide_additional_details()
	sel.z_index = 0
	selected_idx = -1
	tween.interpolate_property(overlay, "modulate:a", 1, 0, Consts.LEVEL_OPEN_TIME, Tween.TRANS_LINEAR)
	tween.start()
	yield(tween, "tween_completed")
	click_layer.hide()
	is_animating = false

func _on_MenuGoBack_back_select(): emit_signal("back_press")

func blur():
	for n in level_nodes:
		n.blur()

func unblur():
	for n in level_nodes:
		n.unblur()
