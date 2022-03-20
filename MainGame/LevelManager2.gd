extends LevelHandler
class_name LevelManager2

onready var player = get_parent().get_node("Player")
onready var lb:LevelBuilder2 = get_node("LevelBuilder")

var offset := Vector2.ZERO
var player_offset := Vector2(224, 0)

var block_size := Consts.BLOCK_SIZE
var block_scale := 1
var score := 0
var air_amount := 100.0

var power_saver := true
var max_y := 0
var min_y := 0
const ABOVE_LIMIT := 20
var kill_queue := []
var player_popped := {}

const DEBUG := false
var debug_timer := -1.0

func _ready():
	current_level = lb.current_level
	block_size = lb.block_size
	block_scale = lb.block_scale
	width = lb.width
	height = lb.height

func grid_to_map(x:int, y:int) -> Vector2: return Vector2(x * block_size + offset.x, y * block_size + offset.y)
func map_to_grid(p: Vector2) -> Vector2: return Vector2(floor((p.x - offset.x) / block_size), floor((p.y - offset.y) / block_size))
func get_player_pos() -> Vector2: return map_to_grid(player.position + player_offset)
func get_block_by_player(player_dir:Vector2) -> Block2: return get_block_v(get_player_pos() + player_dir)
func get_player_target_pos(player_dir:Vector2) -> Vector2: return get_player_pos() + player_dir

func clear_level():
	for x in width:
		for y in height:
			var b = current_level[x][y]
			if b == null: continue
			current_level[x][y] = null

func _redraw_block(x:int, y:int, redraw_neighbors:bool):
	var b := get_block(x, y)
	if b == null: return
	b.calculate_mask_offset(get_block(x, y - 1), get_block(x + 1, y), 
							get_block(x, y + 1), get_block(x - 1, y),
							get_block(x - 1, y - 1), get_block(x + 1, y - 1),
							get_block(x - 1, y + 1), get_block(x + 1, y + 1))
	if redraw_neighbors:
		_redraw_block(x - 1, y, false)
		_redraw_block(x + 1, y, false)
		_redraw_block(x, y - 1, false)
		_redraw_block(x, y + 1, false)

# Main Game Loop
func _reverse_range() -> Array: return range(max_y, min_y - 1, -1)
func _range() -> Array: return range(min_y, max_y + 1)
func _process(delta:float):
	air_amount -= delta * Consts.AIR_DECREASE_RATE
	for k in player_popped.keys():
		player_popped[k] -= delta
		if player_popped[k] <= 0: player_popped.erase(k)
	_print_debug()
	if power_saver: min_y = max(0, get_player_pos().y - ABOVE_LIMIT)
	if kill_queue.size() > 0:
		kill_queue[0].queue_free()
		kill_queue.remove(0)
	# A. destroy popped blocks and reset flags
	for y in range(0, height):
		var purge_block:bool = power_saver && y < min_y
		for x in width:
			var b:Block2 = current_level[x][y]
			if b == null: continue
			if purge_block || b.state == Block2.State.POPPED:
				current_level[x][y] = null
				kill_queue.append(b)
				#b.queue_free()
			else: b.reset_flags()
	_print_debug("A")
	# B. check if blocks have finished falling and pop 4+groups that have landed
	for y in _reverse_range():
		for x in width:
			var b:Block2 = current_level[x][y]
			if b == null || b.recurse_check || b.type == "air" || b.state == Block2.State.FALLING: continue
			var fell_info := _check_falling_block(x, y, b.type)
			if fell_info.should_clear():
				_pop_from_fall(x, y, b.type)
	_print_debug("B")
	# C. handle player digging action
	if player.is_digging:
		player.is_digging = false
		var target_block_pos := get_player_target_pos(player.active_direction)
		var target_block := get_block_v(target_block_pos)
		if target_block != null && !target_block.is_falling_or_been_popped():
			_reset_all(true, false, true)
			# TODO: handle score
			# TODO: lower health/handle x blocks
			_pop_from_action(target_block_pos.x, target_block_pos.y)
	_print_debug("C")
	_reset_all()
	_print_debug("reset")
	# D. handle setting blocks to fall
	for y in _reverse_range():
		for x in width:
			var b:Block2 = current_level[x][y]
			if b == null || b.is_falling_or_been_popped() || b.lock_check: continue
			var below:Block2 = get_block(x, y + 1)
			if below == null:
				if b.state == Block2.State.NONE:
					b.wait_time = 0 # TODO?: PREFALLTIME if below is player dug??
					b.state = Block2.State.PREFALL
				elif b.state == Block2.State.POSTFALL:
					b.wait_time = 0
					b.state = Block2.State.PREFALL
				else:
					b.state = Block2.State.PREFALL
			elif below.state == Block2.State.PREFALL:
				b.wait_time = below.wait_time
				b.state = Block2.State.PREFALL
			elif below.is_falling_or_been_popped():
				if b.state == Block2.State.POSTFALL:
					_finish_fall(x, y, b.type)
				else:
					_fall_to_none(x, y, b.type)
			else:
				_fall_to_none(x, y, b.type)
	_print_debug("D")
	_reset_all()
	_print_debug("reset")
	# E. set wait time on PREFALL blocks
	for y in _reverse_range():
		for x in width:
			var b:Block2 = current_level[x][y]
			if b == null || b.recurse_check || b.state != Block2.State.PREFALL: continue
			var wait_time := _get_highest_wait_time(x, y, b.type)
			_set_wait_time(x, y, b.type, wait_time)
	_print_debug("E")
	_reset_all(true, false, true) # why false?
	_print_debug("reset")
	# F. make the blocks fall and pop
	for y in _reverse_range():
		for x in width:
			var b:Block2 = current_level[x][y]
			if b == null: continue
			# crystal blocks
			match b.state:
				Block2.State.PREFALL:
					b.wait_time -= delta
					if b.wait_time <= 0:
						current_level[x][y] = null
						current_level[x][y + 1] = b
						b.state = Block2.State.FALLING
						b.fall_remaining = Consts.BLOCK_SIZE
				Block2.State.FALLING:
					var fall_distance := delta * Consts.BLOCK_SIZE * Consts.FALL_TIME
					b.fall_remaining -= fall_distance
					b.position.y += fall_distance
					if b.fall_remaining <= 0.0:
						b.position.y = grid_to_map(x, y).y
						b.fall_remaining = 0.0
						b.state = Block2.State.POSTFALL
						_redraw_block(x, y, true)
				Block2.State.POPPING:
					b.wait_time -= delta
					if b.wait_time <= 0:
						b.state = Block2.State.POPPED
	_print_debug("F")

