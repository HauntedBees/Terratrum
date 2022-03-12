extends Node2D
class_name LevelManager

const family = preload("res://MainGame/BlockFamily.gd")
const piece = preload("res://MainGame/Block.tscn")
onready var full_level_info: Levels.FullLevelInfo = SceneSwitcher.get_carried_scene_data()
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
	#level_seed = level_info.level_seed if level_info != null && level_info.level_seed != 0 else randi() % 10000000
	#level_seed = 9102156
	level_seed = 6202397
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

func get_block_v(v:Vector2) -> Block: return get_block(int(v.x), int(v.y))
func get_block(x:int, y:int) -> Block: return get_block_from(current_level, x, y)
func get_block_from(level, x:int, y:int) -> Block: return null if out_of_bounds(x, y) else level[x][y]
func set_block(x:int, y:int, new_val:Block):
	if out_of_bounds(x, y): return
	current_level[x][y] = new_val

func grid_to_map(x:int, y:int) -> Vector2: return Vector2(x * block_size + offset.x, y * block_size + offset.y)
func map_to_grid(p: Vector2) -> Vector2: return Vector2(floor((p.x - offset.x) / block_size), floor((p.y - offset.y) / block_size))

func get_player_pos(player:KinematicBody2D) -> Vector2: return map_to_grid(player.position + player_offset)

func get_difficulty_info(idx: int): # TODO: expand to support looping and such
	return difficulty_curve[int(min(idx, difficulty_curve.size() - 1))]

func create_block(type:String, x:int, y:int) -> Block:
	#var f:BlockFamily = family.new()
	var b:Block = piece.instance()
	b.type = type
	b.grid_pos = Vector2(x, y)
	b.name = "%s (%s, %s)" % [type, x, y]
	b.scale *= block_scale
	#f.add_block(b)
	return b

func try_linking_with_above_and_left(level: Array, block: Block):
	var left:Block = get_block_from(level, block.grid_pos.x - 1, block.grid_pos.y)
	if block.grid_pos.x > 0 && block.try_link(left):
		block.left = left
		left.right = block
	var above:Block = get_block_from(level, block.grid_pos.x, block.grid_pos.y - 1)
	if block.grid_pos.y > 0 && block.try_link(above):
		block.above = above
		above.below = block

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
func _process(_delta): make_next_level()
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
	var top_chunk := _get_debug_top(5)
	#var top_chunk:Array = [] if delayed else _get_level_top(level_info.colors) # "!delayed" is equivalent to "top of level"
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
	b.calculate_mask_offset(get_block(x, y - 1), get_block(x + 1, y), get_block(x, y + 1), get_block(x - 1, y))
	if redraw_neighbors:
		_redraw_block(x - 1, y, false)
		_redraw_block(x + 1, y, false)
		_redraw_block(x, y - 1, false)
		_redraw_block(x, y + 1, false)

func pop(b:Block, wiggle:bool):
	var fall_info := _pop(b.grid_pos.x, b.grid_pos.y, b.type)
	get_falls(fall_info, false, wiggle)
func _pop(x:int, y:int, type:String) -> Vector3:
	if x < 0 || y < 0 || x >= width || y >= height: return BAD_RECT
	var b:Block = current_level[x][y]
	if b == null || b.status == Block.BlockStatus.POPPING || b.type != type: return BAD_RECT
	b.pop()
	var rect := Vector3(b.grid_pos.x, b.grid_pos.x, b.grid_pos.y)
	rect = _expand_rect(rect, _pop(x - 1, y, type))
	rect = _expand_rect(rect, _pop(x + 1, y, type))
	rect = _expand_rect(rect, _pop(x, y - 1, type))
	rect = _expand_rect(rect, _pop(x, y + 1, type))
	highest_y = max(rect.z + 1, highest_y)
	return rect

