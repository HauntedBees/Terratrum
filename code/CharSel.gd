extends AnimatedSprite
class_name CharSel
signal char_change

const characters := ["Mole", "Prairie", "Jerboa", "Tortoise", "Fish", "Groundhog", "Pangolin", "Owl", "Robot", "Spider"]
var character: String = "Mole"
func _ready(): frame = characters.find(character)
func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton && event.button_index == 1 && !event.pressed:
		emit_signal("char_change")