func _print_debug(key:String = ""):
	if !DEBUG: return
	if key == "":
		debug_timer = OS.get_ticks_msec()
		return
	var delta := OS.get_ticks_msec() - debug_timer
	print("%s = %s" % [key, delta])
	debug_timer = OS.get_ticks_msec()

func _check_falling_block(x:int, y:int, type:String) -> FallInfo:
	var b:Block2 = get_block(x, y)
	if b == null || b.recurse_check || b.type != type: return FallInfo.new()
	b.recurse_check = true
	if b.state == Block2.State.FALLING: return FallInfo.new() # this seems redundant, they'll never be FALLING
	#var info := FallInfo.new(b.state == Block2.State.POSTFALL, 1)
	var info := FallInfo.new(b.just_landed, 1)
	b.just_landed = false
	info.merge(_check_falling_block(x - 1, y, type))
	info.merge(_check_falling_block(x + 1, y, type))
	info.merge(_check_falling_block(x, y - 1, type))
	info.merge(_check_falling_block(x, y + 1, type))
	return info

func _pop_from_fall(x:int, y:int, type:String):
	var b:Block2 = get_block(x, y)
	if b == null || b.pop_wait_check || b.type != type: return
	b.pop_wait_check = true
	if (b.state == Block2.State.POPPED || b.state == Block2.State.POPPING) && b.wait_time < 8.0: return # TODO: some number
	b.state = Block2.State.POPPING
	b.wait_time = Consts.POP_TIME
	b.fall_remaining = 0.0
	b.player_popped = false
	b.pop()
	max_y = max(max_y, y)
	_pop_from_fall(x - 1, y, type)
	_pop_from_fall(x + 1, y, type)
	_pop_from_fall(x, y - 1, type)
	_pop_from_fall(x, y + 1, type)
func _pop_from_action(x:int, y:int, reset := false):
	if reset: _reset_all(true, false, true)
	#player_popped = []
	var b:Block2 = get_block(x, y)
	if b == null || b.state == Block2.State.POPPING || b.is_unpoppable_type(): return
	_pop_block(x, y, b.type)
