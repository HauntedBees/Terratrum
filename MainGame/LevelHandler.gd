extends Node2D
class_name LevelHandler

var width := 7 # 5/7/9/11 NOTE: fucks up more on sizes that aren't 7
var height := 100
var current_level := []

func out_of_bounds(x:int, y:int) -> bool: return y < 0 || y >= height || x < 0 || x >= width
func get_block_v(v:Vector2) -> Block2: return get_block(int(v.x), int(v.y))
func get_block(x:int, y:int) -> Block2: return get_block_from(current_level, x, y)
func get_block_from(level, x:int, y:int) -> Block2: return null if out_of_bounds(x, y) else level[x][y]
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
