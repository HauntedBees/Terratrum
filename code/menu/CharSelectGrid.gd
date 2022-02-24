extends Node2D
const char_sel = preload("res://scenes/menu/CharSel.tscn")
const CX := 200.0 # 360 is center of screen
const CY := 540.0
const SIZE := 128.0
const HALF := SIZE / 2.0
const DY := 46.5
const CHAR_POSITIONS := [
	[Vector2(CX, CY)],
	[Vector2(CX - HALF + 1, CY), Vector2(CX + HALF - 1, CY)],
	[Vector2(CX - HALF + 1, CY - DY + 1), Vector2(CX + HALF - 1, CY - DY + 1), Vector2(CX, CY + DY - 1)],
	[Vector2(CX - HALF + 1, CY), Vector2(CX + HALF - 1, CY), Vector2(CX, CY + 2 * DY), Vector2(CX, CY - 2 * DY)],
	[Vector2(CX - HALF + 1, CY - 2 * DY), Vector2(CX + HALF - 1, CY - 2 * DY), Vector2(CX, CY), Vector2(CX - HALF + 1, CY + 2 * DY), Vector2(CX + HALF - 1, CY + 2 * DY)],
	[Vector2(CX - HALF + 1, CY), Vector2(CX + HALF - 1, CY), Vector2(CX, CY - 2 * DY), Vector2(CX, CY + 2 * DY), Vector2(CX - 2 * HALF + 2, CY - 2 * DY), Vector2(CX - 2 * HALF + 2, CY + 2 * DY)], 
	[Vector2(CX, CY), Vector2(CX + 2 * HALF - 2, CY), Vector2(CX + HALF - 1, CY - 2 * DY), Vector2(CX + HALF - 1, CY + 2 * DY), Vector2(CX - HALF + 1, CY - 2 * DY), Vector2(CX - HALF + 1, CY + 2 * DY), Vector2(CX - 2 * HALF + 1, CY)],
	[Vector2(CX - HALF + 1, CY), Vector2(CX + HALF - 1, CY), Vector2(CX, CY - 2 * DY), Vector2(CX - 2 * HALF + 2, CY - 2 * DY), Vector2(CX + 2 * HALF - 2, CY - 2 * DY), Vector2(CX, CY + 2 * DY),  Vector2(CX - 2 * HALF + 2, CY + 2 * DY), Vector2(CX + 2 * HALF - 2, CY + 2 * DY)],
	[Vector2(CX, CY), Vector2(CX + 2 * HALF - 2, CY), Vector2(CX + HALF - 1, CY - 2 * DY), Vector2(CX + HALF - 1, CY + 2 * DY), Vector2(CX - HALF + 1, CY - 2 * DY), Vector2(CX - HALF + 1, CY + 2 * DY), Vector2(CX - 2 * HALF + 1, CY), Vector2(CX, CY - 4 * DY), Vector2(CX, CY + 4 * DY)],
	[Vector2(CX - HALF + 1, CY), Vector2(CX + HALF - 1, CY), Vector2(CX, CY - 2 * DY), Vector2(CX - 2 * HALF + 2, CY - 2 * DY), Vector2(CX + 2 * HALF - 2, CY - 2 * DY), Vector2(CX, CY + 2 * DY), Vector2(CX - 2 * HALF + 2, CY + 2 * DY), Vector2(CX + 2 * HALF - 2, CY + 2 * DY), Vector2(CX - HALF + 1, CY - 4 * DY), Vector2(CX + HALF - 1, CY + 4 * DY)]
]
onready var selected_icon := $Selected
var available_characters := ["Mole", "Prairie", "Jerboa", "Tortoise", "Groundhog", "Robot", "Pangolin", "Spider", "Owl", "Fish"]
var selected_char := "Mole"
var charsels := []

func _ready(): set_characters(available_characters)
func set_characters(characters: Array):
	available_characters = characters
	for c in charsels: c.queue_free()
	charsels = []
	var positions: Array = CHAR_POSITIONS[available_characters.size() - 1]
	for i in available_characters.size():
		var charsel: CharSel = char_sel.instance()
		charsel.position = positions[i]
		charsel.character = available_characters[i]
		charsel.connect("char_change", self, "on_char_change", [charsel])
		charsels.append(charsel)
		add_child(charsel)
	on_char_change(charsels[0])

func on_char_change(c: CharSel):
	selected_char = c.character
	selected_icon.position = c.position