var lowest_y := 0
var highest_y := 0
func _physics_process(delta:float):
	# 1. drop all the blocks that are falling
	var drop_range := Vector3(width, -1, lowest_y)
	for y in range(highest_y - 1, lowest_y - 1, -1):
		for x in width:
			var b:Block = current_level[x][y]
			if b == null: continue
			b.was_counted = false
			if b.status == Block.BlockStatus.POPPING:
				b.pop_time -= delta
				if b.pop_time <= 0.0:
					b.finish_pop()
					current_level[x][y] = null
			b.drop_status = Block.DropStatus.CANNOT_FALL
			b.drop_iter = 0
			var drop_amount := delta
			if b.status == Block.BlockStatus.PREFALL && b.wiggle_time > 0:
				b.wiggle_time -= delta
				if b.wiggle_time <= 0:
					drop_amount += b.wiggle_time
					b.status = Block.BlockStatus.FALL
			if b.status == Block.BlockStatus.FALL:
				var advanced := b.fall(drop_amount, grid_to_map(x, y + 1).y)
				if advanced:
					b.status = Block.BlockStatus.FELL
					drop_range.x = min(drop_range.x, x)
					drop_range.y = max(drop_range.y, x)
					drop_range.z = max(drop_range.z, y + 1)
					current_level[x][y] = null
					current_level[x][y + 1] = b
	# 2. go through all the blocks that just finished falling and see if they can fall more
	if drop_range.y < 0: return
	get_falls(drop_range, true, false)
	# 3. for the ones that can't: clamp em to their positions and mark 'em out.
	var blocks_to_pop := []
	for y in (drop_range.z + 1):
		for x in range(drop_range.x, drop_range.y + 1):
			var b:Block = current_level[x][y]
			if b == null: continue
			if b.status != Block.BlockStatus.FELL: continue
			if b.drop_status == Block.DropStatus.CANNOT_FALL:
				b.status = Block.BlockStatus.NONE
				b.position.y = grid_to_map(x, y).y
				_redraw_block(x, y, true)
				if _count(x, y, b.type) >= 4:
					blocks_to_pop.append(b)
			else:
				b.status = Block.BlockStatus.FALL
	# 4. pop some fuckers!
	for b in blocks_to_pop:
		pop(b, false)

func _count(x:int, y:int, type:String) -> int:
	var b := get_block(x, y)
	if b == null || b.type != type || b.was_counted: return 0
	b.was_counted = true
	var count := 1
	count += _count(x - 1, y, type)
	count += _count(x + 1, y, type)
	count += _count(x, y - 1, type)
	count += _count(x, y + 1, type)
	return count

func get_falls(max_range:Vector3, fells_only:bool, wiggle:bool):
	# 1. flag all blocks that could potentially fall
	var new_max_y := max_range.z
	for y in (max_range.z + 1):
		for x in range(0, width):
			var b:Block = current_level[x][y]
			if b == null: continue
			if fells_only && b.status != Block.BlockStatus.FELL: continue
			if b.is_dead(): continue
			new_max_y = max(new_max_y, set_maybe_fall(x, y, b.type))
			#b.drop_status = Block.DropStatus.MAYBE_FALL
	# 2. repeatedly eliminate maybe_falls
	var iter := 0
	var checked_blocks := 0
	var inconclusive_blocks := -1
	while checked_blocks != inconclusive_blocks:
		checked_blocks = 0
		inconclusive_blocks = 0
		for y in (new_max_y + 1):
			for x in range(0, width):
				var b:Block = current_level[x][y]
				if b == null: continue
				if b.drop_status != Block.DropStatus.MAYBE_FALL: continue
				checked_blocks += 1
				# if this block or any block of the same type connected to
				# it cannot fall, it cannot fall!
				#if check_names.has(b.name): print("%s check %s" % [b.name, iter])
				if is_stuck(x, y, b.type, iter):
					#if check_names.has(b.name): print("%s is stuck" % b.name)
					b.drop_status = Block.DropStatus.CANNOT_FALL
				else:
					#if check_names.has(b.name): print("%s is good" % b.name)
					inconclusive_blocks += 1
		iter += 1
	# 3. make em wiggle
	#if !wiggle: return
	for y in (new_max_y + 1):
		#for x in range(max_range.x, max_range.y + 1):
		for x in range(0, width):
			var b:Block = current_level[x][y]
			if b == null: continue
			if b.drop_status == Block.DropStatus.MAYBE_FALL:
				if wiggle:
					wiggle(x, y, b.type)
				else:
					set_to_fall(x, y, b.type)

