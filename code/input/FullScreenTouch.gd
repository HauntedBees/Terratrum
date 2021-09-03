extends Node2D
class_name FullScreenTouch

signal touch_press(type)
signal end_touch

enum InputState {
	None,
	Down,
	Left,
	Right,
	Up,
	Center,
	Drill
}

var pressed = InputState.None

func handle_press(event: InputEventMouse, new_dir):
	if !(event is InputEventMouseButton): return
	print(new_dir)
	if event.pressed:
		pressed = new_dir
		emit_signal("touch_press", new_dir)
	else:
		pressed = InputState.None
		emit_signal("end_touch")

func handle_enter(new_dir): 
	if pressed == InputState.None || pressed == new_dir: return
	pressed = new_dir
	emit_signal("touch_press", new_dir)

func handle_exit(old_dir):
	if pressed != old_dir: return
	pressed = InputState.None
	emit_signal("end_touch")

func _on_Bottom_input_event(_viewport, event, _shape_idx): handle_press(event, InputState.Down)
func _on_Left_input_event(_viewport, event, _shape_idx): handle_press(event, InputState.Left)
func _on_Right_input_event(_viewport, event, _shape_idx): handle_press(event, InputState.Right)
func _on_Up_input_event(_viewport, event, _shape_idx): handle_press(event, InputState.Up)
func _on_Center_input_event(_viewport, event, _shape_idx): handle_press(event, InputState.Center)

func _on_Bottom_mouse_entered(): handle_enter(InputState.Down)
func _on_Left_mouse_entered(): handle_enter(InputState.Left)
func _on_Right_mouse_entered(): handle_enter(InputState.Right)
func _on_Up_mouse_entered(): handle_enter(InputState.Up)
func _on_Center_mouse_entered(): handle_enter(InputState.Center)

func _on_Bottom_mouse_exited(): handle_exit(InputState.Down)
func _on_Left_mouse_exited(): handle_exit(InputState.Left)
func _on_Right_mouse_exited(): handle_exit(InputState.Right)
func _on_Up_mouse_exited(): handle_exit(InputState.Up)
func _on_Center_mouse_exited(): handle_exit(InputState.Center)

func _process(_delta):
	match pressed:
		InputState.Left: $Label.text = "Left"
		InputState.Down: $Label.text = "Down"
		InputState.Right: $Label.text = "Right"
		InputState.Up: $Label.text = "Up"
		InputState.Center: $Label.text = "_"
		_: $Label.text = ""
