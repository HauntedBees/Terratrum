extends TextureProgress

onready var player: Player = get_node("/root/Geemu/Player")
onready var amount_text: Label = $Amount
onready var amount_font: DynamicFont = amount_text.get("custom_fonts/font")
onready var air_font = $Label.get("custom_fonts/font")
onready var gradient := Gradient.new()

func _ready(): gradient.set_colors([Color(0, 1, 0), Color(1, 0, 0)])

# TODO: the top and bottom get fucky due to the radiuses - look into the nine patch stretch probably
func _process(_delta):
	var health := player.air
	amount_text.text = "%s%%" % round(health)
	var color := gradient.interpolate((100 - health) / 100)
	tint_progress = color
	value = health
	var darker_color := Color(color.r / 5, color.g / 5, color.b / 5)
	amount_font.outline_color = darker_color
	air_font.outline_color = darker_color
