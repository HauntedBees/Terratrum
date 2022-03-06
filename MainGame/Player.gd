extends KinematicBody2D

onready var model := $Viewport/character
onready var camera := $Camera2D
onready var camera_x:float = camera.global_position.x

var walk_speed := 10000.0#Consts.WALK_SPEED
var active_direction := Vector2(0, 1)
var character := "Mole"

func _process(_delta): camera.global_position.x = camera_x

func _physics_process(delta):
	var direction := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	if direction != Vector2.ZERO:
		model.look_at(model.global_transform.origin - 10 * Vector3(direction.x, 0, direction.y), Vector3.UP)
		active_direction = direction
	
	var velocity := Vector2(direction.x, 0)
	velocity = velocity.normalized()
	velocity = walk_speed * delta * velocity
	#var is_moving:bool = velocity.length() > 0.1
	if !is_on_floor(): velocity.y += 10000.0 * delta
	move_and_slide(velocity, Vector2.UP)
	#move_and_collide(Vector2(0.0, 500.0 * delta))
