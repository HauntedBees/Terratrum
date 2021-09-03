extends Node2D
class_name Block

const sprites = preload("res://assets/tiles/Tiles.tscn")
enum BlockState {
	INERT,
	WIGGLING,
	DROPPING,
	FADING,
	FADED
}

var type: String = "red"
var state = BlockState.INERT
onready var collider: StaticBody2D = $StaticBody2D
onready var sprite: AnimatedSprite = $Sprite
onready var cracks: AnimatedSprite = $Cracks
onready var tween: Tween = $Tween
var grid_pos: Vector2
var health := 1
var family := [self]

const color_xref = {
	red = Color(0.9, 0.4, 0.4),
	green = Color(0.4, 0.9, 0.4),
	yellow = Color(0.9, 0.9, 0.4),
	blue = Color(0.4, 0.4, 0.9)
}

func _ready():
	if !$VisibilityNotifier2D.is_on_screen(): hide() # will this make things faster on mobile
	if type == "air":
		sprite.animation = "air"
		collider.queue_free()
		collider = null
	elif type == "hard":
		sprite.animation = "nope"
		health = 5
	else:
		sprite.animation = "2"
		var color = color_xref[type]
		sprite.modulate = color

func can_be_stuck_to(): # TODO: wiggle may be a problem? maybe not but worth double checking
	return state == BlockState.INERT # || state == BlockState.WIGGLING

func wiggle_family():
	for b in family:
		b.wiggle()
func drop_family():
	for b in family:
		b.state = BlockState.DROPPING
func dissipate_family():
	for b in family:
		b.dissipate()

func stop(): state = BlockState.INERT

func damage_block_return_if_destroyed() -> bool:
	if state == BlockState.FADED || state == BlockState.FADING: return false
	health -= 1
	if type == "hard":
		cracks.visible = true
		cracks.frame = 4 - health
	return health <= 0

func wiggle():
	state = BlockState.WIGGLING
	var initial_pos := position
	for i in Consts.NUM_WIGGLES:
		var dir := 1 if i % 2 == 0 else -1
		move(Vector2(initial_pos.x + dir * 5, initial_pos.y), Consts.WIGGLE_TIME)
		yield(tween, "tween_completed")
		move(Vector2(initial_pos.x, initial_pos.y), Consts.WIGGLE_TIME)
		yield(tween, "tween_completed")
	position = initial_pos
	state = BlockState.DROPPING

func dissipate():
	state = BlockState.FADING
	tween.interpolate_property(self, "modulate:a", 1, 0, Consts.ACTION_TIME, Tween.TRANS_LINEAR)
	tween.start()
	yield(tween, "tween_completed")
	state = BlockState.FADED

func permanent_dissipation():
	if collider != null: collider.queue_free()
	state = BlockState.FADING
	tween.interpolate_property(self, "modulate:a", 1, 0, Consts.ACTION_TIME, Tween.TRANS_LINEAR)
	tween.start()
	yield(tween, "tween_completed")
	state = BlockState.FADED
	family = []
	queue_free()

func move(target: Vector2, speed: float):
	tween.interpolate_property(self, "position", position, target, speed, Tween.TRANS_LINEAR)
	tween.start()

func redraw_block():
	if type == "air": return
	var positions = [0, 0, 0, 0]
	for f in family:
		if self == f: continue
		var xdir: float = grid_pos.x - f.grid_pos.x # positive = left
		var ydir: float = grid_pos.y - f.grid_pos.y # positive = above
		if grid_pos.distance_to(f.grid_pos) != 1: continue
		if ydir < 0: # bottom
			positions[0] = 8
		elif ydir > 0: # top
			positions[1] = 1
		elif xdir < 0: # right
			positions[2] = 4
		elif xdir > 0: # left
			positions[3] = 2
	var final_value := 0
	for v in positions: final_value += v
	sprite.frame = final_value

func _on_VisibilityNotifier2D_screen_entered(): show()
func _on_VisibilityNotifier2D_screen_exited(): hide()
