extends Node2D
class_name BlockFamily

enum FamilyState { NORMAL, CHECKING, WIGGLING, FALLING, DYING }
var state:int = FamilyState.NORMAL
var popped := false
var blocks := []
onready var tween := Tween.new()
onready var timer := Timer.new()

func _ready():
	add_child(tween)
	add_child(timer)
func _to_string() -> String: return "!%s - %s" % [blocks[0].name, blocks.size()]

func join(f:BlockFamily):
	if f.state == FamilyState.DYING && state != FamilyState.DYING:
		f.join(self)
	else:
		for b in f.blocks: add_block(b)
		f.queue_free()
func add_block(b:Block):
	if blocks.has(b): return
	b.family = self
	blocks.append(b)
	var bp := b.get_parent()
	b.moving_families = true
	if bp != null: bp.remove_child(b)
	add_child(b)
	b.moving_families = false

func pop(player_initiated:bool):
	state = FamilyState.DYING
	popped = true
	for b in blocks: b.flicker()
	timer.start(Consts.ACTION_TIME)
	yield(timer, "timeout")
	if !is_instance_valid(self): return
	queue_free()
	for bf in get_above_neighbors():
		bf.try_fall(player_initiated)
func get_above_neighbors() -> Array:
	var above_neighbors := []
	for b in blocks:
		var potential_above:BlockFamily = b.get_above_neighbor()
		if potential_above == null: continue
		if potential_above.popped: continue
		if !above_neighbors.has(potential_above):
			above_neighbors.append(potential_above)
	return above_neighbors

func try_fall(make_em_wiggle:bool):
	# 1. Ripple upward and mark all families above this one as potentially falling
	var all_potential_families := mark_fall_upwards()
	# 2. Go through and remove any families that definitely cannot fall, repeating
	# until the size doesn't shrink, meaning that all remaining families can fall.
	var families_count := -1
	var checking_families := []
	while checking_families.size() != families_count:
		checking_families = all_potential_families.duplicate()
		for f_ in checking_families:
			var f:BlockFamily = f_
			if !f.is_fallable():
				f.state = FamilyState.NORMAL
				all_potential_families.erase(f)
		families_count = all_potential_families.size()
	# 3. Make those remaining guys fall
	for f_ in all_potential_families:
		var f:BlockFamily = f_
		if f.state == FamilyState.DYING: continue
		if make_em_wiggle: f.wiggle()
		else: f.fall()
func mark_fall_upwards(already_checked := []) -> Array:
	# don't need to mark the family for falling if it already is!
	if state == FamilyState.WIGGLING || state == FamilyState.FALLING: return []
	var checkable_families := [self]
	already_checked.append(self)
	state = FamilyState.CHECKING
	for b in blocks:
		if b.above == null: continue
		var baf:BlockFamily = b.above.family
		if baf == self: continue
		if already_checked.has(baf): continue
		var their_checks := baf.mark_fall_upwards(already_checked)
		checkable_families.append_array(their_checks)
	return checkable_families
func is_fallable() -> bool:
	for b_ in blocks:
		var b:Block = b_
		if b.is_at_bottom(): return false
		if b.below == null: continue
		var bbf:BlockFamily = b.below.family
		if bbf == self: continue
		if bbf.popped || bbf.state == FamilyState.CHECKING || bbf.state == FamilyState.FALLING: continue
		return false
	return true

func wiggle():
	if state == FamilyState.WIGGLING: return
	state = FamilyState.WIGGLING
	for b in blocks: b.wiggle()
	timer.start(Consts.ACTION_TIME)
	yield(timer, "timeout")
	if !is_instance_valid(self): return
	fall()
func fall():
	if state == FamilyState.FALLING: return
	state = FamilyState.FALLING
	continue_fall()
func continue_fall():
	if state == FamilyState.NORMAL: return
	for b_ in blocks:
		var b:Block = b_
		tween.interpolate_property(b, "position:y", b.position.y, b.position.y + Consts.BLOCK_SIZE, Consts.ACTION_TIME, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()
	yield(tween, "tween_all_completed")
	timer.start(Consts.TINY_TIME)
	yield(timer, "timeout")
	for b in blocks.duplicate():
		b.move_down()
	if is_fallable():
		timer.start(Consts.TINY_TIME)
		yield(timer, "timeout")
		continue_fall()
	else:
		stop_fall_upwards()
		timer.start(Consts.TINY_TIME)
		yield(timer, "timeout")
		if blocks.size() >= 4:
			pop(false)
func stop_fall_upwards(already_checked := []) -> Array:
	var checkable_families := [self]
	already_checked.append(self)
	state = FamilyState.NORMAL
	for b in blocks:
		if b.above == null: continue
		var baf:BlockFamily = b.above.family
		if baf == self: continue
		if already_checked.has(baf): continue
		var their_checks := baf.stop_fall_upwards(already_checked)
		checkable_families.append_array(their_checks)
	return checkable_families
