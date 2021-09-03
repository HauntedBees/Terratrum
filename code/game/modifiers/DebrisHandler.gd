extends Node2D

onready var game: Node2D = get_tree().root.get_node("/root/Geemu")
onready var lb: LevelBuilder = get_tree().root.get_node("/root/Geemu/LevelBuilder")
onready var bh: BlockHandler = get_tree().root.get_node("/root/Geemu/BlockHandler")
onready var player: Player = get_tree().root.get_node("/root/Geemu/Player")
var intensity := 0.1
var drop_speed := 1.0
var drop_limit := 1.0

var last_player_pos := Vector2(0, 0)
var time_elapsed := 0.0

func _ready():
	drop_speed = lb.block_scale * Consts.DROP_SPEED
	drop_limit = lb.grid_to_map(0, 1).y

func _process(delta):
	var player_pos := player.get_grid_position()
	if intensity < 0.5 && last_player_pos == player_pos: return # lower intensities won't keep shitting ya when idle
	
	time_elapsed += drop_speed * delta
	if time_elapsed < drop_limit: return
	time_elapsed = 0
	
	if randf() > intensity: return
	
	for x in lb.width: # can't start dropping until there's theoretically room for the blocks
		if lb.get_block(x, 0) != null: return
	
	var block_x := -1
	var block_y := -1
	var attempts := 7
	while attempts > 0:
		attempts -= 1
		var potential_x = randi() % lb.width
		var potential_y = int(player_pos.y) - 12
		if lb.get_block(potential_x, potential_y) == null:
			block_x = potential_x
			block_y = potential_y
			break
	if block_x < 0: return
	
	last_player_pos = player_pos
	var block_type = "hard" if randf() < 0.25 else lb.current_potential_types[randi() % lb.current_potential_types.size()]
	var block := lb.create_block(block_type, block_x, block_y)
	lb.current_level[block_x][block_y] = block
	block.position = lb.grid_to_map(block_x, block_y)
	block.family = [block]
	block.state = Block.BlockState.DROPPING
	game.add_child(block)
	bh.dropping_families.append([block])
