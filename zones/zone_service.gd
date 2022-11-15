extends Node

export (Array, Resource) var zones = null

var current_zone_min_position:Vector2 = Vector2.ZERO
var current_zone_max_position:Vector2 = Vector2.ZERO


func get_zone_data(my_id:int)->Resource:
	return zones[my_id]


func get_wave_data(my_id:int, index:int)->Resource:
	var zone = zones[my_id].duplicate()
	var wave = zone.waves_data[index - 1].duplicate()
	
	return wave


func get_rand_pos(edge:int = Utils.EDGE_MAP_DIST)->Vector2:
	
	var min_x = min((current_zone_min_position.x) + edge, (current_zone_max_position.x / 2) - 1)
	var max_x = max((current_zone_max_position.x) - edge, (current_zone_max_position.x / 2) + 1)
	var min_y = min((current_zone_min_position.y) + edge, (current_zone_max_position.y / 2) - 1)
	var max_y = max((current_zone_max_position.y) - edge, (current_zone_max_position.y / 2) + 1)
	
	return Vector2(rand_range(min_x, max_x), rand_range(min_y, max_y))


func get_rand_pos_in_area(base_pos:Vector2, area:float, edge:int = Utils.EDGE_MAP_DIST)->Vector2:
	
	var pos = Vector2(
		clamp(base_pos.x, edge + area / 2, current_zone_max_position.x - edge - area / 2), 
		clamp(base_pos.y, edge + area / 2, current_zone_max_position.y - edge - area / 2)
	)
	
	return Vector2(rand_range(pos.x - area / 2, pos.x + area / 2), rand_range(pos.y - area / 2, pos.y + area / 2))
