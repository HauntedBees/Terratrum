extends HUDValue

var time := 0.0
func _process(delta):
	time += delta
	var time_int := int(time)
	_set_val("%02d:%02d" % [time_int / 60, time_int % 60])
