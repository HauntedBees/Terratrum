extends VBoxContainer
signal back_from_char_select
signal character_selected(c)

var char_sel:PackedScene = preload("res://Menu/CharSelButton.tscn")
onready var char_containers := [$Characters/Top, $Characters/Middle, $Characters/Bottom]
onready var group := ButtonGroup.new()

func set_characters(chars:Array):
	for cc in char_containers:
		for c in cc.get_children():
			c.queue_free()
	var chars_available := chars.size()
	var first_char:TextureButton = null
	for i in chars_available:
		var n:TextureButton = char_sel.instance()
		n.character = chars[i]
		n.group = group
		n.name = chars[i]
		if i == 0: first_char = n
		if i < 3 || chars_available <= 4 || (chars_available == 8 && i < 4):
			char_containers[1].add_child(n)
		elif chars_available <= 8 || (chars_available == 9 && i < 6):
			char_containers[0].add_child(n)
		else:
			char_containers[3].add_child(n)
	first_char.pressed = true

func _on_StartButton_pressed():
	if group.get_pressed_button() == null: return
	emit_signal("character_selected", group.get_pressed_button().name)
func _on_BackButton_pressed(): emit_signal("back_from_char_select")
