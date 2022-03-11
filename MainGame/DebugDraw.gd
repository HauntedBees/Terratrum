extends Node2D

onready var bc:Node2D = get_parent().get_node("BlockContainer")

func _ready():
	var t := Timer.new()
	t.wait_time = 0.25
	add_child(t)
	t.connect("timeout", self, "update")
	t.start()

func _draw():
	for vbf in bc.get_children():
		if !(vbf is BlockFamily): continue
		for vb in vbf.blocks:
			if !(vb is Block): continue
			var b:Block = vb as Block
			if b.above != null: draw_line(b.global_position + Vector2(2, 0), b.above.global_position, _ncolor(b, b.above, Color.blue), _nwidth(b, b.above))
			if b.right != null: draw_line(b.global_position - Vector2(0, 2), b.right.global_position, _ncolor(b, b.right, Color.green), _nwidth(b, b.right))
			if b.below != null: draw_line(b.global_position - Vector2(2, 0), b.below.global_position, _ncolor(b, b.below, Color.white), _nwidth(b, b.below))
			if b.left != null: draw_line(b.global_position + Vector2(0, 2), b.left.global_position, _ncolor(b, b.left, Color.red), _nwidth(b, b.left))

func _ncolor(a:Block, b:Block, c:Color) -> Color:
	if a.family == b.family: c = Color.rebeccapurple
	return c
func _nwidth(a:Block, b:Block) -> float: return 2.0 if a.family == b.family else 1.0
