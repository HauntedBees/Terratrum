extends Node2D

onready var lm:LevelManager2 = get_parent().get_parent().get_node("LevelManager")
onready var l:Label = get_parent().get_node("Label")
const BOX_SIZE := 4.0
const DX := 20.0
const DY := 50.0

func _ready():
	var t := Timer.new()
	t.wait_time = 0.25
	add_child(t)
	t.connect("timeout", self, "update")
	t.start()
func _draw():
	l.text = "%sFPS / [%s, %s]" % [Engine.get_frames_per_second(), lm.min_y, lm.max_y]
	for y in lm.height:
		for x in lm.width:
			draw_rect(Rect2(DX + x * BOX_SIZE, DY + y * BOX_SIZE, BOX_SIZE, BOX_SIZE), _get_color(lm.get_block(x, y)))
func _get_color(b:Block2):
	if b == null: return Color(0, 0, 0, 0)
	if b.type == "air": return Color.white
	var color:Color = b.COLOR_XREF[b.type]
	#if b.is_dead(): color.a *= 0.5
	if b.state == Block.BlockStatus.POPPING || b.state == Block.BlockStatus.POPPED: color.a *= 0.5
	return color
