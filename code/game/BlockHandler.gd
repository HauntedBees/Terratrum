extends Node2D
class_name BlockHandler

var level: LevelBuilder
var dropping_families := []
var fading_families := []
func _on_LevelBuilder_lb_ready(lb: LevelBuilder): level = lb

class BlockSorter:
	static func sort_lowest_depth_first(a: Block, b: Block) -> bool:
		var ap := a.grid_pos
		var bp := b.grid_pos
		if ap.y > bp.y:
			return true
		elif ap.y < bp.y:
			return false
		elif ap.x > bp.x:
			return true
		else:
			return false

func _physics_process(delta):
	for i in range(fading_families.size() - 1, -1, -1):
		var family = fading_families[i]
		if family.size() == 0 || family[0] == null || !is_instance_valid(family[0]): # TODO: this shouldn't even happen
			print("yo what the FUCK")
			fading_families.remove(i)
		elif family[0].state == Block.BlockState.FADED:
			destroy_family(family, false)
			fading_families.remove(i)

	var blocks_to_drop := []
	var dropped_families := []
	for family in dropping_families:
		var already_added_to_dropped_families := false
		for b in family:
			var did_move := drop_block_return_if_moved(b, delta)
			if did_move && !already_added_to_dropped_families:
				already_added_to_dropped_families = true
				dropped_families.append(family)
				blocks_to_drop.append_array(family)
	blocks_to_drop.sort_custom(BlockSorter, "sort_lowest_depth_first")
	for b in blocks_to_drop:
		if b.grid_pos.y >= 0:
			level.current_level[b.grid_pos.x][b.grid_pos.y] = null
			level.current_level[b.grid_pos.x][b.grid_pos.y + 1] = b
		b.grid_pos.y += 1
	for bs in dropped_families:
		if check_if_stop_blocks(bs):
			dropping_families.remove(dropping_families.find(bs))
			for b in bs.duplicate():
				b.stop()
				make_potential_links(b)
			if bs.size() >= 4:
				bs[0].dissipate_family()
				fading_families.append(bs)

# moves dropped block and returns if it moved a full tile
func drop_block_return_if_moved(b: Block, delta: float) -> bool:
	if b == null: return false
	b.position.y += level.block_scale * Consts.DROP_SPEED * delta
	var new_pos := level.map_to_grid(b.position)
	var is_dropped := new_pos.y == (b.grid_pos.y + 1)
	if is_dropped: b.position.y = level.grid_to_map(int(new_pos.x), int(new_pos.y)).y # to prevent fuckiness
	return is_dropped

# wipe all of the blocks in the family and update any neighboring block
# families to start falling or, if by_player is true, start a-wiggling.
func destroy_family(family: Array, by_player: bool):
	var lowest_depth := 0
	#var lowest_x := level.width - 3
	#var highest_x := 1
	for b in family:
		lowest_depth = int(max(lowest_depth, b.grid_pos.y))
		#highest_x = int(max(highest_x, b.grid_pos.x))
		#lowest_x = int(min(lowest_x, b.grid_pos.x))
		wipe_block(b, by_player)
	var already_processed_families := []
	for y in range(lowest_depth + 1, -1, -1):
		for x in level.width:#range(lowest_x - 1, highest_x + 2):
			var potential_block = level.get_block(x, y)
			if potential_block == null: continue
			var block := (potential_block as Block)
			if already_processed_families.find(block.family) >= 0: continue
			already_processed_families.append(block.family)
			if block.state == Block.BlockState.INERT:
				if can_family_drop(block.family):
					dropping_families.append(block.family)
					if by_player:
						block.wiggle_family()
					else:
						block.drop_family()

func can_family_drop(bs: Array) -> bool:
	for b in bs:
		if !can_drop(b): return false
	return true
func can_drop(b: Block) -> bool:
	# can't drop into bottom of the world!
	if (b.grid_pos.y + 1) == level.height: return false
	# if space below is empty, this block can drop!
	var potential_below = level.get_block(b.grid_pos.x, b.grid_pos.y + 1)
	if potential_below == null: return true
	# if the below block isn't part of this block's family, this block can't drop, unless that block is also wiggling now,
	# (but only if this block is the bottom of its row, to prevent issues where a block is entirely consumed in a family
	# that would otherwise fall)
	if bottom_of_family_row(b):
		var below := (potential_below as Block)
		var block_in_family: bool = b.family.find(below) >= 0
		if !block_in_family: return below.state == Block.BlockState.WIGGLING || below.state == Block.BlockState.DROPPING
	# otherwise, say yes; blocks at the bottom of the family will fail if they collide
	return true
