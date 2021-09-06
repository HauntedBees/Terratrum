extends Node2D

signal clear_level
signal update_ui_value(key, value)
signal set_camera_max_height(y)
signal set_max_depth(depth)

const INFO_BEEP = preload("res://scenes/game/InfoBeep.tscn")
onready var lb: LevelBuilder = $LevelBuilder
onready var bh: BlockHandler = $BlockHandler
onready var clear_block: Node2D = $Clearblock
onready var player: Player = $Player

func _ready():
	player.position = Vector2(325, -20)
	emit_signal("set_camera_max_height", lb.height)
	emit_signal("update_ui_value", "lives", player.lives)
	emit_signal("set_max_depth", lb.max_depth)
	player.scale *= lb.block_scale
	player.block_scale = lb.block_scale
	player.block_size = lb.block_size
	clear_block.position = lb.grid_to_map(0, lb.height)
	draw_level(lb.current_level)
	if bh.level == null: bh.level = lb
	
	var level_info: Levels.LevelInfo = SceneSwitcher.get_carried_scene_data().level
	for m in level_info.modifiers:
		match m.type:
			"DEBRIS":
				var dh_s = load("res://scenes/game/modifiers/DebrisHandler.tscn")
				var dh = dh_s.instance()
				dh.intensity = m.intensity
				add_child(dh)

func _on_Player_drill(v: Vector2, is_air: bool = false):
	var pos := lb.get_player_pos(player)
	var steps := 3 if player.character == "Wombat" else 1
	while steps > 0:
		steps -= 1
		pos.x += v.x
		pos.y += v.y
		if pos.y == lb.height:
			clear_level()
			return
		var potential_target = lb.get_block_v(pos) # TODO: does air even work now
		if potential_target == null || (!is_air && potential_target.type == "air"): continue
		var target_block := (potential_target as Block)
		if !target_block.damage_block_return_if_destroyed(): return
		if target_block.type == "hard":
			var score_loss := player.unbreathe()
			add_info_text(-score_loss, target_block.position + Vector2(32.0, 16.0))
			bh.separate_from_family(target_block)
			steps = 0
		var blocks_to_clear := target_block.family
		player.add_block_score(blocks_to_clear.size(), target_block.type == "hard")
		bh.destroy_family(blocks_to_clear, true)

func _process(_delta):
	handle_player()
	$JeffWalls.position.y = player.position.y - 10
	
func handle_player():
	var pos := lb.get_player_pos(player)
	player.check_depth(lb.level_number * 100 + int(pos.y) + 1)
	if player.dead: return
	if player.is_timed && player.play_info.play_time <= 0.0:
		player.lives = 1
		player_did_died(pos)
		return
	if player.air <= 0:
		player_did_died(pos)
		return
	var potential_block = lb.get_block_v(pos)
	if potential_block == null || !is_instance_valid(potential_block): return
	var b: Block = (potential_block as Block)
	if b.type == "air":
		var score_bonus := player.breathe()
		add_info_text(score_bonus, player.position)
		_on_Player_drill(Vector2(0, 0), true)
	elif b.state != Block.BlockState.DROPPING && !player.immune:
		player_did_died(pos)

func add_info_text(val: int, position: Vector2):
	var info := INFO_BEEP.instance()
	info.msg = ("+%s" if val >= 0 else "%s") % val
	info.mode = 0 if val >= 0 else 1
	info.position = position
	info.z_index = 10
	add_child(info)

func player_did_died(player_pos: Vector2):
	if player.dead: return
	player.lives -= 1
	emit_signal("update_ui_value", "lives", player.lives)
	player.do_a_died()
	yield(get_tree().create_timer(Consts.DEATH_TIME), "timeout")
	if player.lives <= 0:
		player.play_info.gamed_over = true
		lb.full_level_info.play_data = player.play_info
		SceneSwitcher.go_to_score(lb.full_level_info)
	else:
		bh.wipe_range(int(player_pos.x - 1), int(player_pos.x + 2), 0, int(player_pos.y + 1))
		player.undie_ha_ha_like_underwear_but_actually_as_in_un_die()

func clear_level():
	lb.level_number += 1
	player.add_score(lb.level_number * lb.height + Consts.CLEAR_AREA_BONUS)
	lb.clear_level()
	lb.offset.y = lb.grid_to_map(0, lb.height).y + Consts.BLOCK_SIZE * 4
	
	if player.play_info.max_depth == lb.max_depth:
		move_clear_block()
		emit_signal("clear_level")
		lb.make_empty_current_level()
		lb.full_level_info.play_data = player.play_info
		SceneSwitcher.go_to_score(lb.full_level_info)
	else:
		# somehow the player got to the next level before it even finished loading??
		# this should probably never happen because I couldn't even do it with my 
		# standard debugging speed-up shit, but just in case, it's always better to
		# account for players doing weird shit and NOT crashing than the alternative.
		if lb.next_level_builder != null:
			while lb.make_next_level(): pass
		
		lb.current_level = lb.next_level
		lb.current_potential_types = lb.potential_types
		draw_level(lb.current_level)
		move_clear_block()
		emit_signal("clear_level")
		lb.start_making_next_level()

func move_clear_block():
	clear_block.collider.scale = Vector2(0.01, 0.01)
	clear_block.tween.interpolate_property(clear_block, "modulate:a", 1, 0, Consts.ACTION_TIME, Tween.TRANS_LINEAR)
	clear_block.tween.start()
	yield(clear_block.tween, "tween_completed")
	clear_block.modulate.a = 1
	clear_block.position = lb.grid_to_map(0, lb.height)
	clear_block.collider.scale = Vector2(1, 1)
	clear_block.increase_limit()

func draw_level(level: Array):
	for x in lb.width:
		for y in lb.height:
			var b: Block = level[x][y]
			b.position = lb.grid_to_map(x, y)
			add_child(b)
			b.redraw_block()
