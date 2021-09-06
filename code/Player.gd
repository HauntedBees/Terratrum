extends KinematicBody2D
class_name Player

const angel = preload("res://scenes/characters/Angel.tscn")

class CharacterStat:
	var air_mult: float
	var speed_mult: float
	var drop_mult: float
	var air_get_mult: float
	var air_damage_mult: float
	func _init(air: float = 1.0, speed: float = 1.0, drop: float = 1.0, air_damage: float = 1.0, air_get: float = 1.0):
		air_mult = air
		speed_mult = speed
		drop_mult = drop
		air_damage_mult = air_damage
		air_get_mult = air_get

var character_multipliers := {
	"Prairie": CharacterStat.new(0.75, 1.5, 1.25, 1.5, 1.25),
	"Tortoise": CharacterStat.new(0.25, 0.5, 1.0, 0.75, 1.25),
	"Jerboa": CharacterStat.new(1.0, 1.25, 1.0),
	"Robot": CharacterStat.new(0.005, 1.0, 1.75, 0.25, -1.5)
}

signal drill(x, y)
signal update_ui_value(key, value)

class PlayInfo:
	var score := 0
	var blocks_broken := 0
	var hard_broken := 0
	var air_collected := 0
	var play_time := 0.0
	var max_depth := 0
	var gamed_over := false
	func get_average_speed() -> float:
		return round(100 * (float(max_depth) / float(play_time))) / 100

onready var game = get_node("/root/Geemu")
onready var tween = $Tween
var sprite: AnimatedSprite

var play_info := PlayInfo.new()
var is_timed := false
var fresh_touch := false

var character := "Mole"
var lives := 3
var air := 100.0
var direction := Vector2(0, 1)
var immune := false
var animating := false
var is_moving := false
var block_scale := 1.0
var block_size := Consts.BLOCK_SIZE

var velocity = Vector2()
var dead := false
var input_frozen := false
var trying_climb := 0.0
var fall_dist := 0.0
var stats := CharacterStat.new()

func _ready():
	var level_info: Levels.FullLevelInfo = SceneSwitcher.get_carried_scene_data()
	if level_info.level.time_limit > 0.0:
		is_timed = true
		play_info.play_time = level_info.level.time_limit
	character = level_info.character
	if character_multipliers.has(character):
		stats = character_multipliers[character]
	var sprite_asset = load("res://scenes/characters/%s.tscn" % character)
	sprite = sprite_asset.instance()
	add_child(sprite)

func breathe() -> int:
	air = min(air + stats.air_get_mult * 20, 100)
	play_info.air_collected += 1
	var new_score := play_info.air_collected * Consts.AIR_MULTIPLIER
	add_score(new_score)
	return new_score

func unbreathe() -> int:
	var air_lost := int(stats.air_damage_mult * 20)
	air = max(air - air_lost, 0)
	return air_lost

func do_a_died():
	dead = true
	animating = true
	input_frozen = true
	sprite.animation = "crush"
func undie_ha_ha_like_underwear_but_actually_as_in_un_die():
	var a = angel.instance()
	a.character = sprite.duplicate()
	a.position = game.player.position
	game.add_child(a)
	yield(get_tree().create_timer(Consts.ACTION_TIME), "timeout")
	sprite.animation = "revive"
	sprite.playing = true
	immune = true
	air = 100.0
	yield(get_tree().create_timer(Consts.ACTION_TIME), "timeout")
	immune = false
	animating = false
	input_frozen = false
	dead = false

func add_block_score(amount: int, is_hard: bool):
	add_score(amount * Consts.CLEAR_MULTIPLIER)
	if is_hard:
		play_info.hard_broken += amount
	else:
		play_info.blocks_broken += amount

func add_chain_score(amount: int, is_hard: bool):
	add_score(amount * Consts.CHAIN_MULTIPLIER)
	if is_hard:
		play_info.hard_broken += amount
	else:
		play_info.blocks_broken += amount

func check_depth(new_depth: int):
	emit_signal("update_ui_value", "depth", new_depth)
	if new_depth > play_info.max_depth:
		add_score(new_depth - play_info.max_depth)
		play_info.max_depth = new_depth

func add_score(amount: int):
	play_info.score += amount
	emit_signal("update_ui_value", "score", play_info.score)

func _input(_event):
	if Input.is_key_pressed(KEY_Q): undie_ha_ha_like_underwear_but_actually_as_in_un_die()
	if input_frozen: return
	if Input.is_key_pressed(KEY_DOWN):
		direction = Vector2(0, 1)
	elif Input.is_key_pressed(KEY_LEFT):
		direction = Vector2(-1, 0)
	elif Input.is_key_pressed(KEY_RIGHT):
		direction = Vector2(1, 0)
	elif Input.is_key_pressed(KEY_UP):
		direction = Vector2(0, -1)
	if !is_on_floor() && character != "Owl": return
	if Input.is_key_pressed(KEY_A):
		do_drill()

func _on_VPad_touch_press(dir: Vector2, drilling: bool):
	if input_frozen: return
	fresh_touch = true
	direction = dir
	if !is_on_floor() && character != "Owl": return
	if drilling: do_drill()

func _on_VBtn_btn_press(_key):
	if input_frozen: return
	if !is_on_floor(): return
	do_drill()

