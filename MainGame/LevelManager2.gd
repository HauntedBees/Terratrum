extends Node2D
class_name LevelManager2

const piece = preload("res://MainGame/Block2.tscn")
onready var full_level_info: Levels.FullLevelInfo = SceneSwitcher.get_carried_scene_data()
onready var player = get_parent().get_node("Player")

var current_potential_types := ["red", "blue", "green", "yellow"]
var potential_types := ["red", "blue", "green", "yellow"]
var difficulty_curve := []
var air_every_x_rows := 5 # 5 = easy, 12 = hard
var bad_block_percent := 3.7143 # between 3.7143 and 5.1587
var max_depth := 0

var width := 7 # 5/7/9/11 NOTE: fucks up more on sizes that aren't 7
var height := 100
var offset := Vector2.ZERO#Vector2(100, 0)
var player_offset := Vector2(224, 0)
var block_scale := 1.0
var block_size := Consts.BLOCK_SIZE

var level_number := 0
var current_level := []
var next_level := []
var next_level_builder = null
var level_seed := 0


func _ready():
	var level_info := full_level_info.level
	width = level_info.level_width
	block_scale = 7.0 / width
	block_size = block_scale * Consts.BLOCK_SIZE
	difficulty_curve = level_info.difficulty_set if level_info != null else [Menu.DifficultyInfo.new(4, 0, 0)]
	max_depth = level_info.max_depth if level_info != null else 0
	randomize()
	level_seed = level_info.level_seed if level_info != null && level_info.level_seed != 0 else randi() % 10000000
	#level_seed = 9102156
	#level_seed = 6202397
	seed(level_seed)
	print(level_seed)
	current_level = get_2d_array(width, height)
	continue_making_level(current_level, get_difficulty_info(0), false)
	current_potential_types = potential_types
	start_making_next_level()

# General Helper Methods
func out_of_bounds(x:int, y:int) -> bool: return y < 0 || y >= height || x < 0 || x >= width
func rand_percent() -> float: return randf() * 100
func arr_rand(arr:Array): return arr[randi() % arr.size()]

func get_block_v(v:Vector2) -> Block2: return get_block(int(v.x), int(v.y))
func get_block(x:int, y:int) -> Block2: return get_block_from(current_level, x, y)
func get_block_from(level, x:int, y:int) -> Block2: return null if out_of_bounds(x, y) else level[x][y]
func set_block(x:int, y:int, new_val:Block2):
	if out_of_bounds(x, y): return
	current_level[x][y] = new_val

func grid_to_map(x:int, y:int) -> Vector2: return Vector2(x * block_size + offset.x, y * block_size + offset.y)
func map_to_grid(p: Vector2) -> Vector2: return Vector2(floor((p.x - offset.x) / block_size), floor((p.y - offset.y) / block_size))

func get_player_pos() -> Vector2: return map_to_grid(player.position + player_offset)
func get_block_by_player(player_dir:Vector2) -> Block2: return get_block_v(get_player_pos() + player_dir)
func get_player_target_pos(player_dir:Vector2) -> Vector2: return get_player_pos() + player_dir

func get_difficulty_info(idx: int): # TODO: expand to support looping and such
	return difficulty_curve[int(min(idx, difficulty_curve.size() - 1))]

func create_block(type:String, x:int, y:int) -> Block2:
	var b:Block2 = piece.instance()
	b.type = type
	#b.grid_pos = Vector2(x, y)
	b.name = "%s (%s, %s)" % [type, x, y]
	b.scale *= block_scale
	return b

func clear_level():
	for x in width:
		for y in height:
			var b = current_level[x][y]
			if b == null: continue
			current_level[x][y] = null
			#b.permanent_dissipation()
func make_empty_current_level(): current_level = get_2d_array(width, height)

## slowly build the next level over time (creating one block per frame in _process)
## because creating 700+ block instances at once does exactly what you'd expect it to.
func _physics_process(_delta): make_next_level()
func get_2d_array(w: int, h: int):
	var arr = []
	for i in w:
		arr.append([])
		for j in h:
			arr[i].append(null)
	return arr
func start_making_next_level():
	next_level = get_2d_array(width, height)
	next_level_builder = continue_making_level(next_level, get_difficulty_info(level_number + 1))
func make_next_level() -> bool:
	if next_level_builder == null: return false
	if next_level_builder is GDScriptFunctionState && next_level_builder.is_valid():
		next_level_builder = next_level_builder.resume()
		return next_level_builder != null
	return true
func continue_making_level(level: Array, level_info, delayed: bool = true):
	air_every_x_rows += level_info.air_increase
	bad_block_percent += level_info.bad_increase
	match level_info.colors:
		4: potential_types = ["red", "blue", "green", "yellow"]
		3: potential_types = ["red", "blue", "green"]
		2: potential_types = ["blue", "yellow"]
	#var top_chunk := _get_debug_top(7)
	var top_chunk:Array = [] if delayed else _get_level_top(level_info.colors) # "!delayed" is equivalent to "top of level"
	var top_chunk_size := top_chunk.size()
	var special_occasions := _get_air_sections()
	for y in height:
		for x in width:
			if y < top_chunk_size && !delayed:
				if top_chunk[y][x] == "x":
					level[x][y] = null
				else:
					level[x][y] = create_block(top_chunk[y][x], x, y)
			else:
				var type: String = arr_rand(potential_types)
				var key = "%s,%s" % [x, y]
				if special_occasions.has(key):
					type = special_occasions[key]
				elif rand_percent() < bad_block_percent:
					type = "hard"
				var block := create_block(type, x, y)
				level[x][y] = block
				if delayed: yield()
	for y in height:
		for x in width:
			_redraw_block(x, y, false)

