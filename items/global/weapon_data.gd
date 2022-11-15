class_name WeaponData
extends ItemParentData

enum Type{MELEE, RANGED}
enum WeaponClass{GUN, PRIMITIVE, HEAVY, ELEMENTAL, UNARMED, PRECISE, BLUNT, SUPPORT, MEDICAL, ETHEREAL, TOOL, EXPLOSIVE, BLADE, MEDIEVAL}

export (String) var weapon_id = ""
export (Type) var type: = Type.MELEE
export (Array, WeaponClass) var weapon_classes: = [WeaponClass.PRIMITIVE]
export (PackedScene) var scene = null
export (Resource) var stats = null
export (Resource) var upgrades_into


func get_category()->int:
	return Category.WEAPON


func get_weapon_stats_text()->String:
	var current_stats
	
	if type == Type.MELEE:
		current_stats = WeaponService.init_melee_stats(stats, weapon_id, weapon_classes, effects)
	else :
		current_stats = WeaponService.init_ranged_stats(stats, weapon_id, weapon_classes, effects)
	
	return current_stats.get_text(stats)
