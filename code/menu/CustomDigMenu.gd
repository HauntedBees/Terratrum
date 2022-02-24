extends Node2D
signal back_press

onready var col_btns := ButtonGroup.new()

func _on_MenuGoBack_back_select(): emit_signal("back_press")

func _ready():
	$Columns/Col5.set_button_group(col_btns)
	$Columns/Col7.set_button_group(col_btns)
	$Columns/Col9.set_button_group(col_btns)
	$Columns/Col7.grab_focus()
	$MenuGoBack.text = tr("MODE_CUSTOM_NAME")
