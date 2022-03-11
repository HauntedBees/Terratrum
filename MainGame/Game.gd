extends Node2D

onready var lm:LevelManager = $LevelManager
onready var bc := $BlockContainer
onready var player := $Player

func _ready():
	bc.transform.origin.x = (-lm.width * lm.block_size + lm.block_size) / 2.0
	draw_level(lm.current_level)

func draw_level(level:Array):
	var families := []
	for x in lm.width:
		for y in lm.height:
			var b:Block = level[x][y]
			b.position = lm.grid_to_map(x, y)
			b.connect("debug_kill", self, "_debug_kill", [b])
			if !families.has(b.family2):
				families.append(b.family2)
				bc.add_child(b.family2)
			#bc.add_child(b)
			_refresh_block(b)
func _refresh_block(b:Block):
	yield(get_tree(), "idle_frame")
	b.redraw_block()

func _process(_delta):
	if GASInput.is_action_just_pressed("ui_accept"):
		_player_drill()
	
	if Input.is_action_just_pressed("ui_cancel"):
		var f := File.new()
		f.open("user://replay.json", File.WRITE)
		f.store_string("%s\n" % lm.level_seed)
		f.store_string(JSON.print(debug_dels))
		f.close()
		print("Saved to %s/replay.json" % OS.get_user_data_dir())
	if Input.is_action_just_pressed("ui_focus_next") && replay.size() > 0:
		var block = $BlockContainer.get_node(replay[0])
		replay.remove(0)
		_debug_kill(block)

var replay := ["yellow (3, 5)","red (3, 7)","yellow (3, 9)","green (3, 11)","yellow (3, 12)","green (4, 14)","yellow (4, 15)","green (5, 17)","green (5, 20)"]
var debug_dels := []
func _debug_kill(block:Block):
	if block == null: return
	debug_dels.append(block.name)
	print(block.family2)
	block.family2.pop(true)

func _player_drill():
	var drill_dir:Vector2 = player.active_direction
	#var steps := 3 if player.character == "Wombat" else 1
	var block:Block = null
	match drill_dir:
		Vector2(1, 0): block = player.right
		Vector2(-1, 0): block = player.left
		Vector2(0, 1): block = player.below
		Vector2(0, -1): block = player.above
	if block == null: return
	debug_dels.append(block.name)
	print(block.family2)
	block.family2.pop(true)
	# TODO: scoring
