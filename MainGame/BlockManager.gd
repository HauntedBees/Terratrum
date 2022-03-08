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
		if !falling_families.has(bf):
			falling_families.append(bf)
			if from_player: wiggling_families.append(bf)

# TODO: constantly monitor for fuckiness!
func _physics_process(delta:float):
	var can_drops := []
	var wigglers := []
	var blockers := {} # BlockFamily:BlockFamily[]
	var families_to_destroy := []
	# Get all families that can DEFINITELY fall (no blocks below them),
	# and all families that might not be able to (blocks below them, checks validity in next step)
	for f in falling_families:
		var my_blockers := []
		if f.wiggle_time > 0.0:
			f.wiggle_or_drop_return_if_done(lm, delta, false)
			wigglers.append(f)
			continue
		if f.falling:
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
			var wiggle_hold := false
			
#			print("blockers for %s" % f.debug_name)
#			for qq in blockers[f]:
#				print(" - %s" % qq.debug_name)
			var i := 0
			while i < blockers[f].size():
				var blocking_family:BlockFamily = blockers[f][i]
				i += 1
#			for blocking_family in blockers[f]:
				#print("checking %s" % blocking_family.debug_name)
				if can_drops.has(blocking_family):
					# Stopped by a family that's also falling, so it's fine
					continue
				
				if wigglers.has(blocking_family):
					# Stopped by a wiggling block, so it shouldn't be removed from the
					# list of valid blocks because that block is ABOUT to fall, but it
					# can't fall now, so do nothing with it
					wiggle_hold = true
					continue
				
				if blockers.has(blocking_family):
					# Stopped by another family that is potentially blocked
					#print("%s has an issue with %s" % [f.debug_name, blocking_family.debug_name])
					var blockers_blockers:Array = blockers[blocking_family]
					if blockers_blockers.has(f):
						# Stopped by a family that is stopped by this,
						# the two cancel out and then we try in another pass
						#print("%s can cancel out with %s" % [f.debug_name, blocking_family.debug_name])
						blockers[f].erase(blocking_family)
						i -= 1
						blockers_blockers.erase(f)
						can_fall = false
						needs_double_check = true
					else:
						# Try reaching forward to find deeper blocking loops (i.e. A is blocked by
						# B, B is blocked by C, C is blocked by A) that wouldn't be caught by the
						# simple "is A blocked by B and is B blocked by A?" check above.
						can_fall = false
#						var shifted_blockers := _expand_blocking_families(f, blockers[f], blockers, true)
#						if shifted_blockers == blockers[f] || shifted_blockers.size() == 0:
#							print("completely stuck: %s" % f.debug_name)
#						#if shifted_blockers == blockers[f]:
#							# Reached forward and family A is blocked by family A; complete blockage
#							break
#						else:
#							# Reached forward and got something new; let's try again!
#							blockers[f] = shifted_blockers
#							i = shifted_blockers.size()
#							print("new for: %s" % f.debug_name)
#							for q in shifted_blockers:
#								print(" - %s" % q.debug_name)
#							needs_double_check = true
				else:
					# Stopped by something that isn't even POTENTIALLY falling
					can_fall = false
					break

			if wiggle_hold:
				blockers.erase(f)
			elif can_fall:
				can_drops.append(f)
				blockers.erase(f)
			elif needs_double_check:
				continue
			else:
				if f.just_stopped && f.size() >= 4 && !families_to_destroy.has(f):
					families_to_destroy.append(f)
				f.just_stopped = false
				falling_families.erase(f)
				wiggling_families.erase(f)
				blockers.erase(f)
		blocked_families = blockers.keys()
	
	# Drop em all down.
	var dropped_one_tile := []
	for f in can_drops:
		var do_wiggle := wiggling_families.has(f)
		if do_wiggle: wiggling_families.erase(f)
		var done:bool = f.wiggle_or_drop_return_if_done(lm, delta, do_wiggle)
		if done && !dropped_one_tile.has(f): dropped_one_tile.append(f)
	for f in dropped_one_tile:
		for b in f.clone():
			b.move_down()
	
	# Clear anything that got wiped out during this whole deal
	for f in families_to_destroy: queue_destroy_family_return_info(f)

func _expand_blocking_families(source:BlockFamily, blockers_to_expand:Array, full_blockers_list:Dictionary, is_first := false) -> Array:
	var blockers_minus_source := blockers_to_expand.duplicate()
	blockers_minus_source.erase(source)
	if !is_first && blockers_minus_source.size() <= 1: return blockers_to_expand
	if is_first && blockers_to_expand.size() <= 1: return blockers_to_expand
	var results := []
	for blocker in blockers_minus_source:
		if !full_blockers_list.has(blocker): continue
		var new_blockers := _expand_blocking_families(source, full_blockers_list[blocker], full_blockers_list)
		#if new_blockers.size() == 0:
		#	results.append(blocker)
		#else:
		#for new_blocker in new_blockers:
		#	if !results.has(new_blocker): results.append(new_blocker)
		results.append_array(new_blockers)
	return results

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
