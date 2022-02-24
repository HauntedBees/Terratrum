class_name DualButton
extends Control

signal pressed(s)

onready var a := $AnimationPlayer
onready var main_node := $MarginContainer/VBoxContainer/Text
onready var subtitle_node := $MarginContainer/VBoxContainer/Subtitle
var main_text := "" setget set_main_text
var subtitle_text := "" setget set_subtitle

func _ready():
	set_main_text(main_text)
	set_subtitle(subtitle_text)
	_resize()
func set_main_text(t:String):
	main_text = " %s  " % t
	if main_node != null: main_node.text = t
func set_subtitle(t:String):
	subtitle_text = "   %s " % t
	if subtitle_node != null: subtitle_node.text = t
func _resize():
	rect_pivot_offset = rect_size / 2.0 # TODO: AAAAAAAAAAAAAAAAAAAAAAAAAAA

func _on_Button_mouse_entered(): pass#a.play("MenuHover") # TODO: AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
func _on_Button_mouse_exited():
	a.stop()
	rect_scale = Vector2(1, 1)
func _on_Button_pressed():
	a.play("MenuSelect")
	emit_signal("pressed", self)
