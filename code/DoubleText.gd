tool
extends Node2D

export var text: String setget set_text
func set_text(t: String):
	text = t
	if Engine.editor_hint:
		$Label.text = t
		$Label2.text = t

func _ready():
	$Label.text = text
	$Label2.text = text
