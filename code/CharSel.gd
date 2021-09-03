extends AnimatedSprite
class_name CharSel
signal char_change

const characters := ["Mole", "Prairie", "Jerboa", "Tortoise"]
var character: String = "Mole"
var selected: bool = false
onready var selected_frame := $Selected
func _ready():
	frame = characters.find(character)
	selected_frame.modulate.a = 0.5 if selected else 0.0
func toggle_select(new_val: bool):
	selected = new_val
	if new_val:
		selected_frame.modulate.a = 0.5
	else:
		selected_frame.modulate.a = 0

func _on_Selected_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1:
			emit_signal("char_change")
