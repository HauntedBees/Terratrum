extends Node2D

onready var bc:Node2D = get_parent().get_node("BlockContainer")

func _ready():
	var t := Timer.new()
	t.wait_time = 0.25
	add_child(t)
	t.connect("timeout", self, "update")
	t.start()

func _draw():
	for vb in bc.get_children():
		if !(vb is Block): continue
		var b:Block = vb as Block
		if b.left != null: draw_line(b.global_position + Vector2(0, 2), b.left.global_position, Color.red, 2.0)
		if b.right != null: draw_line(b.global_position - Vector2(0, 2), b.right.global_position, Color.blue, 2.0)
		if b.above != null: draw_line(b.global_position + Vector2(2, 0), b.above.global_position, Color.green, 2.0)
		if b.below != null: draw_line(b.global_position - Vector2(2, 0), b.below.global_position, Color.black, 2.0)
