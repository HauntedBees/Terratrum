extends Reference
class_name BlockFamily

var family := []
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
