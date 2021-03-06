extends KinematicBody2D
class_name DigPlayer

onready var lm:LevelManager2 = get_parent().get_node("LevelManager")
onready var model := $Viewport/character
onready var camera := $Camera2D
onready var camera_x:float = camera.global_position.x

var walk_speed := Consts.WALK_SPEED
var active_direction := Vector2(0, 1)
var character := "Mole"
var drill_cooldown := 0.0

var climb_height := 1
var climb_limit := 0.0
var forced_steps := []
var on_floor := false
var near_floors := []

var is_digging := false

class ForcedStep:
	var new_pos:float
	var dir:int
	func _init(direction:int, new_position:float):
		dir = direction
		new_pos = new_position

func _process(_delta):
	camera.global_position.x = camera_x
	if GASInput.is_action_just_pressed("ui_accept") && can_dig():
		drill_cooldown = Consts.POP_HOLD_TIME
		is_digging = true

func can_dig() -> bool:
	return forced_steps.size() == 0 && drill_cooldown <= 0.0 && (on_floor || near_floors.size() > 0)

func _physics_process(delta:float):
	if drill_cooldown > 0.0:
		drill_cooldown -= delta
		if drill_cooldown > 0.0:
			return
	
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
	velocity.y = lm.block_size * Consts.DROP_SPEED * delta
	if !on_floor:
		velocity.x = 0
	move_and_slide(velocity, Vector2.UP)
	on_floor = is_on_floor()
	
	if is_on_wall(): _try_climb(direction, delta)
	else: climb_limit = 0.0

func _try_climb(direction:Vector2, delta:float):
	if active_direction.x == 0: return
	climb_limit += delta
	if climb_limit >= Consts.TIME_TO_TRIGGER_CLIMB && on_floor:
		var height := _get_actual_climb_height()
		if height == 0: return
		for i in height:
			forced_steps.append(Vector3(position.x, position.y - lm.block_size * (i + 1), 0))
		forced_steps.append(Vector3(position.x + active_direction.x * lm.block_size * 0.75, position.y - lm.block_size * climb_height, active_direction.x))

func _get_actual_climb_height() -> int:
	var possible_climb_height := 0
	for potential_height in range(1, climb_height + 1):
		# if there aren't blocks to climb up, the player can't climb
		var front_block := lm.get_block_by_player(active_direction - Vector2(0, potential_height - 1))
		# and if there are blocks above the player, the player can't climb
		var above_block := lm.get_block_by_player(Vector2(0, -potential_height))
		if front_block == null || front_block.can_climb_through() || above_block != null: break
		possible_climb_height += 1
	# if there is a block in the destination, the player can't climb
	var goal := lm.get_block_by_player(active_direction - Vector2(0, possible_climb_height))
	if goal != null && !goal.can_climb_through(): return 0
	return possible_climb_height

func _do_climb(delta:float):
	var step:Vector3 = forced_steps[0]
	var amount := lm.block_size * Consts.CLIMB_STEP_TIME * delta
	if step.z == 0: # climb up
		position.y -= amount
		if position.y <= step.y:
			forced_steps.remove(0)
	else: # move forward
		position.x += step.z * amount
		if (step.z > 0 && position.x >= step.x) || (step.z < 0 && position.x <= step.x):
			forced_steps.remove(0)

func _on_NearFloor_body_entered(body):
	if near_floors.has(body): return
	near_floors.append(body)
func _on_NearFloor_body_exited(body): near_floors.erase(body)
