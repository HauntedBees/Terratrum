extends Node

class NewRecordInfo:
	var score := false
	var time := false
	var depth := false
	func _init(s: bool = false, t: bool = false, d: bool = false):
		score = s
		time = t
		depth = d
class BestScore:
	var score := 0
	var time := 0
	var depth := 0
	var won := false
	func _init(s: int, t: int, d: int, w: bool):
		score = s
		time = t
		depth = d
		won = w

var scores := {}
func _ready(): load_from_disk()

func load_from_disk():
	var save_file := File.new()
	if !save_file.file_exists("user://scores.bee"): return
	save_file.open("user://scores.bee", File.READ)
	scores = parse_json(save_file.get_line())
func save_to_disk():
	var save_file := File.new()
	save_file.open("user://scores.bee", File.WRITE)
	save_file.store_line(to_json(scores))
	save_file.close()

#func submit_story_score(chapter: int, level: int, score: int, time: int, depth: int) -> NewRecordInfo:
#	return submit_standard_score(("S%s-%s" % [chapter, level]), score, time, depth)
func get_story_score(chapter: int, level: int) -> BestScore: return get_standard_score("S%s-%s" % [chapter, level])

func beat_level(level_key: String) -> bool: return scores.has(level_key) && scores[level_key].won

func submit_standard_score(key: String, score: int, time: int, depth: int, won: bool) -> NewRecordInfo:
	var standard := get_standard_score(key)
	if standard == null:
		save_standard_score(key, BestScore.new(score, time, depth, won))
		save_to_disk()
		return NewRecordInfo.new(true, true, true)
	else:
		var new_score := NewRecordInfo.new()
		if score > standard.score:
			new_score.score = true
			standard.score = score
		if time < standard.time:
			new_score.time = true
			standard.time = time
		if depth > standard.depth:
			new_score.depth = true
			standard.depth = depth
		save_standard_score(key, standard)
		save_to_disk()
		return new_score
func get_standard_score(key: String) -> BestScore:
	var score_dict = scores.get(key)
	return null if score_dict == null else BestScore.new(score_dict.score, score_dict.time, score_dict.depth, score_dict.won)
func save_standard_score(key: String, standard: BestScore):
	scores[key] = {
		score = standard.score,
		time = standard.time,
		depth = standard.depth,
		won = standard.won
	}
