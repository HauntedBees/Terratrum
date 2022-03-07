extends KinematicBody2D

onready var model := $Viewport/character
onready var camera := $Camera2D
onready var camera_x:float = camera.global_position.x

var walk_speed := 10000.0#Consts.WALK_SPEED
var active_direction := Vector2(0, 1)
var character := "Mole"
var above:Block
var right:Block
var below:Block
var left:Block

func _process(_delta): camera.global_position.x = camera_x

func _physics_process(delta):
	var direction := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	if direction != Vector2.ZERO:
		model.look_at(model.global_transform.origin - 10 * Vector3(direction.x, 0, direction.y), Vector3.UP)
		active_direction = Vector2(round(direction.x), round(direction.y))
	
	var velocity := Vector2(direction.x, 0)
	velocity = velocity.normalized()
	velocity = walk_speed * delta * velocity
	#var is_moving:bool = velocity.length() > 0.1
	if !is_on_floor(): velocity.y += Consts.BLOCK_SIZE * Consts.BLOCK_SIZE * delta
	move_and_slide(velocity, Vector2.UP)

func _on_Above_area_entered(area:Area2D): _on_body_entered(area, 1)
func _on_Right_area_entered(area:Area2D): _on_body_entered(area, 2)
func _on_Below_area_entered(area:Area2D): _on_body_entered(area, 4)
func _on_Left_area_entered(area:Area2D): _on_body_entered(area, 8)
func _on_body_entered(body:Node, dir:int):
	var parent := body.get_parent()
	if parent == null: return
	if parent.get_class() != "Block": return
	match dir:
		1: above = parent
		2: right = parent
		4: below = parent
		8: left = parent

func _on_Above_area_exited(area:Area2D): _on_body_exited(area, 1)
func _on_Right_area_exited(area:Area2D): _on_body_exited(area, 2)
func _on_Below_area_exited(area:Area2D): _on_body_exited(area, 4)
func _on_Left_area_exited(area:Area2D): _on_body_exited(area, 8)
func _on_body_exited(body:Node, dir:int):
	var parent := body.get_parent()
	if parent == null: return
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
