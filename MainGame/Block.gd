extends Node2D
class_name Block

onready var sprite := $AnimatedSprite
onready var shader:ShaderMaterial = sprite.material
var family := BlockFamily.new(self)

var type := "red"
var grid_pos := Vector2.ZERO
var above:Block
var right:Block
var below:Block
var left:Block

const COLOR_XREF = {
	"red": Color(0.9, 0.4, 0.4),
	"green": Color(0.4, 0.9, 0.4),
	"yellow": Color(0.9, 0.9, 0.4),
	"blue": Color(0.4, 0.4, 0.9),
	"hard": Color(0.2, 0.2, 0.2)
}

func _ready():
	#if type == "hard" || type == "air": return
	if type == "air": return
	sprite.modulate = COLOR_XREF[type]
	shader = shader.duplicate()
	sprite.material = shader

func try_link(neighbor:Block) -> bool:
	if type == "air": return false
	if neighbor == null: return false
	if neighbor.type != type: return false
	if neighbor.family == family: return false
	family.join(neighbor.family)
	return true

func try_join_neighbors():
	if above != null && try_link(above): above.redraw_block()
	if right != null && _aligned(right) && try_link(right): right.redraw_block()
	if below != null && try_link(below): below.redraw_block()
	if left != null && _aligned(left) && try_link(left): left.redraw_block()
	redraw_block()
func _aligned(neighbor:Block) -> bool: return round(neighbor.global_position.y) == round(global_position.y)

func flicker(): $AnimationPlayer.play("fade")
func redraw_block():
	if type == "air": return
	var final_value := 0
	if above != null && above.family == family: final_value += 1
	if right != null && right.family == family: final_value += 2
	if below != null && below.family == family: final_value += 4
	if left != null && left.family == family: final_value += 8
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

func _on_Above_area_entered(area:Area2D): _on_body_entered(area, 1)
func _on_Right_area_entered(area:Area2D): _on_body_entered(area, 2)
func _on_Below_area_entered(area:Area2D): _on_body_entered(area, 4)
func _on_Left_area_entered(area:Area2D): _on_body_entered(area, 8)
func _on_body_entered(body:Node, dir:int):
	var parent := body.get_parent()
	if parent == null: return
	if parent == self: return
	if parent.get_class() != "Block": return
	#if parent.family == family: return
	match dir:
		1:
			if above != null: above.below = null
			above = parent
			parent.below = self
			try_link(parent)
			redraw_block()
			parent.redraw_block()
		2:
			if right != null: right.left = null
			right = parent
			parent.left = self
		4:
			if below != null: below.above = null
			below = parent
			parent.above = self
			try_link(parent)
			redraw_block()
			parent.redraw_block()
		8:
			if left != null: left.right = null
			left = parent
			parent.right = self

func _on_Above_area_exited(area:Area2D): _on_body_exited(area, 1)
func _on_Right_area_exited(area:Area2D): _on_body_exited(area, 2)
func _on_Below_area_exited(area:Area2D): _on_body_exited(area, 4)
func _on_Left_area_exited(area:Area2D): _on_body_exited(area, 8)
func _on_body_exited(body:Node, dir:int):
	var parent := body.get_parent()
	if parent == null: return
	if parent == self: return
	if parent.get_class() != "Block": return
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
