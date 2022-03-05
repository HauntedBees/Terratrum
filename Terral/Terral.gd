extends KinematicBody #RigidBody

var tmat = preload("res://Terral/Shaders/TerralMaterial.tres")
onready var model:Spatial = $terraltest
onready var m:ShaderMaterial
onready var ms:ShaderMaterial
var data = TerralData.new(false, true)
var held := false

var nav:Navigation
var path := []
var path_idx := 0

func _ready():
	nav = get_tree().current_scene.get_node("Navigation")
	for mo in model.get_children():
		if !(mo is MeshInstance): continue
		m = tmat.duplicate()
		ms = m.next_pass
		(mo as MeshInstance).material_override = m
		_set_textures(m)
		_set_textures(ms)
	redraw()
	if nav == null: return
	path = nav.get_simple_path(global_transform.origin, _get_random_point())
	path_idx = 0

func _physics_process(delta:float):
	if path_idx < path.size():
		var dir:Vector3 = (path[path_idx] - global_transform.origin)
		if dir.length() < 0.5:
			path_idx += 1
		else:
			var d := dir.normalized()
			model.look_at(model.global_transform.origin + d, Vector3.UP)
			d.y = -10.0
			move_and_slide(d * delta * 15.0, Vector3.UP)
	else:
		path = nav.get_simple_path(global_transform.origin, _get_random_point())
		path_idx = 0

func _set_textures(sm:ShaderMaterial):
	sm.set_shader_param("sun_texture", preload("res://Terral/Textures/sun.png"))
	sm.set_shader_param("sea_texture", preload("res://Terral/Textures/sea.png"))
	sm.set_shader_param("stone_texture", preload("res://Terral/Textures/stone.png"))
	sm.set_shader_param("shock_texture", preload("res://Terral/Textures/shock.png"))
	sm.set_shader_param("plant_texture", preload("res://Terral/Textures/plant.png"))

func redraw():
	for sm in [m, ms]:
		sm.set_shader_param("sun_intensity", data.sun / 10.0)
		sm.set_shader_param("sea_intensity", data.sea / 10.0)
		sm.set_shader_param("stone_intensity", data.stone / 10.0)
		sm.set_shader_param("shock_intensity", data.shock / 10.0)
		sm.set_shader_param("plant_intensity", data.plant / 10.0)

func _get_random_point() -> Vector3:
	var dx = randf() * 5.0
	var dz = randf() * 6.0
	return Vector3(-3.5 + dx, 0, -3.2 + dz)
