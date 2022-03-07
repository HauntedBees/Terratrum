extends Node2D
class_name BlockManager

onready var lm:LevelManager = get_parent().get_node("LevelManager")
onready var bc:Node2D = get_parent().get_node("BlockContainer")
var min_y := 0
var falling_families := []

# TODO: this fucks up if a block joins a dying family
func destroy_family_return_info(f:BlockFamily) -> Dictionary:
	var info := {
		"lowest_y": 0,
		"blocks_cleared": 0
	}
	for b in f.list():
		var by:int = b.grid_pos.y
		if by > info["lowest_y"]: info["lowest_y"] = by
		info["blocks_cleared"] += 1
		b.family = null
		b.unlink_neighbors()
		b.queue_free()
	falling_families.erase(f)
	return info

func set_potential_falls(max_y:int):
	for vb in bc.get_children():
		if !(vb is Block): continue
		var bf:BlockFamily = vb.family
		if bf == null: continue
		if !bf.potentially_affected(max_y): continue
		if falling_families.find(bf) < 0:
			falling_families.append(bf)

# TODO: there's *something* fucky that happens sometimes
func _physics_process(delta:float):
	# Get all families that can fall, and all families that cannot
	var can_drops := []
	var blockers := {}
	var families_to_destroy := []
	for f in falling_families:
		var my_blockers := []
		for b in f.family:
			var below:Block = (b as Block).below
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
			var can_fall := true
			var needs_double_check := false
			for blocking_family in blockers[f]:
				# Stopped by a family that's also falling, so it's fine
				if can_drops.find(blocking_family) >= 0:
					continue
				# TODO: Stopped by a family stopped by this
				if blockers.has(blocking_family):
					needs_double_check = true
					can_fall = false
					break
				else:
					can_fall = false
					break
			if can_fall:
				can_drops.append(f)
				blockers.erase(f)
			elif needs_double_check:
				# TODO double check
				pass
			else:
				if f.falling && f.size() >= 4 && families_to_destroy.find(f) < 0:
					families_to_destroy.append(f)
				f.falling = false
				falling_families.erase(f)
				blockers.erase(f)
		blocked_families = blockers.keys()
	
	# Drop em all down.
	var dropped_one_tile := []
	for f in can_drops:
		for vb in f.family:
			var b:Block = vb
			b.transform.origin.y += Consts.BLOCK_SIZE * delta
			var next_spot := lm.grid_to_map(b.grid_pos.x, b.grid_pos.y + 1).y
			if round(b.transform.origin.y + 0.1) >= next_spot:
				b.transform.origin.y = next_spot
				if dropped_one_tile.find(f) < 0:
					dropped_one_tile.append(f)
	for f in dropped_one_tile:
		f.falling = true
		for b in f.clone():
			b.move_down()
	
	# Clear anything that got fuckied during this whole deal
	#var lowest_y := -1
	for f in families_to_destroy:
		f.prepare_to_die()
		get_tree().create_timer(Consts.ACTION_TIME).connect("timeout", self, "_on_family_flickered", [f])
		#var info := destroy_family_return_info(f)
		#lowest_y = max(info["lowest_y"], lowest_y)
	#if lowest_y > -1: set_potential_falls(lowest_y)

func _on_family_flickered(f:BlockFamily):
	var info := destroy_family_return_info(f)
	set_potential_falls(info["lowest_y"])
