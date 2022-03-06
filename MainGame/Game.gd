extends Node2D

onready var lm:LevelManager = $LevelManager
onready var bm:BlockManager = $BlockManager
onready var bc := $BlockContainer
onready var player := $Player

func _ready():
	bc.transform.origin.x = (-lm.width * lm.block_size + lm.block_size) / 2.0
	draw_level(lm.current_level)

func draw_level(level:Array):
	for x in lm.width:
		for y in lm.height:
			var b:Block = level[x][y]
			b.position = lm.grid_to_map(x, y)
			bc.add_child(b)
			b.redraw_block()

func _process(_delta):
	if GASInput.is_action_just_pressed("ui_accept"):
		#print(lm.get_player_pos(player))
		_player_drill()
	#print("%s ^ %s" % [lm.get_block(0, 4), lm.get_block(0, 4).above])
	#print(lm.get_block(6, 2))
	#print(lm.get_block(6, 2).left)

func _player_drill():
	var drill_pos:Vector2 = lm.get_player_pos(player)
	var drill_dir:Vector2 = player.active_direction
	var steps := 3 if player.character == "Wombat" else 1
	while steps > 0:
		steps -= 1
		drill_pos += drill_dir
		#if pos.y == lm.height:
		#	clear_level()
		#	return
		var block = lm.get_block_v(drill_pos) # TODO: does air even work now
		if block == null: continue
		#if potential_target == null || (!is_air && potential_target.type == "air"): continue
		#var target_block := (potential_target as Block)
		#if !block.damage_block_return_if_destroyed(): return
		if block.type == "hard":
			#var score_loss := player.unbreathe()
			#add_info_text(-score_loss, target_block.position + Vector2(32.0, 16.0))
			#bm.separate_from_family(target_block)
			steps = 0
		#var blocks_to_clear:Array = block.family.list()
		#player.add_block_score(blocks_to_clear.size(), block.type == "hard")
		var info := bm.destroy_family_return_info(block.family)
		bm.set_potential_falls(info["lowest_y"])
		#bm.destroy_family(blocks_to_clear, true)
