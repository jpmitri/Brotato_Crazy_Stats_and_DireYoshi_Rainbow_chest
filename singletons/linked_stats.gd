extends TempStats

signal linked_stat_updated(stat_name, value)

var update_on_gold_chance: = false


func reset()->void :
	.reset()
	
	update_on_gold_chance = false
	
	for linked_stat in RunData.effects["stat_links"]:
		var stat_to_tweak = linked_stat[0]
		var stat_scaled = ""
		
		if linked_stat[2] == "materials":
			stat_scaled = RunData.gold
			update_on_gold_chance = true
		else :
			stat_scaled = RunData.get_stat(linked_stat[2]) + TempStats.get_stat(linked_stat[2])
		
		var amount_to_add = linked_stat[1] * (stat_scaled / linked_stat[3])
		
		add_stat(stat_to_tweak, amount_to_add)


func get_signal_name()->String:
	return "linked_stat_updated"
