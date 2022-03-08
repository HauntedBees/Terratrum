extends KinematicBody
signal checking_body(body)

const SPEED := 10.0
var material:ShaderMaterial = preload("res://Terral/Shaders/egg.tres")
onready var c := $character
var current_targets := []
var held_object:RigidBody = null

func _ready():
	var mat:ShaderMaterial = material.duplicate()
	mat.set_shader_param("albedo_a", Color("AA5E00"))
	mat.set_shader_param("mask_texture", null)
	mat.set_shader_param("use_specular", false)
	(mat.next_pass as SpatialMaterial).params_grow_amount = 0.1
	for mesh in c.get_children():
		if mesh is Area: continue
		(mesh as MeshInstance).material_override = mat

func _physics_process(delta):
	var velocity := Vector3(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		0,
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	velocity = velocity.normalized()
	if velocity != Vector3.ZERO: c.look_at(c.global_transform.origin + -10.0 * velocity, Vector3.UP)
	velocity = SPEED * delta * velocity
	var is_moving:bool = velocity.length() > 0.1
	velocity.y -= 10.0 * delta
	move_and_collide(velocity, false)
	
	if held_object:
		held_object.global_transform.origin = _get_in_front(true)
		held_object.rotation.y = c.rotation.y
	
	if GASInput.is_action_just_pressed("ui_accept"):
		if held_object == null:
			if current_targets.size() == 0: return
			var temp:RigidBody = current_targets[0]
			_on_FrontChecker_exited(temp)
			held_object = temp
			held_object.held = true
		else:
			held_object.global_transform.origin = _get_in_front(false)
			if is_moving:
				held_object.apply_impulse(c.global_transform.origin, (_get_direction() + Vector3(0, 1.25, 0)) * 40.0)
			held_object.held = false
			var temp := held_object
			held_object = null
			_on_FrontChecker_entered(temp)

func _get_in_front(is_elevated:bool) -> Vector3:
	var init_pos:Vector3 = c.global_transform.origin
	var forward_vector := _get_direction()
	var new_position := init_pos + forward_vector * 0.7
	if is_elevated: new_position.y += 0.2
	return new_position
func _get_direction() -> Vector3:
	var v:Vector3 = c.global_transform.basis.z
	v.y = 0.0
	return v.normalized()

func _on_FrontChecker_entered(body:Node):
	if !(body is RigidBody): return
	if body == held_object: return
	if !current_targets.has(body):
		current_targets.append(body)
	emit_signal("checking_body", current_targets[0])

func _on_FrontChecker_exited(body:Node):
	if !(body is RigidBody): return
	if body == held_object: return
	var idx := current_targets.find(body)
	if idx < 0: return
	current_targets.remove(idx)
	if current_targets.size() > 0:
		emit_signal("checking_body", current_targets[0])
	else:
		emit_signal("checking_body", null)
