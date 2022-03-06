extends Node2D
class_name BlockManager

onready var lm:LevelManager = get_parent().get_node("LevelManager")
var min_y := 0
var falling_families := []

func destroy_family_return_info(f:BlockFamily) -> Dictionary:
	var info := {
		"lowest_y": 0,
		"blocks_cleared": 0
	}
	print(f.family)
	for b in f.list():
		var by:int = b.grid_pos.y
		if by > info["lowest_y"]: info["lowest_y"] = by
		info["blocks_cleared"] += 1
		lm.set_block(b.grid_pos.x, by, null)
		b.family = null
		b.unlink_neighbors()
		b.queue_free()
	return info

func set_potential_falls(max_y:int):
	for x in lm.width:
		for y in range(min_y, max_y + 1):
			var b:Block = lm.get_block(x, y)
			if b == null: continue
			var bf:BlockFamily = b.family
			if bf == null: continue
			if falling_families.find(bf) < 0:
				falling_families.append(bf)

func _physics_process(delta):
	var can_drops := []
	var blockers := {}
	# Get all families that can fall, and all families that cannot
	for f in falling_families:
		var my_blockers := []
		for b in f.family:
			var below := lm.get_block(b.grid_pos.x, b.grid_pos.y + 1)
			if below != null && below.family != f:
				# TODO: check if it's falling or whatever
				var my_blocker := below.family
				if my_blockers.find(my_blocker) < 0:
					my_blockers.append(my_blocker)
		if my_blockers.size() == 0: can_drops.append(f)
		else: blockers[f] = my_blockers
	# For all the families that can't fall, check if the reason they can't
	# fall is because they're tangled with other families, or if the family
	# blocking them is already falling; if that's the case, let them fall.
	# Otherwise, stop the family from falling. 
	var blocked_families := blockers.keys()
	while blocked_families.size() > 0:
		for f in blocked_families:
			if !blockers.has(f): continue
			var can_fall := false
			var needs_double_check := false
			for blocking_family in blockers[f]:
				# Stopped by a family that's also falling, so it's fine
				if can_drops.find(blocking_family) >= 0:
					can_fall = true
				# TODO: Stopped by a family stopped by this
				if blockers.has(blocking_family):
					needs_double_check = true
				else:
					needs_double_check = false
					break
			if can_fall:
				can_drops.append(f)
				blockers.erase(f)
			elif needs_double_check:
				pass
			else:
				falling_families.erase(f)
				blockers.erase(f)
		blocked_families = blockers.keys()
	var dropped_one_tile := []
	# Drop em all down.
	for f in can_drops:
		for vb in f.family:
			var b:Block = vb
			b.transform.origin.y += Consts.BLOCK_SIZE * delta
			if b.transform.origin.y >= lm.grid_to_map(b.grid_pos.x, b.grid_pos.y + 1).y && dropped_one_tile.find(f) < 0:
				dropped_one_tile.append(f)
	# TODO: handle if top block finishes falling into bottom before bottom leaves its tile
	for f in dropped_one_tile:
		for b in f.family:
			lm.set_block(b.grid_pos.x, b.grid_pos.y, null)
			b.grid_pos.y += 1
	for f in dropped_one_tile:
		for b in f.family:
			lm.set_block(b.grid_pos.x, b.grid_pos.y, b)