# checks if this block has the highest y value for its row (x value) in its family
func bottom_of_family_row(b: Block) -> bool:
	for n in b.family:
		if n.grid_pos.x != b.grid_pos.x: continue
		if n.grid_pos.y > b.grid_pos.y: return false
	return true

# checks if any block in the family can't move down or is now touching a non-family block of the same type
func check_if_stop_blocks(family: Array) -> bool:
	for b in family:
		if (b.grid_pos.y + 1) == level.height: return true
		var below = level.get_block(b.grid_pos.x, b.grid_pos.y + 1)
		var left = level.get_block(b.grid_pos.x - 1, b.grid_pos.y)
		var right = level.get_block(b.grid_pos.x + 1, b.grid_pos.y)
		if family.find(left) >= 0: left = null
		if family.find(right) >= 0: right = null
		var can_go_down: bool = below == null || (below as Block).state == Block.BlockState.DROPPING
		var stick_left: bool = left != null && (left as Block).can_be_stuck_to() && (left as Block).type == b.type
		var stick_right: bool = right != null && (right as Block).can_be_stuck_to() && (right as Block).type == b.type
		if stick_left || stick_right || !can_go_down:
			return true
	return false
# connects newly stopped blocks with any new neighbors of theirs
func make_potential_links(b: Block, top_left_only: bool = false):
	if !top_left_only:
		make_potential_link(b, -1, 0)
		make_potential_link(b, 0, -1)
	make_potential_link(b, 1, 0)
	make_potential_link(b, 0, 1)
func make_potential_link(b: Block, dx: int, dy: int):
	if b.type == "air": return
	var potential_neighbor = level.get_block(b.grid_pos.x + dx, b.grid_pos.y + dy)
	if potential_neighbor == null: return
	var neighbor := (potential_neighbor as Block)
	if neighbor.type == b.type && b.family.find(neighbor) < 0 && neighbor.can_be_stuck_to():
		b.family.append_array(neighbor.family)
		for n in b.family:
			n.family = b.family
			n.redraw_block()

# this is a great name for a function I feel very good about this
func separate_from_family(target_block: Block):
	level.current_level[target_block.grid_pos.x][target_block.grid_pos.y] = null
	restructure_family(target_block.family.duplicate())
func restructure_family(block_family: Array):
	var left := 9999; var right := -1;
	var highest := -1; var lowest := 9999;
	for b in block_family:
		b.family = [b]
		left = int(min(left, b.grid_pos.x))
		right = int(max(right, b.grid_pos.x))
		lowest = int(min(lowest, b.grid_pos.y))
		highest = int(max(highest, b.grid_pos.y))
	for x in range(left, right + 1):
		for y in range(lowest, highest + 1):
			var p_b = level.get_block(x, y)
			if p_b == null: continue
			if block_family.find(p_b) < 0: continue
			make_potential_links(p_b, true)
	for b in block_family:
		b.redraw_block()

func wipe_range(x_min: int, x_max: int, y_min: int, y_max: int):
	var blocks_to_refamily := []
	var airs_to_air := []
	for x in range(x_min, x_max):
		for y in range(y_min, y_max):
			var potential_block = level.get_block(x, y)
			if potential_block == null: continue
			var block := (potential_block as Block)
			if block.type == "air":
				airs_to_air.append(block)
				continue
			var idx = block.family.find(block)
			if idx >= 0: # ensure this block's family hasn't already been processed
				block.family.remove(idx)
				blocks_to_refamily.append_array(block.family)
			wipe_block(block)
	restructure_family(blocks_to_refamily)
	for air in airs_to_air:
		if can_drop(air):
			air.state = Block.BlockState.DROPPING
			dropping_families.append(air.family)
func wipe_block(b: Block, pop_first: bool = false):
	level.current_level[b.grid_pos.x][b.grid_pos.y] = null
	b.family = []
	if pop_first:
		b.permanent_dissipation()
	else:
		b.queue_free()
