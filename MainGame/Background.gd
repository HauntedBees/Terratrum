extends ParallaxBackground

onready var top := $TopLayer/TopSprite
onready var bottom := $BottomLayer/BottomSprite

var background_idx := 1
func _ready():
	print("%02d" % background_idx)
	top.texture = load("res://MainGame/Backgrounds/%02d_top.png" % background_idx)
	bottom.texture = load("res://MainGame/Backgrounds/%02d_bottom.png" % background_idx)
