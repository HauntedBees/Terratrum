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

func try_link(neighbor:Block):
	if neighbor == null: return
	if neighbor.type != type: return
	if neighbor.family == family: return
	family.join(neighbor.family)

func redraw_block():
	if type == "air": return
	var positions = [0, 0, 0, 0]
	for f in family.list():
		if self == f: continue
		var xdir: float = grid_pos.x - f.grid_pos.x # positive = left
		var ydir: float = grid_pos.y - f.grid_pos.y # positive = above
		if grid_pos.distance_to(f.grid_pos) != 1: continue
		if ydir < 0: # bottom
			positions[0] = 4
		elif ydir > 0: # top
			positions[1] = 1
		elif xdir < 0: # right
			positions[2] = 2
		elif xdir > 0: # left
			positions[3] = 8
	var final_value := 0
	for v in positions: final_value += v
	shader.set_shader_param("mask_offset", Vector2(final_value % 4, final_value / 4))

func get_class(): return "Block"
func unlink_neighbors():
	if left != null && is_instance_valid(left): left.right = null
	if right != null && is_instance_valid(right): right.left = null
	if above != null && is_instance_valid(above): above.below = null
	if below != null && is_instance_valid(below): below.above = null

func _on_Above_body_entered(body:Node): _on_body_entered(body, 1)
func _on_Right_body_entered(body:Node): _on_body_entered(body, 2)
func _on_Below_body_entered(body:Node): _on_body_entered(body, 4)
func _on_Left_body_entered(body:Node): _on_body_entered(body, 8)
func _on_body_entered(body:Node, dir:int):
	var parent := body.get_parent()
	if parent == null: return
	if parent.get_class() != "Block": return
	match dir:
		1: above = parent
		2: right = parent
		4: below = parent
		8: left = parent

func _on_Above_body_exited(body:Node): pass#_on_body_exited(body, 1)
func _on_Right_body_exited(body:Node): pass#_on_body_exited(body, 2)
func _on_Below_body_exited(body:Node): pass#_on_body_exited(body, 4)
func _on_Left_body_exited(body:Node): pass#_on_body_exited(body, 8)
func _on_body_exited(body:Node, dir:int):
	var parent := body.get_parent()
	if parent == null: return
	if parent.get_class() != "Block": return
#	match dir:
#		1: above = null
#		2: right = null
#		4: below = null
#		8: left = null
#	var parent := body.get_parent()
#	if parent == null: return
#	if parent.get_class() != "Block": return
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
#	else:
#		print("this shouldn't happen I don't think")
#		print("%s / %s" % [current_neighbor, parent])

func _on_Above_area_entered(area:Area2D): _on_body_entered(area, 1)
func _on_Right_area_entered(area:Area2D): _on_body_entered(area, 2)
func _on_Below_area_entered(area:Area2D): _on_body_entered(area, 4)
func _on_Left_area_entered(area:Area2D): _on_body_entered(area, 8)

func _on_Above_area_exited(area:Area2D): _on_body_exited(area, 1)
func _on_Right_area_exited(area:Area2D): _on_body_exited(area, 2)
func _on_Below_area_exited(area:Area2D): _on_body_exited(area, 4)
func _on_Left_area_exited(area:Area2D): _on_body_exited(area, 8)
