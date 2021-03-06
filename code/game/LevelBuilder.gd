extends Node2D
class_name LevelBuilder
signal lb_ready(lb)

const piece = preload("res://scenes/game/Block.tscn")
onready var full_level_info: Levels.FullLevelInfo = SceneSwitcher.get_carried_scene_data()
var current_potential_types := ["red", "blue", "green", "yellow"]
var potential_types := ["red", "blue", "green", "yellow"]
var difficulty_curve := []
var air_every_x_rows := 5 # 5 = easy, 12 = hard
var bad_block_percent := 3.7143 # between 3.7143 and 5.1587
var max_depth := 0

var width := 7 # 5/7/9/11 NOTE: fucks up more on sizes that aren't 7
var height := 100
var offset := Vector2(100, 0)
var block_scale := 1.0
var block_size := Consts.BLOCK_SIZE

var level_number := 0
var current_level := []
var next_level := []
var next_level_builder = null

func _ready():
	var level_info := full_level_info.level
	emit_signal("lb_ready", self)
	width = level_info.level_width
	block_scale = 7.0 / width
	block_size = block_scale * Consts.BLOCK_SIZE
	difficulty_curve = level_info.difficulty_set if level_info != null else [Menu.DifficultyInfo.new(4, 0, 0)]
	max_depth = level_info.max_depth if level_info != null else 0
	randomize()
	var wow_real_seed = level_info.level_seed if level_info != null && level_info.level_seed != 0 else randi() % 10000000
	seed(wow_real_seed)
	print(wow_real_seed)
	current_level = get_2d_array(width, height)
	continue_making_level(current_level, get_difficulty_info(0), false)
	current_potential_types = potential_types
	start_making_next_level()

# General Helper Methods
func rand_percent() -> float: return randf() * 100
func get_block_from(level, x, y): return null if out_of_bounds(int(x), int(y)) else level[int(x)][int(y)]
func get_block(x, y): return null if out_of_bounds(int(x), int(y)) else current_level[int(x)][int(y)]
func get_block_v(v: Vector2): return get_block(v.x, v.y)
func grid_to_map(x: int, y: int) -> Vector2: return Vector2(x * block_size + offset.x, y * block_size + offset.y)
func map_to_grid(p: Vector2) -> Vector2: return Vector2(floor((p.x - offset.x) / block_size), floor((p.y - offset.y) / block_size))
func out_of_bounds(x: int, y: int) -> bool: return y < 0 || y >= height || x < 0 || x >= width
func get_player_pos(player) -> Vector2: return map_to_grid(player.position)
# Array Helper Methods
func arr_rand(arr): return arr[randi() % arr.size()]
func arr_every(arr: Array, function_name: String) -> bool:
	var f = funcref(self, function_name)
	for i in arr:
		if !f.call_func(i):
			return false
	return true

func get_difficulty_info(idx: int): # TODO: expand to support looping and such
	return difficulty_curve[int(min(idx, difficulty_curve.size() - 1))]

func create_block(type: String, x: int, y: int) -> Block:
	var b: Block = piece.instance()
	b.type = type
	b.grid_pos = Vector2(x, y)
	b.scale *= block_scale
	return b
func try_linking_with_above_and_left(level: Array, block: Block):
	if block.grid_pos.x > 0: try_link_blocks(get_block_from(level, block.grid_pos.x - 1, block.grid_pos.y), block)
	if block.grid_pos.y > 0: try_link_blocks(get_block_from(level, block.grid_pos.x, block.grid_pos.y - 1), block)
func try_link_blocks(potential_established_block, new_block: Block):
	if potential_established_block == null: return
	var established_block := (potential_established_block as Block)
	if established_block.type != new_block.type: return
	if new_block.type == "air" || established_block.type == "air": return
	if established_block.family.find(new_block) < 0:
		established_block.family.append_array(new_block.family)
		for b in new_block.family:
			b.family = established_block.family

func clear_level():
	for x in width:
		for y in height:
			var b = current_level[x][y]
			if b == null: continue
			current_level[x][y] = null
			b.permanent_dissipation()
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
	var top_chunk = [] if delayed else get_level_top(level_info.colors) # "!delayed" is equivalent to "top of level"
	var special_occasions := get_air_sections()
	#var special_occasions := get_fake_shit()#get_air_sections()
	for y in height:
		#var air_x := randi() % width if y % air_every_x_rows == 0 else -1
		for x in width:
			if y < 4 && !delayed:
				var block := create_block(top_chunk[y][x], x, y)
				try_linking_with_above_and_left(level, block)
				level[x][y] = block
			else:
				var type: String = arr_rand(potential_types)
				var key = "%s,%s" % [x, y]
				if special_occasions.has(key):
					type = special_occasions[key]
				elif rand_percent() < bad_block_percent:
					type = "hard"
				var block := create_block(type, x, y)
				try_linking_with_above_and_left(level, block)
				level[x][y] = block
				if delayed: yield()
func get_level_top(num_colors: int) -> Array:
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

func get_fake_shit() -> Dictionary: # TODO: find out what actually fucks up the thing still
	var ooo = [
		"GGGGGGB",
		"RRRGGGB",
		"RRRGGGB",
		"RGGGGGB",
		"RRRRRRG",
		"BBBBBBB",
		"RRRGGGB",
		"RRRGGGB"
	]
	var fake_shit := {}
	for y in ooo.size():
		var aaa:String = ooo[y]
		for x in aaa.length():
			var bbb:String = aaa[x]
			var key := "%s,%s" % [x, y + 4]
			match bbb:
				"R": fake_shit[key] = "red"
				"G": fake_shit[key] = "green"
				"B": fake_shit[key] = "blue"
	return fake_shit

func get_air_sections() -> Dictionary:
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
