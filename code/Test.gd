extends Node2D

func _ready():
	$Block2.sprite.frame = 8
	$Block3.sprite.frame = 4

func _process(_delta):
	if Input.is_key_pressed(KEY_Z):
		$Block.dissipate()
		$Block2.dissipate()
		$Block3.dissipate()

# CHAINED BLOCKS FLICKER THEN POP
# DRILLED BLOCKS JUST POP
