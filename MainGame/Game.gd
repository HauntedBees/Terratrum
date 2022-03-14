extends Node2D

onready var lm:LevelManager = $LevelManager
onready var bc := $BlockContainer
onready var player:DigPlayer = $Player

func _ready():
	bc.transform.origin.x = (-lm.width * lm.block_size + lm.block_size) / 2.0
	draw_level(lm.current_level)

func draw_level(level:Array):
	for x in lm.width:
		for y in lm.height:
			var b:Block = level[x][y]
			if b == null: continue
			b.position = lm.grid_to_map(x, y)
			b.connect("debug_kill", self, "_debug_kill", [b])
			bc.add_child(b)
	player.scale = Vector2(lm.block_scale, lm.block_scale)
func _refresh_block(b:Block):
	yield(get_tree(), "idle_frame")
	b.redraw_block()

func _process(_delta):
	if GASInput.is_action_just_pressed("ui_accept"):
		_player_drill()
		print(lm.get_player_pos(player))
	
	if Input.is_action_just_pressed("ui_cancel"):
		var f := File.new()
		f.open("user://replay.json", File.WRITE)
		f.store_string("%s\n" % lm.level_seed)
		f.store_string(JSON.print(debug_dels))
		f.close()
		print("Saved to %s/replay.json" % OS.get_user_data_dir())
	if Input.is_action_just_pressed("ui_focus_next") && replay.size() > 0:
		var block = $BlockContainer.get_node_or_null(replay[0])
		if block == null: return
		replay.remove(0)
		_debug_kill(block)

var replay := ["red (3, 0)","green (3, 1)","blue (3, 2)","red (3, 3)","blue (4, 4)","yellow (5, 8)","green (4, 8)","yellow (3, 8)","green (3, 9)","hard (4, 10)","yellow (2, 10)","yellow (4, 6)","yellow (3, 11)","green (1, 13)","red (4, 13)","green (3, 14)","yellow (3, 16)","blue (3, 17)","hard (3, 19)","green (4, 19)","red (3, 20)","yellow (3, 21)","red (3, 22)","green (4, 22)","green (3, 23)","air (2, 20)","blue (2, 19)","red (2, 26)","green (3, 26)","blue (4, 26)","hard (1, 26)","red (0, 26)","air (0, 25)","red (0, 24)"]
var debug_dels := []
func _debug_kill(block:Block):
	if block == null: return
	debug_dels.append(block.name)
	print("%s: %s" % [block.name, block.grid_pos])
	lm.pop(block, LevelManager.FallCause.PLAYER)

func _player_drill():
	if !player.can_dig(): return
	player.drill_cooldown = Consts.POP_HOLD_TIME
	var block:Block = lm.get_block_by_player(player, player.active_direction)
	if block == null: return
	debug_dels.append(block.name)
	lm.pop(block, LevelManager.FallCause.PLAYER)
	# TODO: scoring
