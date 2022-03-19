extends LevelHandler
class_name LevelBuilder2

onready var full_level_info: Levels.FullLevelInfo = SceneSwitcher.get_carried_scene_data()
const piece = preload("res://MainGame/Block2.tscn")


var current_potential_types := ["red", "blue", "green", "yellow"]
var potential_types := ["red", "blue", "green", "yellow"]
var air_every_x_rows := 5 # 5 = easy, 12 = hard
var bad_block_percent := 3.7143 # between 3.7143 and 5.1587
var max_depth := 0

var level_number := 0
var next_level := []
var next_level_builder = null
var level_seed := 0
var block_scale := 1.0
var block_size := Consts.BLOCK_SIZE
var difficulty_curve := []

func _ready():
	var level_info := full_level_info.level
	width = level_info.level_width
	block_scale = 7.0 / width
	block_size = block_scale * Consts.BLOCK_SIZE
	difficulty_curve = level_info.difficulty_set if level_info != null else [Menu.DifficultyInfo.new(4, 0, 0)]
	max_depth = level_info.max_depth if level_info != null else 0
	randomize()
	#level_seed = level_info.level_seed if level_info != null && level_info.level_seed != 0 else randi() % 10000000
	level_seed = 1126572
	#level_seed = 9102156
	#level_seed = 6202397
	seed(level_seed)
	print(level_seed)
	current_level = get_2d_array(width, height)
	continue_making_level(current_level, get_difficulty_info(0), false)
	current_potential_types = potential_types
	start_making_next_level()

func get_difficulty_info(idx: int): # TODO: expand to support looping and such
	return difficulty_curve[int(min(idx, difficulty_curve.size() - 1))]

func arr_rand(arr:Array): return arr[randi() % arr.size()]
func rand_percent() -> float: return randf() * 100

## slowly build the next level over time (creating one block per frame in _process)
## because creating 700+ block instances at once does exactly what you'd expect it to.
func _process(_delta): make_next_level()

func make_empty_current_level(): current_level = get_2d_array(width, height)
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
	var top_chunk := _get_debug_top(8)
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

func create_block(type:String, x:int, y:int) -> Block2:
	var b:Block2 = piece.instance()
	b.type = type
	b.name = "%s (%s, %s)" % [type, x, y]
	b.scale *= block_scale
	return b

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
		8: # wow new fucko
			return [
				_expand("BGGRRRR"),
				_expand("BGBBRRR"),
				_expand("BRRRRRR"),
				_expand("BRRBGGG"),
				_expand("HHHHHHH")
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
