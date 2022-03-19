extends Node2D

onready var lm:LevelManager2 = get_parent().get_parent().get_node("LevelManager")
onready var l:Label = get_parent().get_node("Label")
const BOX_SIZE := 8.0
const INFO_SIZE := 2.0
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
			_draw_debug(x, y)

func _draw_debug(x:int, y:int):
	var b:Block2 = lm.get_block(x, y)
	if b == null: return
	var sx := Vector2(0, 0)
	match b.state:
		Block2.State.NONE: sx = Vector2(0, 0)
		Block2.State.PREFALL: sx = Vector2(4, 0)
		Block2.State.FALLING: sx = Vector2(0, 4)
		Block2.State.POSTFALL: sx = Vector2(2, 2)
		Block2.State.POPPING: sx = Vector2(4, 4)
		Block2.State.POPPED: sx = Vector2(8, 8)
	draw_rect(Rect2(DX + x * BOX_SIZE + sx.x, DY + y * BOX_SIZE + sx.y, INFO_SIZE, INFO_SIZE), Color.black)

func _get_color(b:Block2):
	if b == null: return Color(0, 0, 0, 0)
	if b.type == "air": return Color.white
	var color:Color = b.COLOR_XREF[b.type]
	if b.state == Block.BlockStatus.POPPING || b.state == Block.BlockStatus.POPPED: color.a *= 0.5
	return color
