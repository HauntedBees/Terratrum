extends KinematicBody2D

onready var model := $Viewport/character
onready var camera := $Camera2D
onready var camera_x:float = camera.global_position.x

var walk_speed := 10000.0#Consts.WALK_SPEED
var active_direction := Vector2(0, 1)
var character := "Mole"
var climb_left := []
var climb_right := []
var above:Block
var right:Block
var below:Block
var left:Block

var climb_limit := 0.0
var forced_steps := []

class ForcedStep:
	var new_pos:float
	var dir:int
	func _init(direction:int, new_position:float):
		dir = direction
		new_pos = new_position

func _process(_delta): camera.global_position.x = camera_x

func _physics_process(delta:float):
	if forced_steps.size() > 0:
		_do_climb(delta)
		return
	
	var direction := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	if direction != Vector2.ZERO:
		if direction.x != 0: direction.y = 0 # no diagonals allowed!
		model.look_at(model.global_transform.origin - 10 * Vector3(direction.x, 0, direction.y), Vector3.UP)
		active_direction = Vector2(round(direction.x), round(direction.y))
	
	var velocity := Vector2(direction.x, 0)
	velocity = velocity.normalized()
	velocity = walk_speed * delta * velocity
	if !is_on_floor(): velocity.y += Consts.BLOCK_SIZE * Consts.DROP_SPEED * delta
	move_and_slide(velocity, Vector2.UP)
	_try_climb(direction, delta)

func _try_climb(direction:Vector2, delta:float):
	var collisions := get_slide_count()
	var target:Block = left if direction.x < 0 else right
	var goal:Array = climb_left if direction.x < 0 else climb_right
	if direction.x == 0 || collisions == 0 || target == null || goal.size() > 0:
		climb_limit = 0.0
		return
	var collider:Block = null
	for i in collisions:
		var col := _get_collision_object(i)
		if col is Block: collider = col
	if collider == null || target != collider:
		climb_limit = 0.0
		return
	climb_limit += delta
	if climb_limit >= Consts.TIME_TO_TRIGGER_CLIMB:
		forced_steps.append(ForcedStep.new(1, position.y - Consts.BLOCK_SIZE))
		var move_dir:int = 8 if direction.x < 0 else 2
		forced_steps.append(ForcedStep.new(move_dir, position.x + Consts.BLOCK_SIZE * sign(direction.x)))
func _do_climb(delta:float):
	var step:ForcedStep = forced_steps[0]
	var direction:float = -1.0 if (step.dir == 1 || step.dir == 8) else 1.0
	var amount := direction * Consts.BLOCK_SIZE * Consts.CLIMB_STEP_TIME * delta
	if step.dir == 1 || step.dir == 4:
		position.y += amount
		if (step.dir == 1 && position.y <= step.new_pos) || (step.dir == 4 && position.y >= step.new_pos):
			forced_steps.remove(0)
	else:
		position.x += amount
		if (step.dir == 8 && position.x <= step.new_pos) || (step.dir == 2 && position.x >= step.new_pos):
			forced_steps.remove(0)
func _get_collision_object(idx:int) -> Node:
	var collision_info := get_slide_collision(idx)
	if collision_info == null: return null
	var collision_shape := collision_info.collider_shape
	if collision_shape == null: return null
	if !(collision_shape is CollisionPolygon2D || collision_shape is CollisionShape2D): return null
	var collision_body:CollisionObject2D = collision_shape.get_parent()
	if collision_body == null: return null
	return collision_body.get_parent()

func _on_Above_area_entered(area:Area2D): _on_body_entered(area, 1)
func _on_Right_area_entered(area:Area2D): _on_body_entered(area, 2)
func _on_ClimbRight_area_entered(area:Area2D): _on_body_entered(area, 3)
func _on_Below_area_entered(area:Area2D): _on_body_entered(area, 4)
func _on_Left_area_entered(area:Area2D): _on_body_entered(area, 8)
func _on_ClimbLeft_area_entered(area:Area2D): _on_body_entered(area, 9)
func _on_body_entered(body:Node, dir:int):
	var parent := body.get_parent()
	if parent == null: return
	if parent.get_class() != "Block": return
	match dir:
		1: above = parent
		2: right = parent
		3: if !climb_right.has(parent): climb_right.append(parent)
		4: below = parent
		8: left = parent
		9: if !climb_left.has(parent): climb_left.append(parent)

func _on_Above_area_exited(area:Area2D): _on_body_exited(area, 1)
func _on_Right_area_exited(area:Area2D): _on_body_exited(area, 2)
func _on_ClimbRight_area_exited(area:Area2D): _on_body_exited(area, 3)
func _on_Below_area_exited(area:Area2D): _on_body_exited(area, 4)
func _on_Left_area_exited(area:Area2D): _on_body_exited(area, 8)
func _on_ClimbLeft_area_exited(area:Area2D): _on_body_exited(area, 9)
func _on_body_exited(body:Node, dir:int):
	var parent := body.get_parent()
	if parent == null: return
	if parent.get_class() != "Block": return
	var current_neighbor:Block = null
	match dir:
		1: current_neighbor = above
		2: current_neighbor = right
		3: current_neighbor = parent if climb_right.has(parent) else null
		4: current_neighbor = below
		8: current_neighbor = left
		9: current_neighbor = parent if climb_left.has(parent) else null
	if current_neighbor == parent:
		match dir:
			1: above = null
			2: right = null
			3: climb_right.erase(parent)
			4: below = null
			8: left = null
			9: climb_left.erase(parent)
