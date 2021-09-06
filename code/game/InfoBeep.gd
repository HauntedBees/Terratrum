extends Node2D

const RISE_SPEED := 125.0
const X_RANGE: = 15.0
const X_DELTA := 5.0
const MAX_TIME := 1.0

var msg := "+20"
var mode := 0 # 0 = float up, 1 = flicker for MAX_TIME seconds
var elapsed_time := 0.0
onready var base_x := position.x

func _ready():
	$Label.text = msg
	$Label.modulate = Color.green if mode == 0 else Color.red

func _process(delta):
	elapsed_time += delta
	if mode == 0:
		position.x = base_x + X_RANGE * sin(elapsed_time * X_DELTA)
		position.y -= RISE_SPEED * delta
	else:
		modulate.a = 1 if int(6 * elapsed_time) % 2 == 0 else 0
		if elapsed_time >= MAX_TIME: queue_free()

func _on_screen_exited(): queue_free()