var check_names := ["red (3, 1)"]
#var check_names := ["green (2, 3)", "green (2, 2)", "green (3, 2)", "green (4, 2)"]

func is_stuck(x:int, y:int, type:String, iter:int) -> bool:
	if y == (height - 1): return true
	var b := get_block(x, y)
	if b == null: return false
	#if check_names.has(b.name): print("-- %s iter %s" % [b.name, iter])
	if b.type != type: return false
	if b.drop_iter > iter: return false
	if b.is_dead(): return false
	#if check_names.has(b.name): print("-- %s made it past those guys" % b.name)
	b.drop_iter += 1
	if b.drop_status == Block.DropStatus.CANNOT_FALL: return true
	#if check_names.has(b.name): print("-- %s not cannot fall" % b.name)
	var below := get_block(x, y + 1)
	#if b.name == "red (3, 0)": print("below %s (%s, %s) is %s (%s, %s)" % [b, x, y, below, x, y + 1])
#	if below != null && below.type != type && !below.is_dead() && below.drop_status == Block.DropStatus.CANNOT_FALL:
	if below != null && !below.is_dead() && below.drop_status == Block.DropStatus.CANNOT_FALL:
		#if check_names.has(b.name): print("-- %s below is a nopey" % b.name)
		return true
	if is_stuck(x + 1, y, type, iter): return true
	#if check_names.has(b.name): print("-- %s right is good" % b.name)
	if is_stuck(x - 1, y, type, iter): return true
	#if check_names.has(b.name): print("-- %s left is good" % b.name)
	if is_stuck(x , y + 1, type, iter): return true
	#if check_names.has(b.name): print("-- %s below is good" % b.name)
	if is_stuck(x, y - 1, type, iter): return true
	#if check_names.has(b.name): print("-- %s above is good" % b.name)
	return false

func wiggle(x:int, y:int, type:String):
	var b := get_block(x, y)
	if b == null: return
	if b.type != type: return
	if b.status == Block.BlockStatus.PREFALL: return
	b.wiggle()
	wiggle(x - 1, y, type)
	wiggle(x + 1, y, type)
	wiggle(x, y + 1, type)
	wiggle(x, y - 1, type)

func set_to_fall(x:int, y:int, type:String):
	var b := get_block(x, y)
	if b == null: return
	if b.type != type: return
	if b.status == Block.BlockStatus.PREFALL: return# || b.status == Block.BlockStatus.FALL: return
	b.pre_fall()
	#b.status = Block.BlockStatus.FALL
	set_to_fall(x - 1, y, type)
	set_to_fall(x + 1, y, type)
	set_to_fall(x, y + 1, type)
	set_to_fall(x, y - 1, type)

func set_maybe_fall(x:int, y:int, type:String) -> int:
	var b := get_block(x, y)
	if b == null: return -1
	if b.type != type: return -1
	if b.drop_status == Block.DropStatus.MAYBE_FALL: return -1
	b.drop_status = Block.DropStatus.MAYBE_FALL
	var high_y := y
	high_y = max(high_y, set_maybe_fall(x - 1, y, type))
	high_y = max(high_y, set_maybe_fall(x + 1, y, type))
	high_y = max(high_y, set_maybe_fall(x, y + 1, type))
	high_y = max(high_y, set_maybe_fall(x, y - 1, type))
	return high_y

# TODO: make a new class for this if this actually fucking works
const BAD_RECT := Vector3(-1, -1, -1) # x = min x, y = max x, z = max y

func _expand_rect(a:Vector3, b:Vector3) -> Vector3:
	if b.x < 0: return a
	return Vector3(min(a.x, b.x), max(a.y, b.y), max(a.z, b.z))
