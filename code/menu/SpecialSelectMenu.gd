extends Node2D
signal back_press
signal selected_option(option)

const level_sel = preload("res://scenes/menu/MenuLevel.tscn")
const options := ["CORES", "BOSS", "KEY", "MACHINE", "CUSTOM"]

func _ready():
	$MenuGoBack.text = tr("MODE_SPECIAL_NAME")
	for i in range(0, options.size()):
		var option: String = options[i]
		var l = level_sel.instance()
		l.connect("chosen", self, "_on_mode_selected", [l, i])
		l.mode = MenuLevel.DisplayMode.StoryChapter
		l.label_text = tr("MODE_%s_NAME" % option)
		l.subtitle_text = tr("MODE_%s_DESC" % option)
		l.position.y = Consts.MENU_TOP_HEIGHT + Consts.MENULEVEL_HEIGHT * i
		add_child(l)

func _on_mode_selected(sel: MenuLevel, idx: int):
	print(sel) # TODO make it light up or some shit
	emit_signal("selected_option", options[idx])

func _on_MenuGoBack_back_select(): emit_signal("back_press")

func blur(): pass
func unblur(): pass
