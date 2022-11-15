class_name TierEffect
extends ReplaceEffect


func get_args()->Array:
	
	var val = "TIER_I"
	
	if value == 1:val = "TIER_II"
	elif value == 2:val = "TIER_III"
	elif value == 3:val = "TIER_IV"
	
	return [tr(val)]
