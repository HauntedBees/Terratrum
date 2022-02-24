extends TextureButton
const SIZE := 128
var character := "Mole"
func _ready(): _refresh_texture()

func _set_character(t):
	character = t
	if is_inside_tree(): _refresh_texture()

func _refresh_texture():
	var t:AtlasTexture = texture_normal.duplicate()
	match character:
		"Mole": t.region = Rect2(0, 0, SIZE, SIZE)
		"Prairie": t.region = Rect2(SIZE, 0, SIZE, SIZE)
		"Jerboa": t.region = Rect2(2 * SIZE, 0, SIZE, SIZE)
		"Tortoise": t.region = Rect2(3 * SIZE, 0, SIZE, SIZE)
		"Wombat": t.region = Rect2(0, SIZE, SIZE, SIZE)
		"Pangolin": t.region = Rect2(SIZE, SIZE, SIZE, SIZE)
		"Owl": t.region = Rect2(2 * SIZE, SIZE, SIZE, SIZE)
		"Robot": t.region = Rect2(3 * SIZE, SIZE, SIZE, SIZE)
		"Spider": t.region = Rect2(4 * SIZE, SIZE, SIZE, SIZE)
		"Fish": t.region = Rect2(4 * SIZE, 0, SIZE, SIZE)
	texture_normal = t

# TODO: make this prettier
func _on_CharSelBtn_toggled(button_pressed:bool):
	modulate = Color.yellow if button_pressed else Color.white
