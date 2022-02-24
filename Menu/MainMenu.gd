extends Control
onready var info_label:Label = $OuterContainer/TextBGContainer/TextContainer/InfoLabel
onready var contents_container:Container = $OuterContainer/Contents
onready var button_container:Container = $OuterContainer/Contents/Buttons
onready var story_container:Container = $OuterContainer/Contents/StorySelect
onready var char_sel_container:Container = $OuterContainer/CharacterSelect
onready var t:Tween = $Tween
onready var hide_during_char_select := [$OuterContainer/TextBGDivider, $OuterContainer/TextBGContainer]
var current_level = null
var current_metadata = null

func _on_StoryMode_hover(): info_label.text = "Play through the game's story."
func _on_StandardMode_hover(): info_label.text = "Play some standard drilling modes."
func _on_TimeAttack_hover(): info_label.text = "Race against time to beat your best scores!"
func _on_SpecialDigs_hover(): info_label.text = "Engage in unique challenges with special conditions."
func _on_TerraGarden_hover(): info_label.text = "Tend to your terrals in the Terra Garden."
func _on_Options_hover(): info_label.text = "Options Menus! Every game needs one!"
func _on_QuickPlay_hover(): info_label.text = "Less menus, more gaming! Jump right into a game."

func _on_StoryMode_pressed():
	_move_buttons(button_container, story_container)
func _on_StandardMode_pressed():
	pass#_move_buttons()
func _on_TimeAttack_pressed():
	pass#_move_buttons()
func _on_SpecialDigs_pressed():
	pass#_move_buttons()
func _on_TerraGarden_pressed():
	pass#_move_buttons()
func _on_Options_pressed():
	pass#_move_buttons()
func _on_QuickPlay_pressed():
	pass#_move_buttons()

# TODO: [Shaggy voice] like, fuck this
func _move_buttons(to_hide:Control, to_show:Control):
	to_hide.visible = true
	to_hide.modulate.a = 1
	to_show.visible = true
	to_hide.modulate.a = 0
	#t.interpolate_property(to_hide, "modulate:a", 1, 0, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
	t.interpolate_property(to_show, "modulate:a", 0, 1, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
	t.start()
	to_hide.visible = false

func _on_StorySelect_back_to_main(): _move_buttons(story_container, button_container)


func _on_StorySelect_level_selected(level_info):
	current_metadata = get_metadata("STORY", level_info)
	_move_to_char_select(level_info)

func _move_to_char_select(level_info):
	current_level = level_info
	char_sel_container.set_characters(level_info.available_characters)
	_move_buttons(contents_container, char_sel_container)
	for h in hide_during_char_select:
		h.visible = false

func _on_back_from_char_select():
	current_level = null
	_move_buttons(char_sel_container, contents_container)
	for h in hide_during_char_select:
		h.visible = true

func _on_character_selected(selected_char:String):
	var level_info := Levels.FullLevelInfo.new(current_level, selected_char, current_metadata)
	if level_info.misc_metadata.has("cutscene"):
		SceneSwitcher.go_to_cutscene(level_info)
	else:
		SceneSwitcher.go_to_game(level_info)


func get_metadata(mode:String, level_info):
	match mode:
		"STORY":
			return {
				mode = "STORY",
				chapter = level_info.story_chapter, # TODO: does this need to be metadata?
				level = level_info.story_level,		# what about this
				key = level_info.key,				# or this
				cutscene = true
			}
	return {}
