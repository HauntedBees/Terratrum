extends Node2D

signal touch_press(dir, drilling)
signal touch_release

const PRESS_DELAY := 0.5
const QTR_1 := PI / 4
const QTR_2 := QTR_1 * 2
const QTR_3 := QTR_1 * 3
#const FAIR_GAME := 30.0 # past this point, direction is unambiguous
const MAX_SIZE := 80.0
const PADDED_SIZE := MAX_SIZE * 1.5
onready var dirs := [$U, $L, $D, $R, $L2, $R2]
onready var base_position := to_global(Vector2(0, 0))
var one_handed := false
var pressed := false
var press_idx := -1
var is_touch := false
var press_position := Vector2(0, 0)
var drill_cooldown := 0.0

func _ready():
	$L2.visible = one_handed
	$R2.visible = one_handed

func in_box(pos: Vector2, size: float) -> bool: return abs(pos.x) <= size && abs(pos.y) <= size
func in_range(a, x, y): return a >= x && a <= y

func _input(event):
	if event is InputEventScreenTouch:
		is_touch = true
		var potential_position: Vector2 = event.position - base_position
		if event.pressed && press_idx == -1 && in_box(potential_position, MAX_SIZE):
			press_position = potential_position
			pressed = true
			press_idx = event.index
		elif !event.pressed && press_idx == event.index:
			pressed = false
			press_idx = -1
			emit_signal("touch_release")
	if event is InputEventMouseButton && !is_touch:
		pressed = event.pressed
		press_position = event.position - base_position
		if !pressed: emit_signal("touch_release")
	elif event is InputEventScreenDrag && press_idx == event.index:
		press_position = event.position - base_position
	elif event is InputEventMouseMotion && !is_touch:
		press_position = event.position - base_position

func _process(delta):
	drill_cooldown -= delta
	var in_bounds := pressed && in_box(press_position, PADDED_SIZE)
	
	var angle := press_position.angle()
	var abs_angle := abs(angle)
	var dir := Vector2(
		(-1 if in_range(abs_angle, QTR_3, PI) else 0) + (1 if in_range(abs_angle, 0, QTR_1) else 0),
		(-1 if in_range(angle, -QTR_3, -QTR_1) else 0) + (1 if in_range(angle, QTR_1, QTR_3) else 0)
	) if in_bounds else Vector2(0, 0)
	# auto-drill if looking up or down, or if pressing really far to the left or right
	var drilling := false
	if one_handed && ((abs(dir.x) > 0 && abs(press_position.x) >= MAX_SIZE) || dir.y != 0):
		if drill_cooldown <= 0.0:
			drilling = true
			drill_cooldown = PRESS_DELAY
		else:
			dir = Vector2(0, 0)
	
	$U.frame = 1 if dir.y < 0 else 0
	$D.frame = 1 if dir.y > 0 else 0
	$L.frame = 1 if dir.x == -1 else 0
	$L2.frame = 1 if dir.x == -2 else 0
	$R.frame = 1 if dir.x == 1 else 0
	$R2.frame = 1 if dir.x == 2 else 0
	
	if pressed && dir.length() > 0: emit_signal("touch_press", dir, drilling)
