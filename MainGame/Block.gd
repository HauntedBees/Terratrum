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

var family = null
var moving_families := false # this is set when joiningfamilies to stop _on_body_entered/exited calls

var type := "red"
var grid_pos := Vector2.ZERO
#var above:Block
#var right:Block
#var below:Block
#var left:Block

var mask_offset := 0

func calculate_mask_offset(above:Block, right:Block, below:Block, left:Block):
	if type == "air": return
	var final_value := 0
	if above != null && above.type == type: final_value += 1
	if right != null && right.type == type: final_value += 2
	if below != null && below.type == type: final_value += 4
	if left != null && left.type == type: final_value += 8
	mask_offset = final_value
	if is_inside_tree(): _set_shader()


func get_class(): return "Block"
func _ready():
	#if type == "hard" || type == "air": return
	shader = shader.duplicate()
	sprite.material = shader
	if type == "air": return
	sprite.modulate = COLOR_XREF[type]
	_set_shader()
func _set_shader(): shader.set_shader_param("mask_offset", Vector2(mask_offset % 4, mask_offset / 4))

func try_join_neighbors() -> bool:
	var linked := false
#	if above != null && try_link(above):
#		linked = true
#		above.redraw_block()
#	if right != null && _aligned(right) && try_link(right):
#		linked = true
#		right.redraw_block()
#	if below != null && try_link(below):
#		linked = true
#		below.redraw_block()
#	if left != null && _aligned(left) && try_link(left):
#		linked = true
#		left.redraw_block()
#	redraw_block()
	return linked
func try_link(neighbor:Block) -> bool:
	if type == "air": return false
	if neighbor == null: return false
	if neighbor.type != type: return false
	if neighbor.family== family: return false
	family.join(neighbor.family)
	return true
func _aligned(neighbor:Block) -> bool: return round(neighbor.global_position.y) == round(global_position.y)
func redraw_block():
	if type == "air": return
	var final_value := 0
#	if above != null && above.family == family: final_value += 1
#	if right != null && right.family == family: final_value += 2
#	if below != null && below.family == family: final_value += 4
#	if left != null && left.family == family: final_value += 8
#	shader.set_shader_param("mask_offset", Vector2(final_value % 4, final_value / 4))

func get_above_neighbor() -> Block: return self
#	if above == null: return null
#	if above.family == family: return null
#	return above.family
func is_at_bottom() -> bool: return grid_pos.y == 99

func flicker(): $AnimationPlayer.play("fade")
func pop():
	status = BlockStatus.POPPING # is prepop needed?
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
func move_down():
	grid_pos.y += 1
	try_join_neighbors()
	
func fall(amount:float, next_y:float) -> bool:
	# fucking rounding
	position.y = stepify(position.y + Consts.FALL_TIME * Consts.BLOCK_SIZE * amount, 0.1)
	if position.y >= next_y:
		grid_pos.y += 1
		return true
	else: return false

func is_dead() -> bool:
	return [BlockStatus.PREPOP, BlockStatus.POPPING, BlockStatus.POPPED].has(status)

func _on_Above_area_entered(area:Area2D): _on_body_entered(area, 1)
func _on_Right_area_entered(area:Area2D): _on_body_entered(area, 2)
func _on_Below_area_entered(area:Area2D): _on_body_entered(area, 4)
func _on_Left_area_entered(area:Area2D): _on_body_entered(area, 8)
func _on_body_entered(body:Node, dir:int):
	if moving_families: return
	var parent := body.get_parent()
	if parent == null: return
	if parent == self: return
	if parent.get_class() != "Block": return
	if dir < 0: return
#	match dir:
#		1:
#			if above != null: above.below = null
#			above = parent
#			parent.below = self
#		2:
#			if right != null: right.left = null
#			right = parent
#			parent.left = self
#		4:
#			if below != null: below.above = null
#			below = parent
#			parent.above = self
#		8:
#			if left != null: left.right = null
#			left = parent
#			parent.right = self

func _on_Above_area_exited(area:Area2D): _on_body_exited(area, 1)
func _on_Right_area_exited(area:Area2D): _on_body_exited(area, 2)
func _on_Below_area_exited(area:Area2D): _on_body_exited(area, 4)
func _on_Left_area_exited(area:Area2D): _on_body_exited(area, 8)
func _on_body_exited(body:Node, dir:int) -> bool:
	if moving_families: return false
	var parent := body.get_parent()
	if parent == null: return false
	if parent == self: return false
	if parent.get_class() != "Block": return false
	return dir < 0
#	var current_neighbor:Block = null
#	match dir:
#		1: current_neighbor = above
#		2: current_neighbor = right
#		4: current_neighbor = below
#		8: current_neighbor = left
#	if current_neighbor == parent:
#		match dir:
#			1: above = null
#			2: right = null
#			4: below = null
#			8: left = null
#		return true
#	else: return false

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
