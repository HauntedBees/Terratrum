extends Node2D

signal btn_press(key)

onready var base_position := to_global(Vector2(0, 0))
onready var text_position: float = $TextContainer.position.y #to_global($TextContainer.position).y
onready var text_pressed_position := text_position + 16.0 * scale.y
onready var max_size := 200.0 * scale.x
var pressed := false
var press_idx := -1
var is_touch := false
export var key := "Drill"

func _ready():
	modulate.a = 0.5

func _input(event):
	if event is InputEventScreenTouch:
		is_touch = true
		if !in_range(event.position - base_position): return
		if event.pressed && press_idx == -1:
			pressed = true
			press_idx = event.index
			emit_signal("btn_press", key)
		elif !event.pressed && press_idx == event.index:
			pressed = false
			press_idx = -1
	elif event is InputEventMouseButton && !is_touch:
		if !in_range(event.position - base_position): return
		pressed = event.pressed
		if pressed: emit_signal("btn_press", key)
	elif event is InputEventMouseMotion:
		if !in_range(event.position - base_position):
			pressed = false

func in_range(pos: Vector2) -> bool: return abs(pos.x) <= max_size && abs(pos.y) <= max_size

func _process(_delta):
	$Btn.frame = 1 if pressed else 0
	$TextContainer.position.y = text_pressed_position if pressed else text_position
