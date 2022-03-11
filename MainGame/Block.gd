extends Node2D
class_name Block

enum DropStatus { CAN_FALL, MAYBE_FALL, ABOVE_WIGGLE, CANNOT_FALL }

onready var sprite := $AnimatedSprite
onready var shader:ShaderMaterial = sprite.material
var family := BlockFamily.new(self)
var family2 = null

var type := "red"
var grid_pos := Vector2.ZERO
var above:Block
var right:Block
var below:Block
var left:Block
var moving_families := false

const COLOR_XREF = {
	"red": Color(0.9, 0.4, 0.4),
	"green": Color(0.4, 0.9, 0.4),
	"yellow": Color(0.9, 0.9, 0.4),
	"blue": Color(0.4, 0.4, 0.9),
	"hard": Color(0.2, 0.2, 0.2)
}

func _ready():
	#if type == "hard" || type == "air": return
	shader = shader.duplicate()
	sprite.material = shader
	if type == "air": return
	sprite.modulate = COLOR_XREF[type]

func try_link(neighbor:Block) -> bool:
	if type == "air": return false
	if neighbor == null: return false
	if neighbor.type != type: return false
	if neighbor.family == family: return false
	family2.join(neighbor.family2)
	family.join(neighbor.family)
	return true

func get_above_neighbor() -> Block:
	if above == null: return null
	if above.family2 == family2: return null
	return above.family2

func try_join_neighbors() -> bool:
	var linked := false
	if above != null && try_link(above):
		linked = true
		above.redraw_block()
	if right != null && _aligned(right) && try_link(right):
		linked = true
		right.redraw_block()
	if below != null && try_link(below):
		linked = true
		below.redraw_block()
	if left != null && _aligned(left) && try_link(left):
		linked = true
		left.redraw_block()
	redraw_block()
	return linked
func _aligned(neighbor:Block) -> bool: return round(neighbor.global_position.y) == round(global_position.y)

func flicker(): $AnimationPlayer.play("fade")
func wiggle(): $AnimationPlayer.play("wiggle")
func redraw_block():
	if type == "air": return
	var final_value := 0
	if above != null && above.family2 == family2: final_value += 1
	if right != null && right.family2 == family2: final_value += 2
	if below != null && below.family2 == family2: final_value += 4
	if left != null && left.family2 == family2: final_value += 8
	shader.set_shader_param("mask_offset", Vector2(final_value % 4, final_value / 4))

func get_class(): return "Block"
func unlink_neighbors():
	if left != null && is_instance_valid(left): left.right = null
	if right != null && is_instance_valid(right): right.left = null
	if above != null && is_instance_valid(above): above.below = null
	if below != null && is_instance_valid(below): below.above = null
func move_down():
	grid_pos.y += 1
	try_join_neighbors()

func can_reach(b:Block) -> bool:
	if grid_pos.y > b.grid_pos.y: return false
	if b.below == null: return false
	return b.below.can_reach(b)


var dead := false
var player_popped := false
func kill(from_player:bool):
	family = null
	dead = true
	player_popped = from_player
	#unlink_neighbors()
	queue_free()

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
	match dir:
		1:
			if above != null: above.below = null
			above = parent
			parent.below = self
		2:
			if right != null: right.left = null
			right = parent
			parent.left = self
		4:
			if below != null: below.above = null
			below = parent
			parent.above = self
		8:
			if left != null: left.right = null
			left = parent
			parent.right = self

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
	var current_neighbor:Block = null
	match dir:
		1: current_neighbor = above
		2: current_neighbor = right
		4: current_neighbor = below
		8: current_neighbor = left
	if current_neighbor == parent:
		match dir:
			1: above = null
			2: right = null
			4: below = null
			8: left = null
		return true
	else: return false

func get_drop_info(can_drops:Array, cant_drops:Array, potential_falls:Array) -> int:
	# if it's at the bottom of the level, it can't fall! 
	if _is_at_bottom(): return DropStatus.CANNOT_FALL
	# if there's nothing below a block, it can fall
	if below == null: return DropStatus.CAN_FALL
	# if it's right above the bottom of the level, it can't fall! 
	if below._is_at_bottom(): return DropStatus.CANNOT_FALL
	# if this block is family, it doesn't matter!
	if below.family == family: return DropStatus.CAN_FALL
	# if the below block is dying, give it a minute!
	if below.family == null: return DropStatus.CAN_FALL # this probably shouldn't happen!
	if below.family.dying: return DropStatus.CANNOT_FALL
	# if a wiggling block is below a block, report that
	if below.family.wiggle_time > 0.0: return DropStatus.ABOVE_WIGGLE
	# if a known falling block is below a block, it can fall
	if can_drops.has(below.family): return DropStatus.CAN_FALL
	# if a known stuck block is below a block, it can't fall
	if cant_drops.has(below.family): return DropStatus.CANNOT_FALL
	# if a block that was never likely to fall is below a block, it can't fall
	# (this and the previous comparison probably have some overlap)
	if !potential_falls.has(below.family): return DropStatus.CANNOT_FALL
	# if the block below this can MAYBE fall, let's check again later
	return DropStatus.MAYBE_FALL
func _is_at_bottom() -> bool: return grid_pos.y == 99 # this is probably right

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
