extends VBoxContainer
signal back_to_main
signal level_selected(level_info)

# TODO: why do the fuckin animations go to shit

var dual_button:PackedScene = preload("res://Menu/DualButton.tscn")
var nodes := []
var levels := []
var chapter_selected := -1
func _ready(): _load_chapters()

func _load_chapters():
	var available_nodes := Levels.get_available_story_chapters()
	for ac in available_nodes:
		var b:DualButton = dual_button.instance()
		b.main_text = "%s. %s" % [ac.number, ac.name]
		b.subtitle_text = "%s%%" % round(ac.completion * 100)
		b.connect("pressed", self, "_on_chapter_pressed")
		nodes.append(b)
		add_child(b)
	move_child($BackButton, nodes.size())

func _load_levels(chapter:int):
	levels = Levels.get_available_story_levels(chapter)
	for i in levels.size():
		var ac = levels[i]
		var b:DualButton = dual_button.instance()
		b.main_text = "%s. %s" % [i + 1, ac.name]
		b.subtitle_text = ac.desc
		b.connect("pressed", self, "_on_level_pressed")
		nodes.append(b)
		add_child(b)
	move_child($BackButton, nodes.size())

func _on_chapter_pressed(chapter:DualButton):
	var idx := nodes.find(chapter)
	if idx < 0: return
	chapter_selected = idx
	_clear_all()
	_load_levels(idx)

func _on_level_pressed(level:DualButton):
	var idx := nodes.find(level)
	if idx < 0: return
	emit_signal("level_selected", levels[idx])

func _clear_all():
	for d in get_children():
		if d == $BackButton: continue
		remove_child(d)
	nodes = []

func _on_BackButton_pressed():
	if chapter_selected < 0:
		emit_signal("back_to_main")
	else:
		chapter_selected = -1
		_clear_all()
		_load_chapters()
