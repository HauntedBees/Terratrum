extends Node2D

const SHIFT_X := 730

onready var menu_sel := $MenuSelect
onready var chapter_sel := $ChapterSelect
onready var level_sel := $LevelSelect
onready var tween := $Tween
var all_levels := {}

func _ready():
	var from_info = SceneSwitcher.get_carried_scene_data()
	if from_info == null: return
	if from_info.mode == "STORY":
		menu_sel.position.x = -SHIFT_X
		chapter_sel.position.x = -SHIFT_X
		level_sel.position.x = 0
		level_sel.set_chapter(from_info.chapter)

func _on_MenuSelect_selected_option(option: String):
	if tween.is_active(): return
	if option == "STORY":
		menu_sel.blur()
		chapter_sel.blur()
		tween.interpolate_property(menu_sel, "position:x", 0, -SHIFT_X, 0.5, Tween.TRANS_LINEAR)
		tween.interpolate_property(chapter_sel, "position:x", SHIFT_X, 0, 0.5, Tween.TRANS_LINEAR)
		tween.start()
		yield(tween, "tween_completed")
		menu_sel.unblur()
		chapter_sel.unblur()
	if option == "STANDARD":
		if tween.is_active(): return
		level_sel.set_mode("standard")
		menu_sel.blur()
		level_sel.blur()
		tween.interpolate_property(menu_sel, "position:x", 0, -SHIFT_X, 0.5, Tween.TRANS_LINEAR)
		tween.interpolate_property(level_sel, "position:x", SHIFT_X, 0, 0.5, Tween.TRANS_LINEAR)
		tween.start()
		yield(tween, "tween_completed")
		level_sel.unblur()
		menu_sel.unblur()

func _on_ChapterSelect_selected_chapter(chapter_idx: int):
	if tween.is_active(): return
	level_sel.set_chapter(chapter_idx)
	chapter_sel.blur()
	level_sel.blur()
	tween.interpolate_property(chapter_sel, "position:x", 0, -SHIFT_X, 0.5, Tween.TRANS_LINEAR)
	tween.interpolate_property(level_sel, "position:x", SHIFT_X, 0, 0.5, Tween.TRANS_LINEAR)
	tween.start()
	yield(tween, "tween_completed")
	level_sel.unblur()
	chapter_sel.unblur()

func _on_ChapterSelect_back_press():
	if tween.is_active(): return
	menu_sel.blur()
	chapter_sel.blur()
	tween.interpolate_property(menu_sel, "position:x", -SHIFT_X, 0, 0.5, Tween.TRANS_LINEAR)
	tween.interpolate_property(chapter_sel, "position:x", 0, SHIFT_X, 0.5, Tween.TRANS_LINEAR)
	tween.start()
	yield(tween, "tween_completed")
	menu_sel.unblur()
	chapter_sel.unblur()

func _on_LevelSelect_back_press():
	if tween.is_active(): return
	level_sel.blur()
	chapter_sel.blur()
	tween.interpolate_property(chapter_sel, "position:x", -SHIFT_X, 0, 0.5, Tween.TRANS_LINEAR)
	tween.interpolate_property(level_sel, "position:x", 0, SHIFT_X, 0.5, Tween.TRANS_LINEAR)
	tween.start()
	yield(tween, "tween_completed")
	level_sel.unblur()
	chapter_sel.unblur()