func do_drill():
	emit_signal("drill", direction)
	if direction.x < 0: sprite.play("drill_left")
	elif direction.x > 0: sprite.play("drill_right")
	elif direction.y > 0: sprite.play("drill_down")
	elif direction.y < 0: sprite.play("drill_up")
	else: return
	animating = true
	yield(sprite, "animation_finished")
	animating = false
	sprite.animation = "stand"
	sprite.playing = false

func _process(delta):
	play_info.play_time += -delta if is_timed else delta
	emit_signal("update_ui_value", "time", play_info.play_time)
	air = max(air - stats.air_mult * delta, 0)
	if air <= 20:
		$PlayerInfo.set_and_show("need_air")
	else:
		$PlayerInfo.hide()
	if animating: return
	if fall_dist > 0.0:
		if (fall_dist / block_size) >= 2.5:
			sprite.animation = "fall"
			sprite.playing = true
		else:
			sprite.animation = "stand"
			sprite.playing = false
			set_frame_from_dir()
	elif is_moving:
		sprite.animation = "walk_left" if direction.x < 0 else "walk_right"
		sprite.playing = true
	else:
		sprite.animation = "stand"
		sprite.playing = false
		set_frame_from_dir()

func set_frame_from_dir():
	if direction.x < 0:
		sprite.frame = 0
	elif direction.x > 0:
		sprite.frame = 2
	elif direction.y < 0:
		sprite.frame = 3
	else:
		sprite.frame = 1

func get_grid_position() -> Vector2: return game.lb.get_player_pos(self)

func climb_wall(dir: int):
	var cur_pos := get_grid_position()
	var dy := 0

	if can_climb_to(cur_pos.x, cur_pos.y, dir): 
		dy = 1
	if dy == 0 && character == "Jerboa" && can_climb_to(cur_pos.x, cur_pos.y - 1, dir) && get_block(cur_pos.x, cur_pos.y - 1) == null:
		dy = 2
	if dy == 0: return
	
	input_frozen = true
	immune = true
	var up_pos = Vector2(position.x, position.y - dy * block_size)
	tween.interpolate_property(self, "position", position, up_pos, Consts.CLIMB_STEP_TIME / stats.speed_mult, Tween.TRANS_LINEAR)
	tween.start()
	yield(tween, "tween_completed")
	animating = true
	sprite.animation = "walk_left" if direction.x < 0 else "walk_right"
	sprite.playing = true
	var forward_pos = Vector2(position.x + dir * block_size, position.y)
	tween.interpolate_property(self, "position", position, forward_pos, Consts.CLIMB_STEP_TIME / stats.speed_mult, Tween.TRANS_LINEAR)
	tween.start()
	yield(tween, "tween_completed")
	input_frozen = false
	immune = false
	animating = false

func can_climb_to(x: float, y: float, dir: int) -> bool:
	if get_block(x, y - 1) != null: return false # can't climb when a block is above you
	var adj_pos = get_block(x + dir, y)
	if adj_pos == null: return false # can't climb edge of map!
	if adj_pos.state != Block.BlockState.INERT && adj_pos.state != Block.BlockState.WIGGLING: return false # can't climb droppies!
	var dest_pos = game.lb.get_block(x + dir, y - 1)
	if !(dest_pos == null || dest_pos.type == "air"): return false
	return true
func get_block(x: float, y: float): return game.lb.get_block(x, y)

func get_player_move_dir() -> float:
	if fresh_touch:
		fresh_touch = false
		return direction.x
	else:
		return Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
func get_player_vert_dir() -> float:
	if fresh_touch:
		fresh_touch = false
		return direction.y
	else:
		return Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

func _physics_process(delta):
	if input_frozen:
		is_moving = false
		return
	
	if character == "Owl":
		velocity.x = delta * block_scale * stats.speed_mult * Consts.WALK_SPEED * get_player_move_dir()
		velocity.y = delta * block_scale * stats.speed_mult * Consts.WALK_SPEED * get_player_vert_dir()
		trying_climb = 0.33 if (velocity.y < 0 || velocity.x != 0) else (trying_climb - delta)
		if trying_climb <= 0.0:
			velocity.y = block_scale * stats.drop_mult * Consts.DROP_SPEED
		velocity = move_and_slide(velocity, Vector2.UP)
		return
	
	var floored := is_on_floor()
	
	if floored:
		fall_dist = 0.0
		velocity.x = delta * block_scale * stats.speed_mult * Consts.WALK_SPEED * get_player_move_dir()
	else:
		fall_dist += block_scale * stats.drop_mult * Consts.DROP_SPEED * delta 
		velocity.x = 0
		is_moving = false
	
	var dir := 1 if velocity.x > 0 else -1

	if velocity.y < 0:
		velocity.y += block_scale * stats.drop_mult * Consts.DROP_SPEED * delta * 3
	else:
		velocity.y = block_scale * stats.drop_mult * Consts.DROP_SPEED
		if Input.is_key_pressed(KEY_X): velocity.y *= 10 # debug

	var was_moving: bool = velocity.x != 0
	velocity = move_and_slide(velocity, Vector2.UP)
	is_moving = velocity.x != 0
	if was_moving && !is_moving && floored:
		trying_climb += delta
		if trying_climb >= Consts.CLIMB_DELAY:
			climb_wall(dir)
	else:
		trying_climb = 0.0
