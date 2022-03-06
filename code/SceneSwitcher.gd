extends Node2D
onready var container: VBoxContainer = $Loader/Container
onready var percent_text: Label = $Loader/Container/PercentText
const BLOCK_MSECS := 100
const DEBUG := true

var queue = null
var current_scene = null
var next_scene_data = null
var loaded := 0.0

func _ready():
	container.hide()
	var root := get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)
func get_carried_scene_data():
	if DEBUG && next_scene_data == null: return Levels.FullLevelInfo.new(Levels.get_specific_level("debug", 0), "Mole")
	return next_scene_data
	#var response = next_scene_data
	#next_scene_data = null
	#return response
func go_to_cutscene(details):
	next_scene_data = details
	load_scene("res://Cutscene/Cutscene.tscn")
func go_to_game(details): # Levels.FullLevelInfo; godot really doesn't like me saying that, though
	next_scene_data = details
	load_scene("res://scenes/game/Main.tscn")
func go_to_score(details):
	next_scene_data = details
	load_scene("res://scenes/game/LevelComplete.tscn")
func go_to_level_select(misc_data: Dictionary):
	next_scene_data = misc_data
	load_scene("res://scenes/menu/MainMenu.tscn")

func load_scene(path: String):
	loaded = 0.0
	queue = ResourceLoader.load_interactive(path)
	container.show()
func _process(_delta):
	if queue == null: return
	var time = OS.get_ticks_msec()
	while OS.get_ticks_msec() < (time + BLOCK_MSECS):
		var response := (queue as ResourceInteractiveLoader).poll()
		if response == ERR_FILE_EOF:
			var scene = queue.get_resource()
			queue = null
			set_new_scene(scene)
			break
		elif response == OK:
			loaded = float(queue.get_stage()) / float(queue.get_stage_count())
			percent_text.text = "%s%%" % round(loaded * 100)
		else:
			print("OOPSIE")
			break
func set_new_scene(scene_resource):
	current_scene.queue_free()
	current_scene = scene_resource.instance()
	get_node("/root").add_child(current_scene)
	container.hide()
