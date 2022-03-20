extends HUDValue

onready var lm:LevelManager2 = owner.get_node("HUD/MarginContainer/Game/GameSpace/Viewport/Game/LevelManager")
func _process(_delta): _set_val("%s" % lm.score)
