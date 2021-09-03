extends Node2D
signal selected_chapter(option)
signal back_press

const level_sel = preload("res://scenes/menu/MenuLevel.tscn")
var chapters := []
var chapter_nodes := []
var selected_idx := -1

func _ready():
	$MenuGoBack/Label.text = "Chapter Select"
	chapters = Levels.get_available_story_chapters()
	for i in range(0, chapters.size()):
		var chapter: Levels.ChapterInfo = chapters[i]
		var l = level_sel.instance()
		l.connect("chosen", self, "_on_chapter_selected", [l, i])
		l.mode = MenuLevel.DisplayMode.StoryChapter
		l.label_text = "%s. %s (%s)" % [i + 1, chapter.name, chapter.completion]
		l.position.y = Consts.MENU_TOP_HEIGHT + Consts.MENULEVEL_HEIGHT * i
		l.z_index = 0
		add_child(l)
		chapter_nodes.append(l)

func _on_chapter_selected(sel: MenuLevel, chapter_idx: int):
	print(sel) # TODO make it light up or some shit
	emit_signal("selected_chapter", chapter_idx)

func _on_MenuGoBack_back_select(): emit_signal("back_press")

func blur():
	for n in chapter_nodes:
		n.blur()

func unblur():
	for n in chapter_nodes:
		n.unblur()
