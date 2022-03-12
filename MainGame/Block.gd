extends Node2D
class_name Block

enum BlockStatus { NONE, PREFALL, FALL, FELL, FALLSTOP, PREPOP, POPPING, POPPED }
enum DropStatus { CAN_FALL, MAYBE_FALL, ABOVE_WIGGLE, CANNOT_FALL }
var status:int = BlockStatus.NONE
var drop_status:int = DropStatus.CANNOT_FALL
var was_counted := false
var drop_iter:int = 0
var empty := false
var pop_time := 0.0
var wiggle_time := 0.0

const COLOR_XREF = {
	"red": Color(0.9, 0.4, 0.4),
	"green": Color(0.4, 0.9, 0.4),
	"yellow": Color(0.9, 0.9, 0.4),
	"blue": Color(0.4, 0.4, 0.9),
	"hard": Color(0.2, 0.2, 0.2)
}

onready var sprite := $AnimatedSprite
onready var shader:ShaderMaterial = sprite.material

var type := "red"
var grid_pos := Vector2.ZERO
var mask_offset := 0
var dark_offset := 0
var show_dark := false

func calculate_mask_offset(above:Block, right:Block, below:Block, left:Block):
	if type == "air": return
	var final_value := 0
	var dark_value := 0
	show_dark = true
	if above != null && above.type == type:
		final_value += 1
		dark_value += 1
	if right != null && right.type == type:
		final_value += 2
		show_dark = false
	if below != null && below.type == type:
		final_value += 4
		dark_value += 2
	if left != null && left.type == type: final_value += 8
	mask_offset = final_value
	dark_offset = dark_value
	
	if is_inside_tree(): _set_shader()


func get_class(): return "Block"
func _ready():
	#if type == "hard" || type == "air": return
	shader = shader.duplicate()
	sprite.material = shader
	if type == "air": return
	sprite.modulate = COLOR_XREF[type]
	_set_shader()
func _set_shader():
	shader.set_shader_param("mask_offset", Vector2(mask_offset % 4, mask_offset / 4))
	shader.set_shader_param("dark_offset", Vector2(dark_offset % 2, dark_offset / 2))
	shader.set_shader_param("show_dark", 1.0 if show_dark else 0.0)

func pop():
	status = BlockStatus.POPPING # is prepop needed?
	drop_status = DropStatus.CANNOT_FALL
	pop_time = Consts.POP_TIME
	$AnimationPlayer.play("fade")
func finish_pop():
	status = BlockStatus.POPPED
	queue_free()
func wiggle():
	wiggle_time = Consts.WIGGLE_TIME
	status = BlockStatus.PREFALL
	$AnimationPlayer.play("wiggle")
func pre_fall():
	wiggle_time = Consts.POP_TIME
	status = BlockStatus.PREFALL
func fall(amount:float, next_y:float) -> bool:
	# fucking rounding
	position.y = stepify(position.y + Consts.FALL_TIME * Consts.BLOCK_SIZE * amount, 0.1)
	if position.y >= next_y:
		grid_pos.y += 1
		return true
	else: return false

func is_dead() -> bool:
	return [BlockStatus.PREPOP, BlockStatus.POPPING, BlockStatus.POPPED].has(status)

# Debug Stuff
signal debug_kill
var mouse := false
func _on_Center_mouse_entered(): mouse = true
func _on_Center_mouse_exited(): mouse = false
func _input(e:InputEvent):
	if mouse && e is InputEventMouseButton && e.button_index == 2 && e.pressed:
		if Input.is_key_pressed(KEY_SHIFT):
			print(name)
		else:
			emit_signal("debug_kill")
