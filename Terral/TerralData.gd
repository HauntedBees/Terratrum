extends Node
class_name TerralData

enum TAlignment { Land, Sea, Underground }
enum TQuirk { None, Silly, Sleepy, Confused, Hungry, Fast }
enum TMood { Calm, Happy, Sad, Mad, Hungry, Hornt }

var base_color:Color
var secondary_color:Color
var shininess := 0.0
var color_pattern := ""
var second_color_pattern := ""
var hat := ""

var animals := {}
var learned_behaviors := []
var mood:int = TMood.Calm

var alignment:int = TAlignment.Land
var personality_quirk:int = TQuirk.None
var openness := 0
var conscientiousness := 0
var extraversion := 0
var agreeableness := 0	
var neuroticism := 0

var generation := 1
var age := 0.0
var has_mated := false
var is_preserved := false

var sun := 0
var sea := 0
var stone := 0
var shock := 0
var plant := 0
var sun_progress := 0
var sea_progress := 0
var stone_progress := 0
var shock_progress := 0
var plant_progress := 0

func _init(is_egg:bool, random_vals := false):
	randomize()
	if is_egg: age = 60.0 + randf() * 60.0
	if random_vals:
		alignment = randi() % 3
		personality_quirk = randi() % 6
		sun = randi() % 20
		sea = randi() % 20
		stone = randi() % 20
		shock = randi() % 20
		plant = randi() % 20
		sun_progress = randi() % 100
		sea_progress = randi() % 100
		stone_progress = randi() % 100
		shock_progress = randi() % 100
		plant_progress = randi() % 100

