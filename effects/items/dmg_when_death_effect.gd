class_name DealDamageWhenDeathEffect
extends Effect

export (int) var chance: = 3
export (String) var stat: = ""


static func get_id()->String:
	return "deal_damage_when_death"


func apply()->void :
	RunData.effects["dmg_when_death_from_luck"][0] += chance
	RunData.effects["dmg_when_death_from_luck"][1] += value


func unapply()->void :
	RunData.effects["dmg_when_death_from_luck"][0] -= chance
	RunData.effects["dmg_when_death_from_luck"][1] -= value


func get_args()->Array:
	
	var dmg = RunData.get_dmg((value / 100.0) * Utils.get_stat(stat))
	var scaling_text = Utils.get_scaling_stat_text(stat, value / 100.0)
	
	return [str(chance), str(dmg), scaling_text]


func serialize()->Dictionary:
	var serialized = .serialize()
	
	serialized.chance = chance
	serialized.stat = stat
	
	return serialized


func deserialize_and_merge(serialized:Dictionary)->void :
	.deserialize_and_merge(serialized)
	
	chance = serialized.chance as int
	stat = serialized.stat
