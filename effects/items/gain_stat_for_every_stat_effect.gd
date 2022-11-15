class_name GainStatForEveryStatEffect
extends Effect

export (int) var nb_stat_scaled = 0
export (String) var stat_scaled = ""


static func get_id()->String:
	return "gain_stat_for_every_stat"


func apply()->void :
	RunData.effects["stat_links"].push_back([key, value, stat_scaled, nb_stat_scaled])


func unapply()->void :
	RunData.effects["stat_links"].erase([key, value, stat_scaled, nb_stat_scaled])


func get_args()->Array:
	var actual_nb_scaled = 0
	if stat_scaled == "materials":
		actual_nb_scaled = RunData.gold
	else :
		actual_nb_scaled = RunData.get_stat(stat_scaled) + TempStats.get_stat(stat_scaled)
	
	var bonus = floor(value * (actual_nb_scaled / nb_stat_scaled))
	
	return [str(value), tr(key.to_upper()), str(nb_stat_scaled), tr(stat_scaled.to_upper()), str(bonus)]


func serialize()->Dictionary:
	var serialized = .serialize()
	
	serialized.nb_stat_scaled = nb_stat_scaled
	serialized.stat_scaled = stat_scaled
	
	return serialized


func deserialize_and_merge(serialized:Dictionary)->void :
	.deserialize_and_merge(serialized)
	
	nb_stat_scaled = serialized.nb_stat_scaled as int
	stat_scaled = serialized.stat_scaled
