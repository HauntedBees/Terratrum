extends Camera2D
onready var initialx := global_position.x + Consts.CAMERA_LEFT_OFFSET
onready var game = get_node("/root/Geemu")

func _on_Geemu_set_camera_max_height(y):
	limit_bottom = game.lb.grid_to_map(0, y).y + Consts.CAMERA_BOTTOM_OFFSET
func _process(_delta): global_position.x = initialx
func _on_Geemu_clear_level():
	var new_bottom: float = game.lb.grid_to_map(0, game.lb.height).y + Consts.CAMERA_BOTTOM_OFFSET
	$Tween.interpolate_property(self, "limit_bottom", limit_bottom, new_bottom, 10, Tween.TRANS_LINEAR)
	$Tween.start()
