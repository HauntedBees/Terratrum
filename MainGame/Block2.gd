extends Node2D
class_name Block2

enum State { NONE, PREFALL, FALLING, POSTFALL, POPPING, POPPED }

onready var anim := $AnimationPlayer
onready var sprite := $AnimatedSprite
const COLOR_XREF = {
	"red": Color(0.9, 0.4, 0.4),
	"green": Color(0.4, 0.9, 0.4),
	"yellow": Color(0.9, 0.9, 0.4),
	"blue": Color(0.4, 0.4, 0.9),
	"hard": Color(0.2, 0.2, 0.2)
}
var mask_offset := 0
var state:int = State.NONE
var type := "red"
var wait_time := 0.0
var fall_remaining := 0.0
var health := 1
var player_popped := false
onready var shader:ShaderMaterial = sprite.material

var recurse_check := false
var pop_wait_check := false
var just_landed := false

func _ready():
	shader = shader.duplicate()
	sprite.material = shader
	if type == "air": return
	sprite.modulate = COLOR_XREF[type]
	_set_shader()

func reset_flags(set_done := true, set_pop_wait_check := true):
	if set_done: recurse_check = false
	if set_pop_wait_check: pop_wait_check = false

func is_falling_or_been_popped() -> bool:
	return state == State.FALLING || state == State.POPPING || state == State.POPPED

func is_unpoppable_type() -> bool:
	return type == "air"

func calculate_mask_offset(above:Block2, right:Block2, below:Block2, left:Block2, aboveleft:Block2, aboveright:Block2, belowleft:Block2, belowright:Block2):
	if type == "air": return
	var final_value := 0
	if _is_valid(above): final_value += 1
	if _is_valid(right): final_value += 2
	if _is_valid(below): final_value += 4
	if _is_valid(left): final_value += 8
	mask_offset = final_value
	if is_inside_tree(): _set_shader()
func _is_valid(b:Block2) -> bool:
	if b == null: return false
	if b.type != type: return false
	return true
	
func _set_shader():
	shader.set_shader_param("mask_offset", Vector2(mask_offset % 4, mask_offset / 4))

func pop():
	$Center/CollisionShape2D.disabled = true
	anim.play("fade")
func wiggle():
	anim.play("wiggle")
func cancel_anim(): anim.stop(true)

# Debug Stuff
signal debug_kill
var mouse := false
func _on_Center_mouse_entered(): mouse = true
func _on_Center_mouse_exited(): mouse = false
func _input(e:InputEvent):
	if mouse && e is InputEventMouseButton && e.button_index == 2 && e.pressed:
		if Input.is_key_pressed(KEY_SHIFT):
			print(type)
		else:
			emit_signal("debug_kill")
