extends Node

class ChunkInfo:
	var colors := 0
	var air_increase := 0
	var bad_increase := 0
	func _init(c = 0, a = 0, b = 0):
		colors = c
		air_increase = a
		bad_increase = b

class LevelInfo:
	var key := ""
	var name := ""
	var desc := ""
	var difficulty_set := []
	var level_seed := 0
	var max_depth := 0
	var available_characters := []
	var time_limit := 0
	var allow_endless := false
	var level_width := 7
	var play_info = null
	var modifiers := []
	var story_chapter := 0
	var story_level := 0
	func _init(mode: String, level_json: Dictionary, chapter: int = 0):
		match mode:
			"STORY":
				key = "S%s-%s" % [chapter + 1, level_json["level"]]
				story_chapter = chapter + 1
				story_level = level_json["level"]
			_: key = "%s%s" % [mode, level_json["level"]]
		name = tr("LEVEL_%s" % key)
		desc = tr("LEVEL_%s_DESC" % key)
		max_depth = level_json["depth"]
		available_characters = level_json["characters"]
		allow_endless = max_depth == 0
		play_info = PlayerData.get_story_score(chapter + 1, level_json["level"])
		for chunk in level_json["chunks"]:
			difficulty_set.append(ChunkInfo.new(chunk["colors"], chunk["air_rate"], chunk["x_rate"]))
		for gimmick in level_json["gimmicks"]:
			match gimmick["type"]:
				"TIME_TRIAL": time_limit = gimmick["limit"]
				"USE_SEED": level_seed = gimmick["seed"]
				"SET_WIDTH": level_width = gimmick["width"]
				"DEBRIS": modifiers.append(gimmick)
				# DESTROY_CORES
				# TURBO_DRILL
	func is_complete() -> bool: return play_info != null && play_info.won

class ChapterInfo:
	var number: int = 0
	var name: String = ""
	var completion: float = 0.0
	func _init(chapter_json):
		number = chapter_json["chapter"]
		name = tr("CHAPTER_%s" % number)
		var levels_completed := 0
		for level_json in chapter_json["levels"]:
			var level_key = "S%s-%s" % [number, level_json["level"]]
			if PlayerData.beat_level(level_key):
				levels_completed += 1
			else: break
		completion = levels_completed / float(chapter_json["levels"].size())

class FullLevelInfo:
	var level: LevelInfo
	var character: String
	var play_data = null
	var misc_metadata := {}
	# TODO: player config settings
	func _init(l: LevelInfo, c: String, m: Dictionary = {}):
		level = l
		character = c
		misc_metadata = m

var all_levels_json := {}
func _ready():
	var file = File.new()
	file.open("res://json/levels.json", file.READ)
	var content = file.get_as_text()
	all_levels_json = parse_json(content)

func get_available_story_chapters() -> Array:
	var story_chapters: Array = all_levels_json["story"]
	var available_chapters := [ChapterInfo.new(story_chapters[0])]
	for i in range(1, story_chapters.size()):
		if available_chapters[-1].completion == 1.0:
			available_chapters.append(ChapterInfo.new(story_chapters[i]))
	return available_chapters

func get_available_story_levels(chapter: int) -> Array:
	var levels: Array = all_levels_json["story"][chapter].levels
	var available_levels := [LevelInfo.new("STORY", levels[0], chapter)]
	for i in range(1, levels.size()):
			if available_levels[-1].is_complete():
				available_levels.append(LevelInfo.new("STORY", levels[i], chapter))
	return available_levels
	
func get_available_mode_levels(mode: String) -> Array:
	var levels: Array = all_levels_json[mode]
	var available_levels := []
	for l in levels:
		available_levels.append(LevelInfo.new(mode, l))
	return available_levels

func get_specific_story_level(chapter: int, level: int) -> LevelInfo:
	return LevelInfo.new("STORY", all_levels_json["story"][chapter].levels[level], chapter)

func get_specific_level(mode: String, idx: int) -> LevelInfo:
	return LevelInfo.new(mode, all_levels_json[mode][idx])
