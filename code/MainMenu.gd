extends Node2D
const SHIFT_X := 730

onready var menu_sel := $MenuSelect
onready var chapter_sel := $ChapterSelect
onready var level_sel := $LevelSelect
onready var char_sel := $CharSelect
onready var tween := $Tween

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
		switch_areund(menu_sel, chapter_sel, false)
	if option == "STANDARD":
		if tween.is_active(): return
		level_sel.set_mode("standard")
		switch_areund(menu_sel, level_sel, false)
		
func _on_ChapterSelect_selected_chapter(chapter_idx: int):
	if tween.is_active(): return
	level_sel.set_chapter(chapter_idx)
	switch_areund(chapter_sel, level_sel, false)

func _on_LevelSelect_level_select(level: Levels.LevelInfo, metadata: Dictionary):
	if tween.is_active(): return
	char_sel.set_level(level, metadata)
	switch_areund(level_sel, char_sel, false)

func _on_ChapterSelect_back_press():
	if tween.is_active(): return
	switch_areund(menu_sel, chapter_sel, true)
func _on_LevelSelect_back_press():
	if tween.is_active(): return
	switch_areund(chapter_sel, level_sel, true)
func _on_CharSelect_back_press():
	if tween.is_active(): return
	switch_areund(level_sel, char_sel, true)

func switch_areund(old, new, is_back: bool):
	old.blur()
	new.blur()
	var old_from := -SHIFT_X if is_back else 0
	var old_to := 0 if is_back else -SHIFT_X
	var new_from := 0 if is_back else SHIFT_X
	var new_to := SHIFT_X if is_back else 0
	tween.interpolate_property(old, "position:x", old_from, old_to, 0.5, Tween.TRANS_LINEAR)
	tween.interpolate_property(new, "position:x", new_from, new_to, 0.5, Tween.TRANS_LINEAR)
	tween.start()
	yield(tween, "tween_completed")
	old.unblur()
	new.unblur()
