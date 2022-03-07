extends Reference
class_name BlockFamily

var family := []
var falling := false
var wiggle_time := 0.0
func _init(starter): family.append(starter)
func list() -> Array: return family
func size() -> int: return family.size()
func join(b:BlockFamily):
	if b == self: return
	if b == null:
		print("THIS SHOULDN'T HAPPEN")
		return
	for n in b.family: n.family = self
	family.append_array(b.family)
func potentially_affected(max_y:int) -> bool:
	for b in family:
		if b.grid_pos.y <= max_y: return true
	return false
func clone() -> Array: return family.duplicate()

func prepare_to_die():
	for b in family:
		b.flicker()

func wiggle_or_drop_return_if_done(lm, delta:float, wiggle:bool) -> bool:
	var is_done := false
	if wiggle:
		for b in family: b.wiggle()
		wiggle_time = Consts.ACTION_TIME
	elif wiggle_time > 0.0:
		wiggle_time -= delta
		if wiggle_time < 0.0: delta = -wiggle_time
	if wiggle_time <= 0.0:
		for b in family:
			b.transform.origin.y += Consts.BLOCK_SIZE * delta
			var next_spot:float = lm.grid_to_map(b.grid_pos.x, b.grid_pos.y + 1).y
			if round(b.transform.origin.y + 0.1) >= next_spot:
				b.transform.origin.y = next_spot
				is_done = true
	return is_done
