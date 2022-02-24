extends Button

onready var a := $AnimationPlayer

func _ready(): rect_pivot_offset = rect_size / 2
func _on_mouse_entered(): a.play("hover")
func _on_mouse_exited():
	a.stop()
	rect_scale = Vector2(1, 1)
func _on_NiceButton_pressed(): a.play("select")
