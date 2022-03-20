tool
extends NinePatchRect
class_name HUDValue

onready var k := $Key
onready var v := $Value

export var key := "Score" setget _set_key
func _set_key(t:String):
	key = t
	if k != null: k.text = key
export var val := "0" setget _set_val
func _set_val(t:String):
	val = t
	if v != null: v.text = val

func _ready():
	k.text = key
	v.text = val
