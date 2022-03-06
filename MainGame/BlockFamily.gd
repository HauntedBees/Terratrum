extends Reference
class_name BlockFamily

var family := []
func _init(starter): family.append(starter)
func list() -> Array: return family
func join(b:BlockFamily):
	if b == self: return
	if b == null:
		print("THIS SHOULDN'T HAPPEN")
		return
	for n in b.family: n.family = self
	family.append_array(b.family)
