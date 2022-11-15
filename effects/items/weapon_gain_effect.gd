class_name WeaponGainEffect
extends Effect

export (String) var stat = ""
export (String) var weapon_modified = ""


static func get_id()->String:
	return "weapon_gain"


func get_args()->Array:
	return [str(value), tr(stat.to_upper()), tr(weapon_modified.to_upper())]


func serialize()->Dictionary:
	var serialized = .serialize()
	
	serialized.stat = stat
	serialized.weapon_modified = weapon_modified
	
	return serialized


func deserialize_and_merge(serialized:Dictionary)->void :
	.deserialize_and_merge(serialized)
	
	stat = serialized.stat
	weapon_modified = serialized.weapon_modified
