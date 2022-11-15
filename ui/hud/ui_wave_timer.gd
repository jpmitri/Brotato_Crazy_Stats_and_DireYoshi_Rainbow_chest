extends Label

var wave_timer:Timer
var is_run_lost = false


func _process(_delta:float)->void :
	if wave_timer != null and is_instance_valid(wave_timer) and not is_run_lost:
		text = str(ceil(wave_timer.time_left))