func _get_level_top(num_colors: int) -> Array:
	var xx := "hard"
	var c1 := "blue" if num_colors == 2 else "red"
	var c2 := "yellow" if num_colors == 2 else "green"
	var c3 := "blue"
	var c4 := "yellow" if num_colors == 2 else "red"
	var res := []
	for y in range(0, 4):
		var row := []
		for x in width:
			if y == 3:
				row.append(c4)
			elif y == 2:
				row.append(c3)
			else:
				row.append(xx)
		var middle = ceil(width / 2)
		if y == 0:
			row[middle] = c1
		elif y == 1:
			row[middle] = c2
			row[middle - 1] = c2
			row[middle + 1] = c2
		elif y == 2:
			row[0] = xx
			row[width - 1] = xx
		res.append(row)
	return res
func _get_air_sections() -> Dictionary:
	var relevant_tiles := {}
	var x_chance := bad_block_percent * 4.0
	for y in range(0, height, air_every_x_rows):
		var x := randi() % width
		relevant_tiles["%s,%s" % [x, y]] = "air"
		for i in range(0, 8):
			if rand_percent() < x_chance:
				x_chance = bad_block_percent * 2.5
				match i:
					0: relevant_tiles["%s,%s" % [x - 1, y]] = "hard"
					1: relevant_tiles["%s,%s" % [x - 1, y - 1]] = "hard"
					2: relevant_tiles["%s,%s" % [x, y - 1]] = "hard"
					3: relevant_tiles["%s,%s" % [x + 1, y - 1]] = "hard"
					4: relevant_tiles["%s,%s" % [x + 1, y]] = "hard"
					5: relevant_tiles["%s,%s" % [x + 1, y + 1]] = "hard"
					6: relevant_tiles["%s,%s" % [x, y + 1]] = "hard"
					7: relevant_tiles["%s,%s" % [x - 1, y + 1]] = "hard"
			else:
				x_chance += 0.5
	return relevant_tiles

func _get_debug_top(case:int) -> Array:
	match case:
		0: #regular loop
			return [
				_expand("RYYYYYR"),
				_expand("RYBRBYR"),
				_expand("RYBRBYR"),
				_expand("RYYYYYR"),
				_expand("RRRRRRR"),
				_expand("YYYYYYY")
			]
		1: # double intermingle
			return [
				_expand("RGRGRRR"),
				_expand("RYYYYYR"),
				_expand("RYBBBBR"),
				_expand("RYYYYBR"),
				_expand("RYBBBBR"),
				_expand("RRRRRRR"),
				_expand("RRRRRRR"),
				_expand("GYGGGGG"),
				_expand("HHRHHHH")
			]
		2: # triple intermingle
			return [
				_expand("RRRBYBB"),
				_expand("BYBGRBB"),
				_expand("RBGYRBB"),
				_expand("RGYGRBB"),
				_expand("BBBRRBB")
			]
		3: # advanced intermingle
			return [
				_expand("YYYYYYY"),
				_expand("YYRRRBY"),
				_expand("YGGBBBY"),
				_expand("YGRRRRY"),
				_expand("YGGGGRY"),
				_expand("YYYYYYY"),
				_expand("RRRRRRR")
			]
		4: # timing fall issues
			return [
				_expand("YYYYYRH"),
				_expand("YYYYYBR"),
				_expand("YYYYYRR"),
				_expand("YYYYYGG"),
				_expand("YYYYYHH")
			]
		5: # just a guy
			return [
				_expand("XXXxXXX"),
				_expand("XXxRxXX"),
				_expand("XxGGGxX"),
				_expand("XxGxxxY"),
				_expand("RXBYxxR"),
				_expand("YYYBxxR"),
				_expand("YBBRYxY"),
				_expand("YRRYGYB"),
				_expand("BRRGBXX")
			]
		6: # let's get a combo going
			return [
				_expand("xxxxBxx"),
				_expand("xxxxHxx"),
				_expand("RxYRBxx"),
				_expand("BGGBBHx"),
				_expand("BRRRGRx"),
				_expand("GGGBRRx"),
				_expand("BBYYYRx"),
				_expand("HHHBBBx"),
				_expand("HHHYRRx"),
				_expand("HHHGGGx"),
				_expand("YYYYYYx"),
				_expand("RRRHHHH"),
				_expand("RGGGGGG"),
				_expand("RGBBYYG"),
				_expand("RGBBBBG"),
				_expand("RGGGGGG"),
				_expand("RRRRRRR"),
				_expand("HHHHYYH"),
				_expand("YYYYYYY")
			]
		7: # quick access to the fucko
			return [
				_expand("RxxRBxx"),
				_expand("BxxBBHx"),
				_expand("BxxRGRx"),
				_expand("GGGBRRx"),
				_expand("BBYYYRx"),
				_expand("HHHBBBx"),
				_expand("HHHYRRx")
			]
	return []
