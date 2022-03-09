extends Node2D
class_name BlockManager

onready var lm:LevelManager = get_parent().get_node("LevelManager")
onready var bc:Node2D = get_parent().get_node("BlockContainer")
var falling_families := []
var wiggling_families := []

# TODO: this can probably be optimized
func set_potential_falls(max_y:int, from_player:bool):
	for vb in bc.get_children():
		if !(vb is Block): continue
		var bf:BlockFamily = vb.family
		if bf == null: continue
		if !bf.potentially_affected(max_y): continue
		if !falling_families.has(bf):
			falling_families.append(bf)
			if from_player: wiggling_families.append(bf)

func _physics_process(delta:float):
	var dnb := _get_drops_and_blockers()
	var can_drops := _calculate_full_drops(dnb["can_drops"], dnb["blockers"])
	_drop_blocks_and_destroy(can_drops, delta)

# 1. Get all families that can DEFINITELY fall (no blocks below them),
# all families that are currently wiggling, and all families that
# might not be able to (blocks below them, checks validity in next step)
func _get_drops_and_blockers() -> Dictionary:
	var can_drops := []
	var blockers := {} # BlockFamily:BlockFamily[]
	
	for f in falling_families:
		var my_blockers := []
		if f.wiggle_time > 0.0 || f.falling:
			can_drops.append(f)
			continue
		for b in f.family:
			var below:Block = (b as Block).below
			if below != null && below.family != f:
				var my_blocker := below.family
				if !my_blockers.has(my_blocker):
					my_blockers.append(my_blocker)
		if my_blockers.size() == 0: can_drops.append(f)
		else: blockers[f] = my_blockers
	
	return {
		"can_drops": can_drops,
		"blockers": blockers
	}

# 2. Sort through all the families that can MAYBE fall and figure them out
# TODO: things fuck up bad in test case 2
func _calculate_full_drops(can_drops:Array, blockers:Dictionary) -> Array:
	can_drops = can_drops.duplicate()
	var cant_drops := []
	var families_blocked_by_other_families := blockers.keys()
	while families_blocked_by_other_families.size() > 0:
		for bf in families_blocked_by_other_families:
			var blocked_family:BlockFamily = bf
			# already got cleared out by the Block.DropStatus.MAYBE_FALL condition below
			if !blockers.has(blocked_family): continue
			var bf_blockers:Array = blockers[blocked_family]
			var definitely_safe := true
			var wiggle_hold := false
			var already_validated_families := []
			for b_ in blocked_family.family:
				var b:Block = b_
				var fall_status := b.get_drop_info(can_drops, cant_drops, falling_families)
				match fall_status:
					Block.DropStatus.CANNOT_FALL:
						cant_drops.append(blocked_family)
						_purge_potential_fall(blocked_family)
						blockers.erase(blocked_family)
						definitely_safe = false
						break
					Block.DropStatus.MAYBE_FALL:
						# If A is blocked by B, and B is blocked by A, let them cancel out!
						var blocker_family := b.below.family
						if already_validated_families.has(blocker_family):
							continue
						elif blockers.has(blocker_family):
							var blocker_blockers:Array = blockers[blocker_family]
							if bf_blockers.has(blocker_family) && blocker_blockers.has(blocked_family):
								bf_blockers.erase(blocker_family)
								blocker_blockers.erase(blocked_family)
								#if bf_blockers.size() == 0: blockers.erase(blocked_family)
								#if blocker_blockers.size() == 0: blockers.erase(blocker_family)
								already_validated_families.append(blocker_family)
							else:
								definitely_safe = false
						else:
							definitely_safe = false
					Block.DropStatus.ABOVE_WIGGLE: wiggle_hold = true
			if wiggle_hold:
				blockers.erase(blocked_family)
			elif definitely_safe:
				can_drops.append(blocked_family)
				blockers.erase(blocked_family)
		families_blocked_by_other_families = blockers.keys()
	return can_drops

# 3. Drop all droppable blocks down and clear out any size 4+ families
func _drop_blocks_and_destroy(can_drops:Array, delta:float):
	var dropped_one_tile := []
	for f in can_drops:
		if wiggling_families.has(f):
			f.wiggle()
			wiggling_families.erase(f)
		else:
			var done:bool = f.drop_return_if_done(lm, delta)
			if done && !dropped_one_tile.has(f):
				dropped_one_tile.append(f)
	
	for f in dropped_one_tile:
		var bf:BlockFamily = f
		for b in bf.clone(): b.move_down()
		if bf.just_stopped && bf.size() >= 4:
			destroy_family_return_info(bf, false)

# either destroy a family immediately or let it flicker and then be destroyed
func destroy_family_return_info(f:BlockFamily, immediate:bool, from_player := false) -> Dictionary:
	var info := {
		"lowest_y": 0,
		"blocks_cleared": 0
	}
	for b in f.list():
		if b == null || !is_instance_valid(b): continue
		var by:int = b.grid_pos.y
		if by > info["lowest_y"]: info["lowest_y"] = by
		info["blocks_cleared"] += 1
		if immediate:
			b.family = null
			b.unlink_neighbors()
			b.queue_free()
	_purge_potential_fall(f)
	if !immediate:
		f.prepare_to_die()
		get_tree().create_timer(Consts.ACTION_TIME).connect("timeout", self, "_on_family_flickered", [f, from_player])
	return info
func _on_family_flickered(f:BlockFamily, from_player:bool):
	var info := destroy_family_return_info(f, true)
	set_potential_falls(info["lowest_y"], from_player)

# if a potentially falling family ends up not being ready to fall,
# clear it out of the falling and wiggling family arrays
func _purge_potential_fall(bf:BlockFamily):
	falling_families.erase(bf)
	wiggling_families.erase(bf)
