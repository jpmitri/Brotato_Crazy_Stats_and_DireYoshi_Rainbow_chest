extends Node



signal temp_stat_updated(stat_name, value)

var stats = null
var player = null


func reset()->void :
	stats = init_stats()


func get_signal_name()->String:
	return "temp_stat_updated"


func set_stat(stat_name:String, value:int)->void :
	stats[stat_name] = value
	emit_signal(get_signal_name(), stat_name, value)


func add_stat(stat_name:String, value:int)->void :
	stats[stat_name] += value
	emit_signal(get_signal_name(), stat_name, value)


func remove_stat(stat_name:String, value:int)->void :
	stats[stat_name] -= value
	emit_signal(get_signal_name(), stat_name, value)


func get_stat(stat_name:String)->int:
	if stat_name in stats:
		return stats[stat_name] * RunData.get_stat_gain(stat_name)
	else :
		return 0


func init_stats()->Dictionary:
	return {
		"stat_max_hp":0, 
		"stat_armor":0, 
		"stat_crit_chance":0, 
		"stat_luck":0, 
		"stat_attack_speed":0, 
		"stat_elemental_damage":0, 
		"stat_hp_regeneration":0, 
		"stat_lifesteal":0, 
		"stat_melee_damage":0, 
		"stat_percent_damage":0, 
		"stat_dodge":0, 
		"stat_engineering":0, 
		"stat_range":0, 
		"stat_ranged_damage":0, 
		"stat_speed":0, 
		"stat_harvesting":0, 
		"explosion_size":0, 
		"explosion_damage":0, 
	}
