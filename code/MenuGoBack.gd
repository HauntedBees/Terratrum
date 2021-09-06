extends Node2D
signal back_select
func _on_Button_pressed(): emit_signal("back_select")
var text = "Gamer" setget set_text
func set_text(t: String):
	text = t
	$MainLabel.bbcode_text = "[center]%s[/center]" % t
	$LabelBack.bbcode_text = "[center]%s[/center]" % t
