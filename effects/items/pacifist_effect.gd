class_name PacifistEffect
extends Effect


static func get_id()->String:
	return "pacifist"


func get_args()->Array:
	return [str(value / 100.0)]
