extends Spatial

onready var t := $Terral
onready var egg := $TerralEgg

func _ready():
	pass

func _process(delta):
	t.rotation_degrees.y += 100.0 * delta

func _on_Sun_value_changed(value):
	t.data.sun = int(value / 10.0)
	t.redraw()

func _on_Sea_value_changed(value):
	t.data.sea = int(value / 10.0)
	t.redraw()

func _on_Shock_value_changed(value):
	t.data.shock = int(value / 10.0)
	t.redraw()

func _on_Stone_value_changed(value):
	t.data.stone = int(value / 10.0)
	t.redraw()

func _on_Plant_value_changed(value):
	t.data.plant = int(value / 10.0)
	t.redraw()
