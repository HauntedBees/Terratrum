extends Spatial

onready var info_container := $HUD/TextContainer
func _on_CharacterModel_checking_body(body:Node):
	if body == null:
		info_container.visible = false
		return
	info_container.visible = true
	if body is TerralEgg:
		info_container.text = body._get_egg_info()
