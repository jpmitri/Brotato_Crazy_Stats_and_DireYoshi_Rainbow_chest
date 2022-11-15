class_name HpCapEffect
extends Effect

export (bool) var set_cap_to_current_max_hp = false


static func get_id()->String:
	return "hp_cap"


func apply()->void :
	if set_cap_to_current_max_hp:
		RunData.effects["hp_cap"] = Utils.get_stat("stat_max_hp")
	else :
		RunData.effects["hp_cap"] = value


func unapply()->void :
	RunData.effects["hp_cap"] = 999999


func get_args()->Array:
	return [str(RunData.effects["hp_cap"] if RunData.effects["hp_cap"] < 9999 else Utils.get_stat("stat_max_hp") as int)]


func serialize()->Dictionary:
	var serialized = .serialize()
	
	serialized.set_cap_to_current_max_hp = set_cap_to_current_max_hp
	
	return serialized


func deserialize_and_merge(serialized:Dictionary)->void :
	.deserialize_and_merge(serialized)
	
	set_cap_to_current_max_hp = serialized.set_cap_to_current_max_hp
