class_name RemoveSpeedEffect
extends Effect

export (int) var max_removed: = 20


static func get_id()->String:
	return "remove_speed"


func apply()->void :
	RunData.effects["remove_speed"][0] += value
	RunData.effects["remove_speed"][1] = max_removed


func unapply()->void :
	RunData.effects["remove_speed"][0] -= value
	RunData.effects["remove_speed"][1] = 0


func get_args()->Array:
	return [str(value), str(max_removed)]


func serialize()->Dictionary:
	var serialized = .serialize()
	
	serialized.max_removed = max_removed
	
	return serialized


func deserialize_and_merge(serialized:Dictionary)->void :
	.deserialize_and_merge(serialized)
	
	max_removed = serialized.max_removed as int