func _expand(r:String) -> Array:
	var r2 := []
	for o in r:
		match o:
			"R": r2.append("red")
			"Y": r2.append("yellow")
			"G": r2.append("green")
			"B": r2.append("blue")
			"H", "X": r2.append("hard")
			"x": r2.append("x")
	return r2

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

func _reverse_range() -> Array: return range(max_y, min_y - 1, -1)
func _range() -> Array: return range(min_y, max_y + 1)

const DEBUG := false

var power_saver := true
var max_y := 0
var min_y := 0
const ABOVE_LIMIT := 10
var kill_queue := []

func _process(delta:float):
	var o := OS.get_ticks_msec()
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
	if DEBUG:
		print("A = %s" % [OS.get_ticks_msec() - o])
		o = OS.get_ticks_msec()
	# B. check if blocks have finished falling and pop 4+groups that have landed
	for y in _reverse_range():
		for x in width:
			var b:Block2 = current_level[x][y]
			if b == null || b.recurse_check || b.type == "air" || b.state == Block2.State.FALLING: continue
			var fell_info := _check_falling_block(x, y, b.type)
			if fell_info.should_clear():
				_pop_from_fall(x, y, b.type)
	if DEBUG:
		print("B = %s" % [OS.get_ticks_msec() - o])
		o = OS.get_ticks_msec()
	# C. handle player digging action
	if player.is_digging:
		player.is_digging = false
		var target_block_pos := get_player_target_pos(player.active_direction)
		var target_block := get_block_v(target_block_pos)
		if target_block != null && !target_block.is_falling_or_been_popped():
			_reset_all(true, false)
			# TODO: handle score
			# TODO: lower health/handle x blocks
			_pop_from_action(target_block_pos.x, target_block_pos.y)
	if DEBUG:
		print("C = %s" % [OS.get_ticks_msec() - o])
		o = OS.get_ticks_msec()
	_reset_all()
	if DEBUG:
		print("reset = %s" % [OS.get_ticks_msec() - o])
		o = OS.get_ticks_msec()
	# D. handle setting blocks to fall
	for y in _reverse_range():
		for x in width:
			var b:Block2 = current_level[x][y]
			if b == null || b.is_falling_or_been_popped(): continue
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
	if DEBUG:
		print("D = %s" % [OS.get_ticks_msec() - o])
		o = OS.get_ticks_msec()
	_reset_all()
	if DEBUG:
		print("reset = %s" % [OS.get_ticks_msec() - o])
		o = OS.get_ticks_msec()
	# E. set wait time on PREFALL blocks
	for y in _reverse_range():
		for x in width:
			var b:Block2 = current_level[x][y]
			if b == null || b.recurse_check || b.state != Block2.State.PREFALL: continue
			var wait_time := _get_highest_wait_time(x, y, b.type)
			_set_wait_time(x, y, b.type, wait_time)
	if DEBUG:
		print("E = %s" % [OS.get_ticks_msec() - o])
		o = OS.get_ticks_msec()
	_reset_all(true, false) # why false?
	if DEBUG:
		print("reset = %s" % [OS.get_ticks_msec() - o])
		o = OS.get_ticks_msec()
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
	if DEBUG:
		print("F = %s" % [OS.get_ticks_msec() - o])

func _check_falling_block(x:int, y:int, type:String) -> FallInfo:
	var b:Block2 = get_block(x, y)
	if b == null || b.recurse_check || b.type != type: return FallInfo.new()
	b.recurse_check = true
	if b.state == Block2.State.FALLING: return FallInfo.new() # this seems redundant, they'll never be FALLING
	var info := FallInfo.new(b.state == Block2.State.POSTFALL, 1)
	info.merge(_check_falling_block(x - 1, y, type))
	info.merge(_check_falling_block(x + 1, y, type))
	info.merge(_check_falling_block(x, y - 1, type))
	info.merge(_check_falling_block(x, y + 1, type))
	return info

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
	if reset: _reset_all(true, false)
	var b:Block2 = get_block(x, y)
	if b == null || b.state == Block2.State.POPPING || b.is_unpoppable_type(): return
	_pop_block(x, y, b.type)
func _pop_block(x:int, y:int, type:String):
	var b:Block2 = get_block(x, y)
	if b == null || b.recurse_check || b.type != type || b.state == Block2.State.FALLING: return
	b.recurse_check = true
	b.state = Block2.State.POPPING
	b.player_popped = true
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
	b.state = Block2.State.NONE
	b.wait_time = Consts.PREFALL_WAIT_TIME
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

func _reset_all(recurse_check := true, pop_wait_check := true):
	for y in height:
		for x in width:
			var b:Block2 = current_level[x][y]
			if b == null: continue
			b.reset_flags(recurse_check, pop_wait_check)

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
