extends PanelContainer

onready var label := $RichTextLabel

var text := "" setget _set_text
func _set_text(t:String):
	text = t
	if label != null: label.bbcode_text = "[center]%s[/center]" % text

func _ready(): _set_text(text)
