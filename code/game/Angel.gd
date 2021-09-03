extends Node2D
onready var x := position.x
var character: AnimatedSprite
var time := 0.0
func _ready():
	add_child(character)
	character.animation = "angel"
	character.modulate.a = 0.5
func _process(delta):
	time += 5 * delta
	position.y -= Consts.BLOCK_SIZE * 2 * delta
	position.x = x + 10 * sin(time)
func _on_screen_exited(): queue_free()
