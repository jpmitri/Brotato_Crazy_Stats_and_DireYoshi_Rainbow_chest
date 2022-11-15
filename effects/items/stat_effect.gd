class_name StatEffect
extends Effect

export (String) var effect_key = ""


static func get_id()->String:
	return "stat"


func apply()->void :
	RunData.effects[effect_key].push_back([key, value])


func unapply()->void :
	RunData.effects[effect_key].erase([key, value])


func get_args()->Array:
	return [str(value), tr(key.to_upper())]


func serialize()->Dictionary:
	var serialized = .serialize()
	
	serialized.effect_key = effect_key
	
	return serialized


func deserialize_and_merge(serialized:Dictionary)->void :
	.deserialize_and_merge(serialized)
	
	effect_key = serialized.effect_key