func _pop_block(x:int, y:int, type:String):
	var b:Block2 = get_block(x, y)
	if b == null || b.recurse_check || b.type != type || b.state == Block2.State.FALLING: return
	b.recurse_check = true
	b.state = Block2.State.POPPING
	b.player_popped = true
	player_popped[Vector2(x, y)] = 0.5
	b.wait_time = Consts.PLAYER_POP_TIME
	b.pop()
	max_y = max(max_y, y)
	_pop_block(x - 1, y, type)
	_pop_block(x + 1, y, type)
	_pop_block(x, y - 1, type)
	_pop_block(x, y + 1, type)

func _finish_fall(x:int, y:int, type:String):
	var b:Block2 = get_block(x, y)
	if b == null || b.recurse_check || b.type != type: return
	b.recurse_check = true
	if b.is_falling_or_been_popped(): return
	b.state = Block2.State.POSTFALL
	b.wait_time = Consts.PREFALL_WAIT_TIME
	b.lock_check = true
	if b.is_unpoppable_type(): return
	_finish_fall(x - 1, y, type)
	_finish_fall(x + 1, y, type)
	_finish_fall(x, y - 1, type)
	_finish_fall(x, y + 1, type)
func _fall_to_none(x:int, y:int, type:String):
	var b:Block2 = get_block(x, y)
	if b == null || b.recurse_check || b.type != type: return
	b.recurse_check = true
	if b.is_falling_or_been_popped(): return
	if b.state == Block2.State.POSTFALL: b.just_landed = true
	#b.just_landed = b.state == Block2.State.NONE
	b.state = Block2.State.NONE
	b.wait_time = Consts.PREFALL_WAIT_TIME
	b.lock_check = true
	if b.is_unpoppable_type(): return
	_fall_to_none(x - 1, y, type)
	_fall_to_none(x + 1, y, type)
	_fall_to_none(x, y - 1, type)
	_fall_to_none(x, y + 1, type)

func _get_highest_wait_time(x:int, y:int, type:String) -> float:
	var b:Block2 = get_block(x, y)
	if b == null || b.recurse_check || b.type != type: return 0.0
	b.recurse_check = true
	var wait_time := b.wait_time
	var below:Block2 = get_block(x, y + 1)
	if below != null && below.type != b.type:
		if below.state == b.state && b.state == Block2.State.PREFALL:
			wait_time = max(wait_time, below.wait_time)
		else:
			var fall_time:float = Consts.PREFALL_WAIT_TIME if below.player_popped else 0.0
			wait_time = max(wait_time, fall_time)
	elif below == null && player_popped.has(Vector2(x, y + 1)):
		player_popped.erase(Vector2(x, y + 1))
		wait_time = max(wait_time,  Consts.PREFALL_WAIT_TIME)
	if b.is_unpoppable_type(): return wait_time
	wait_time = max(wait_time, _get_highest_wait_time(x - 1, y, type))
	wait_time = max(wait_time, _get_highest_wait_time(x + 1, y, type))
	wait_time = max(wait_time, _get_highest_wait_time(x, y - 1, type))
	wait_time = max(wait_time, _get_highest_wait_time(x, y + 1, type))
	return wait_time
func _set_wait_time(x:int, y:int, type:String, wait_time:float):
	var b:Block2 = get_block(x, y)
	if b == null || b.pop_wait_check || b.type != type: return
	b.pop_wait_check = true
	if b.state != Block2.State.PREFALL: return
	b.wait_time = wait_time
	if b.is_unpoppable_type(): return
	_set_wait_time(x - 1, y, type, wait_time)
	_set_wait_time(x + 1, y, type, wait_time)
	_set_wait_time(x, y - 1, type, wait_time)
	_set_wait_time(x, y + 1, type, wait_time)

func _reset_all(recurse_check := true, pop_wait_check := true, lock_check := true):
	for y in height:
		for x in width:
			var b:Block2 = current_level[x][y]
			if b == null: continue
			b.reset_flags(recurse_check, pop_wait_check, lock_check)

func debug_pop(b:Block2):
	var by := -1
	var bx := -1
	for y in height:
		for x in width:
			if current_level[x][y] == b:
				bx = x
				by = y
				break
		if by >= 0: break
	if bx < 0: return
	_pop_from_action(bx, by, true)

class FallInfo:
	var fell := false
	var count := 0
	func _init(f := false, i := 0):
		fell = f
		count = i
	func merge(f:FallInfo):
		if f.fell: fell = true
		count += f.count
	func should_clear() -> bool: return fell && count >= 4
