tool
extends EditorScenePostImport

var double_shader:ShaderMaterial = preload("res://scenes/test/DoubleShader.tres")

func post_import(scene):
	toonify(scene)
	return scene

func toonify(node):
	if node == null: return
	if node is MeshInstance:
		var nm := node as MeshInstance
		var material:Material = nm.get_active_material(0)
		var new_shader:ShaderMaterial = double_shader.duplicate()
		print(material)
		if material is SpatialMaterial:
			var sm := material as SpatialMaterial
			new_shader.set_shader_param("albedo", sm.albedo_color)
			new_shader.set_shader_param("albedo_texture", sm.albedo_texture)
		else: # this guy might not work
			print("it's got a shader material! uhhhhhh sure!")
			new_shader.next_pass.next_pass = material
		nm.material_override = new_shader
	for child in node.get_children():
		toonify(child)
