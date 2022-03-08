extends Node2D
class_name BlockManager

onready var lm:LevelManager = get_parent().get_node("LevelManager")
onready var bc:Node2D = get_parent().get_node("BlockContainer")
var falling_families := []
var wiggling_families := []

func set_potential_falls(max_y:int, from_player:bool):
	for vb in bc.get_children():
		if !(vb is Block): continue
		var bf:BlockFamily = vb.family
		if bf == null: continue
		if !bf.potentially_affected(max_y): continue
		if falling_families.find(bf) < 0:
			falling_families.append(bf)
			if from_player: wiggling_families.append(bf)

# TODO: constantly monitor for fuckiness!
func _physics_process(delta:float):
	# Get all families that can fall, and all families that cannot
	var can_drops := []
	var blockers := {}
	var families_to_destroy := []
	for f in falling_families:
		var my_blockers := []
		if f.falling:
			can_drops.append(f)
			continue
		for b in f.family:
			var below:Block = (b as Block).below
			if below != null && below.family != f:
				# TODO: check if it's falling or whatever maybe
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
				if f.just_stopped && f.size() >= 4 && families_to_destroy.find(f) < 0:
					families_to_destroy.append(f)
				f.just_stopped = false
				falling_families.erase(f)
				wiggling_families.erase(f)
				blockers.erase(f)
		blocked_families = blockers.keys()
	
	# Drop em all down.
	var dropped_one_tile := []
	for f in can_drops:
		var wiggle := wiggling_families.find(f)
		var do_wiggle:bool = wiggle >= 0
		if do_wiggle: wiggling_families.erase(f)
		var done:bool = f.wiggle_or_drop_return_if_done(lm, delta, do_wiggle)
		if done && dropped_one_tile.find(f) < 0: dropped_one_tile.append(f)
	for f in dropped_one_tile:
		for b in f.clone():
			b.move_down()
	
	# Clear anything that got wiped out during this whole deal
	for f in families_to_destroy: queue_destroy_family_return_info(f)

func destroy_family_return_max_y(f:BlockFamily) -> int:
	var max_y := 0
	for b in f.list():
		if b == null || !is_instance_valid(b): continue
		var by:int = b.grid_pos.y
		if by > max_y: max_y = by
		b.family = null
		b.unlink_neighbors()
		b.queue_free()
	falling_families.erase(f)
	wiggling_families.erase(f)
	return max_y
	
func destroy_family_return_info(f:BlockFamily) -> Dictionary:
	var info := {
		"lowest_y": 0,
		"blocks_cleared": 0
	}
	for b in f.list():
		if b == null || !is_instance_valid(b): continue
		var by:int = b.grid_pos.y
		if by > info["lowest_y"]: info["lowest_y"] = by
		info["blocks_cleared"] += 1
		b.family = null
		b.unlink_neighbors()
		b.queue_free()
	falling_families.erase(f)
	return info

func queue_destroy_family_return_info(f:BlockFamily, from_player := false) -> Dictionary:
	var info := {
		"lowest_y": 0,
		"blocks_cleared": 0
	}
	for b in f.list():
		if b == null || !is_instance_valid(b): continue
		var by:int = b.grid_pos.y
		if by > info["lowest_y"]: info["lowest_y"] = by
		info["blocks_cleared"] += 1
	falling_families.erase(f)
	f.prepare_to_die()
	get_tree().create_timer(Consts.ACTION_TIME).connect("timeout", self, "_on_family_flickered", [f, from_player])
	return info

func _on_family_flickered(f:BlockFamily, from_player:bool):
	var max_y := destroy_family_return_max_y(f)
	set_potential_falls(max_y, from_player)
