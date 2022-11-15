class_name ReplaceEffect
extends Effect

var base_value = 0


static func get_id()->String:
	return "replace"


func apply()->void :
	base_value = RunData.effects[key]
	RunData.effects[key] = value


func unapply()->void :
	RunData.effects[key] = base_value


func serialize()->Dictionary:
	var serialized = .serialize()
	
	serialized.base_value = base_value
	
	return serialized


func deserialize_and_merge(serialized:Dictionary)->void :
	.deserialize_and_merge(serialized)
	
	base_value = serialized.base_value as int
