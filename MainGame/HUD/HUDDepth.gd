extends HUDValue

onready var lm:LevelManager2 = owner.get_node("HUD/MarginContainer/Game/GameSpace/Viewport/Game/LevelManager")
func _process(_delta):
	var depth := lm.get_player_pos().y + 1
	_set_val("%sm" % depth)
