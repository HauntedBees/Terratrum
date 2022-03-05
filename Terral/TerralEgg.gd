extends RigidBody
class_name TerralEgg

var mat:Material = preload("res://Terral/Shaders/egg.tres")
onready var collider := $CollisionShape

var egg_material:ShaderMaterial
var data:TerralData = null

var held := false setget _set_held
func _set_held(b:bool):
	held = b
	if collider != null: collider.disabled = held

func _ready():
	randomize()
	data = TerralData.new(true, true)
	print("%s will hatch in %s seconds" % [name, data.age])
	egg_material = mat.duplicate()
	$egg/Sphere.material_override = egg_material
	var color_a := Color.white
	var color_b := Color.black
	match data.alignment:
		TerralData.TAlignment.Land:
			color_a = Color.greenyellow
			color_b = Color.darkgreen
		TerralData.TAlignment.Sea:
			color_a = Color.blue
			color_b = Color.darkblue
		TerralData.TAlignment.Underground:
			color_a = Color.orange
			color_b = Color.brown
	egg_material.set_shader_param("albedo_a", color_a)
	egg_material.set_shader_param("albedo_b", color_b)

func _process(delta:float):
	data.age -= delta
	if data.age < 0.0:
		# TODO: hatch the lad
		pass

func _get_egg_info() -> String:
	match data.alignment:
		TerralData.TAlignment.Land: return "A Land Terral Egg"
		TerralData.TAlignment.Sea: return "A Sea Terral Egg"
		TerralData.TAlignment.Underground: return "An Underground Terral Egg"
	return "A Terral Egg."

func _integrate_forces(state:PhysicsDirectBodyState):
	if held: return
	if state.get_contact_count() == 0: return
	if abs(state.linear_velocity.y) < 0.1: return
	var fv:Vector3 = state.linear_velocity
	fv.y = 0
	var d:float = fv.length()
	if d < 0.1: return
	data.age -= 2.5 * d
