extends Node2D
class_name HUDText

onready var value_label := $Value
onready var max_depth := $MaxDepth
export(String, "text", "int", "time", "depth") var type := "text"
export(String) var label := "Score"
export(int) var max_value := 0 # optional; for depth only 
var value = null

func _ready():
	$Label.text = label# + ":"
	max_depth.text = ""
	update_value()

#TODO: handle max depth

func set_value(new_val):
	value = new_val
	update_value()

# deprecated
func _on_value_change(new_val):
	value = new_val
	update_value()

func update_value():
	match type:
		"text": value_label.text = "" if value == null else value
		"int": value_label.text = int_str(value)
		"time": value_label.text = time_str()
		"depth":
			value_label.text = int_str(value) + "m"# + ("" if max_value == 0 else ("/%sm" % int_str(max_value)))
			max_depth.text = "" if max_value == 0 else "/%sm" % int_str(max_value)

func int_str(i) -> String:
	if i == null: return "0"
	if i < 0: return "-%s" % int_str(i)
	var num_val := int(min(i, 99999))
	var output := ""
	while num_val > 999:
		output = ",%03d%s" % [num_val % 1000, output]
		num_val /= 1000
	return "%s%s" % [num_val, output]

func time_str() -> String:
	if value == null: return "00:00:00"
	var int_val = int(value)
	var seconds: int = int_val % 60
	var remainder: int = int_val / 60
	var minutes: int = remainder % 60
	var hours: int = remainder / 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]


func _on_set_max_depth(depth): max_value = depth
