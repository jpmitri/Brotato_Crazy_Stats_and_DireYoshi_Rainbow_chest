class_name WeaponStackEffect
extends NullEffect

export (String) var weapon_stacked_name
export (String) var weapon_stacked_id
export (String) var stat_displayed_name = "stat_damage"
export (String) var stat_name = "damage"


static func get_id()->String:
	return "weapon_stack"


func get_args()->Array:
	return [str(value), tr(stat_displayed_name.to_upper()), tr(weapon_stacked_name.to_upper())]


func serialize()->Dictionary:
	var serialized = .serialize()
	
	serialized.weapon_stacked_name = weapon_stacked_name
	serialized.weapon_stacked_id = weapon_stacked_id
	serialized.stat_displayed_name = stat_displayed_name
	serialized.stat_name = stat_name
	
	return serialized


func deserialize_and_merge(serialized:Dictionary)->void :
	.deserialize_and_merge(serialized)
	
	weapon_stacked_name = serialized.weapon_stacked_name
	weapon_stacked_id = serialized.weapon_stacked_id
	stat_displayed_name = serialized.stat_displayed_name
	stat_name = serialized.stat_name
