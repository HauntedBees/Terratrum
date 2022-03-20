extends TextureProgress

export(float, 0, 100, 1) var amount := 100.0 setget _set_amount
onready var lm:LevelManager2 = owner.get_node("HUD/MarginContainer/Game/GameSpace/Viewport/Game/LevelManager")

func _set_amount(a:float):
	amount = a
	if is_inside_tree():
		value = amount
		$Key.text = "Air\n%s%%" % floor(amount)

func _process(_delta): _set_amount(lm.air_amount)
