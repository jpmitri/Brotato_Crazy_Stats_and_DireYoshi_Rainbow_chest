class_name WaveManager
extends Node2D

signal group_spawn_timing_reached(group_data, is_elite_wave)

enum {DATA, REPEATING, REPEATING_INTERVAL, REDUCE_REPEATING_INTERVAL, MIN_REPEATING_INTERVAL, NEXT_REPEAT}

export (Array, Resource) var groups_data_in_all_waves: = []
export (Array, Resource) var horde_groups: = []
export (Resource) var elite_group

var wave_timer:Timer
var current_wave_data:Resource

var _groups_to_remove: = []
var _groups_to_repeat: = []
var _repeat_groups_to_remove: = []
var _last_time_checked: = 0

var _is_elite_wave: = false
var _elite_spawn_data: = []


func init(p_wave_timer:Timer, wave_data:Resource)->void :

				wave_timer = p_wave_timer
				current_wave_data = wave_data
				
				for group_data in groups_data_in_all_waves:
								current_wave_data.groups_data.push_back(group_data)

				if RunData.elites_spawn.size() > 0:
								for elite_spawn in RunData.elites_spawn:
												if RunData.current_wave == (elite_spawn[0] as int):
																_is_elite_wave = true
																_elite_spawn_data = elite_spawn
																
																var groups_to_add = []
																
																if elite_spawn[1] == EliteType.ELITE:
																				
																				var local_elite_group = elite_group.duplicate()
																				
																				for elite in ItemService.elites:
																								if elite_spawn[2] == elite.my_id:
																												var unit = WaveUnitData.new()
																												unit.type = EntityType.BOSS
																												unit.unit_scene = elite.scene
																												local_elite_group.wave_units_data.push_back(unit)
																				
																				groups_to_add.push_back(local_elite_group)
																elif elite_spawn[1] == EliteType.HORDE:
																				for group_data in horde_groups:
																								if RunData.current_wave >= group_data.min_wave and RunData.current_wave <= group_data.max_wave:
																												groups_to_add.push_back(group_data)
																
																for group_data in groups_to_add:
																				current_wave_data.groups_data.push_back(group_data)
																
																break


func _physics_process(_delta:float)->void :
				if wave_timer == null or current_wave_data == null:
								return 
				
				if wave_timer.time_left as int != _last_time_checked:
								_last_time_checked = wave_timer.time_left as int
				
								for group_data in current_wave_data.groups_data:
												
												var spawn_start_wave = group_data.is_boss or (group_data.is_neutral and RunData.effects["trees_start_wave"] and wave_timer.time_left >= wave_timer.wait_time - 5)
												
												if RunData.get_current_difficulty() >= group_data.min_difficulty and (wave_timer.time_left <= wave_timer.wait_time - group_data.spawn_timing or spawn_start_wave):
																if randf() <= group_data.spawn_chance:
																				emit_signal("group_spawn_timing_reached", group_data, _is_elite_wave)

																if group_data.repeating > 0:
																				add_group_to_repeat(group_data)
																
																_groups_to_remove.push_back(group_data)
								
								if _groups_to_repeat.size() > 0:
												for group in _groups_to_repeat:
																if wave_timer.time_left <= group[NEXT_REPEAT]:
																				emit_and_update_repeat_group(group)
								
								remove_groups()
								remove_repeat_groups()


func add_group_to_repeat(group_data:WaveGroupData)->void :
				var next_spawn_timing = wave_timer.wait_time - group_data.spawn_timing - group_data.repeating_interval
				_groups_to_repeat.push_back(
								[
												group_data, 
												group_data.repeating, 
												group_data.repeating_interval, 
												group_data.reduce_repeating_interval, 
												group_data.min_repeating_interval, 
												next_spawn_timing
								]
				)


func emit_and_update_repeat_group(group:Array)->void :
				emit_signal("group_spawn_timing_reached", group[DATA], _is_elite_wave)
				group[REPEATING] -= 1
				
				if group[REPEATING] <= 0:
								_repeat_groups_to_remove.push_back(group)
				
				group[REPEATING_INTERVAL] = max(group[MIN_REPEATING_INTERVAL], group[REPEATING_INTERVAL] - group[REDUCE_REPEATING_INTERVAL])
				group[NEXT_REPEAT] -= group[REPEATING_INTERVAL]


func remove_groups()->void :
				if _groups_to_remove.size() > 0:
								for group_to_remove in _groups_to_remove:
												current_wave_data.groups_data.erase(group_to_remove)
												
								_groups_to_remove.clear()


func remove_repeat_groups()->void :
				if _repeat_groups_to_remove.size() > 0:
								for group_to_remove in _repeat_groups_to_remove:
												_groups_to_repeat.erase(group_to_remove)
												
								_repeat_groups_to_remove.clear()


func clean_up_room()->void :
				set_physics_process(false)
				_groups_to_remove.clear()
				_groups_to_repeat.clear()
				_repeat_groups_to_remove.clear()
