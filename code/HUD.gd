extends MarginContainer

onready var info: Label = $VBoxContainer/InfoLabel
onready var debug: RichTextLabel = $VBoxContainer/DebugLabel
onready var player: Player = get_node("/root/Geemu/Player")
onready var game = get_node("/root/Geemu")

func get_block_disp(b, adv: bool = false) -> String:
	if b == null:
		return "000"
	elif adv:
		return "[color=%s][%s, %s][/color]" % [b.type, b.grid_pos.x, b.grid_pos.y]
	else:
		var color: String = b.type
		if b.type == "air": color = "#64A5FF"
		if b.type == "hard": color = "black"
		return "[color=%s]%s[/color]" % [color, (100 + (hash(b.family) % 900))]

func _process(_delta):
	handle_debug_shite()

func handle_debug_shite():
	if Input.is_key_pressed(KEY_Z):
		var player_pos = game.get_player_pos()
		var start_height = max(0, player_pos.y - 4)
		var grid = "\n"
		for y in range(start_height, game.height):
			var disp_row = ""
			for x in game.width:
				if(player_pos == Vector2(x, y)):
					disp_row += "[color=#DD52C8]420[/color]"
				else:
					disp_row += get_block_disp(game.get_block(x, y))
			grid += disp_row + "\n"
		debug.bbcode_text = grid
	else:
		debug.bbcode_text = ""
