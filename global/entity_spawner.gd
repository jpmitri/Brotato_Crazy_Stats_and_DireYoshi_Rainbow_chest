class_name EntitySpawner
extends Node2D

signal enemy_number_updated(nb_of_enemies, nb_of_births)
signal player_spawned(player)
signal enemy_spawned(enemy)
signal neutral_spawned(neutral)
signal structure_spawned(structure)

export (PackedScene) var player_scene
export (PackedScene) var entity_birth_scene

const MAX_STRUCTURES = 50
const MIN_DIST_FROM_PLAYER = 300

var _cleaning_up = false

var births: = []
var enemies: = []
var bosses: = []
var neutrals: = []
var structures: = []
var queue_to_spawn: = []
var spawn_timer: = 0
var enemies_removed_for_perf = 0

var _base_structures_spawned = false

var _player
var _entities_container:Node2D
var _births_container:Node2D
var _zone_min_pos:Vector2
var _zone_max_pos:Vector2
var _current_wave_data:WaveData
var _wave_timer:Timer

var _possible_edge_spawns: = [Direction.TOP, Direction.LEFT, Direction.BOTTOM, Direction.RIGHT]

onready  var _spawn_timer = $SpawnTimer
onready  var _structure_timer = $StructureTimer


func init(
		entities_container:Node2D, 
		births_container:Node2D, 
		zone_min_pos:Vector2, 
		zone_max_pos:Vector2, 
		current_wave_data:WaveData, 
		wave_timer:Timer
	)->void :
	
	_current_wave_data = current_wave_data
	_zone_min_pos = zone_min_pos
	_zone_max_pos = zone_max_pos
	_entities_container = entities_container
	_births_container = births_container
	_wave_timer = wave_timer
	_player = spawn_entity(player_scene, Vector2(zone_max_pos.x / 2, zone_max_pos.y / 2), true)
	
	emit_signal("player_spawned", _player)


func on_group_spawn_timing_reached(group_data:WaveGroupData, is_elite_wave:bool)->void :
	
	var max_wave_size = _current_wave_data.max_enemies
	if max_wave_size != ProgressData.settings.max_Var_enemy:
		max_wave_size = ProgressData.settings.max_Var_enemy as int
	if enemies.size() > max_wave_size:
		var nb_to_remove = enemies.size() - _current_wave_data.max_enemies
		
		for i in nb_to_remove:
			var en = Utils.get_rand_element(enemies)
			en.can_drop_loot = false
			en.die()
			enemies_removed_for_perf += 1
	
	var group_pos:Vector2 = get_group_pos(group_data)
	
	var units_data = group_data.wave_units_data

	if group_data.is_boss and not RunData.effects["double_boss"]:
		units_data = [Utils.get_rand_element(units_data)]
	
	var global_mod = 1.0 * (ProgressData.settings.enemy_multiplier)
	

	for unit_wave_data in units_data:
		var mod = 0
		var flat_mod = 0
		
		if unit_wave_data.type == EntityType.ENEMY:
			mod += (RunData.effects["number_of_enemies"] / 100.0)
		elif unit_wave_data.type == EntityType.NEUTRAL:
			flat_mod += RunData.effects["trees"]
		
		var min_nb = (unit_wave_data.min_number + flat_mod)
		var max_nb = (unit_wave_data.max_number + flat_mod)
		
		var number = (Utils.get_random_int(min_nb, max_nb) * global_mod) as int
		
		if mod < 0 and number > 1:
			var nb_to_remove = 0
			
			for i in number:
				if randf() < abs(mod):
					nb_to_remove += 1
			
			number = max(1, number - nb_to_remove)
		elif mod > 0:
			var nb_to_add = 0
			var additionals = (max(0, number * (mod - 1)))
			
			
			for i in (number + additionals) as int:
				if randf() < abs(mod):
					nb_to_add += 1
			
			number += nb_to_add
		
		for i in number:
			if randf() <= unit_wave_data.spawn_chance:
				var spawn_pos = get_spawn_pos_in_area(group_pos, group_data.area, group_data.spawn_dist_away_from_edges, group_data.spawn_edge_of_map)
				
				while spawn_pos.distance_to(_player.global_position) < MIN_DIST_FROM_PLAYER:
					spawn_pos = get_spawn_pos_in_area(group_pos, - 1, group_data.spawn_dist_away_from_edges, group_data.spawn_edge_of_map)
				
				add_entity_to_spawn(unit_wave_data.type, unit_wave_data.unit_scene, spawn_pos)


func get_group_pos(group_data:WaveGroupData)->Vector2:

	var base_pos:Vector2
	var d = group_data.spawn_dist_away_from_edges
	
	if group_data.area != - 1:
		base_pos = Vector2(
			rand_range(_zone_min_pos.x + d, _zone_max_pos.x - group_data.area - d), 
			rand_range(_zone_min_pos.y + d, _zone_max_pos.y - group_data.area - d)
		)
	else :
		base_pos = Vector2(
			rand_range(_zone_min_pos.x, _zone_max_pos.x), 
			rand_range(_zone_min_pos.y, _zone_max_pos.y)
		)
	
	return base_pos


func add_entity_to_spawn(type:int, scene:PackedScene, pos:Vector2, data:Resource = null)->void :
	queue_to_spawn.append([type, scene, pos, data])
	if _spawn_timer.is_stopped():
		_spawn_timer.start()


func _on_SpawnTimer_timeout()->void :
	if queue_to_spawn.size() == 0:
		return 
	
	var entity_to_spawn = queue_to_spawn.pop_back()
	
	var spawn_pos:Vector2 = entity_to_spawn[2]
	






	
	spawn_entity_birth(entity_to_spawn[0], entity_to_spawn[1], spawn_pos, entity_to_spawn[3])
	queue_to_spawn.erase(entity_to_spawn)
	
	if queue_to_spawn.size() > 0:
		_spawn_timer.start()


func spawn_entity_birth(type:int, scene:PackedScene, pos:Vector2, data:Resource = null)->void :
	var entity_birth = entity_birth_scene.instance()
	
	if type == EntityType.NEUTRAL:
		entity_birth.color = Utils.GOLD_COLOR
	elif type == EntityType.STRUCTURE:
		entity_birth.color = Color.cornflower
		
		if structures.size() > MAX_STRUCTURES:
			var nb_to_remove = structures.size() - MAX_STRUCTURES
			
			for i in nb_to_remove:
				var st = Utils.get_rand_element(structures)
				st.die()
	
	entity_birth.global_position = pos
	_births_container.call_deferred("add_child", entity_birth)
	
	entity_birth.set_entity(type, scene, data)
	entity_birth.connect("birth_timeout", self, "on_entity_birth_timeout")
	
	births.push_back(entity_birth)


func on_entity_birth_timeout(birth:EntityBirth, type:int, scene:PackedScene, pos:Vector2, data:Resource)->void :
	var entity = spawn_entity(scene, pos, false, data)
	
	if type == EntityType.ENEMY:
		enemies.push_back(entity)
		entity.connect("died", self, "_on_enemy_died")
		entity.connect("wanted_to_spawn_an_enemy", self, "on_enemy_wanted_to_spawn_an_enemy")
		emit_signal("enemy_spawned", entity)
	elif type == EntityType.BOSS:
		bosses.push_back(entity)
		entity.connect("died", self, "_on_boss_died")
		entity.connect("wanted_to_spawn_an_enemy", self, "on_enemy_wanted_to_spawn_an_enemy")
		emit_signal("enemy_spawned", entity)
		get_parent()._bosses_spawned+=1
	elif type == EntityType.NEUTRAL:
		neutrals.push_back(entity)
		entity.connect("died", self, "_on_neutral_died")
		emit_signal("neutral_spawned", entity)
	elif type == EntityType.STRUCTURE:
		structures.push_back(entity)
		entity.connect("died", self, "_on_structure_died")
		emit_signal("structure_spawned", entity)
	
	births.erase(birth)


func spawn_entity(scene:PackedScene, pos:Vector2, is_player:bool = false, data:Resource = null)->KinematicBody2D:
	var entity = scene.instance()
	
	if is_player:
		
		if DebugService.add_all_weapons:
			for weapon in ItemService.weapons:
				RunData.add_weapon(weapon)
		
		if DebugService.add_all_items and not DebugService.debug_items_added:
			for item in ItemService.items:
				RunData.add_item(item)
			DebugService.debug_items_added = true
		
		if DebugService.debug_weapons.size() > 0:
			for weapon in DebugService.debug_weapons:
				RunData.add_weapon(weapon)
		
		if DebugService.no_weapons:
			RunData.weapons = []
		
		if DebugService.debug_items.size() > 0 and not DebugService.debug_items_added:
			for item in DebugService.debug_items:
				RunData.add_item(item)
			
			DebugService.debug_items_added = true
	
	entity.global_position = pos
	
	if data:
		entity.set_data(data)
	
	_entities_container.add_child(entity)
	
	if is_player:
		entity.apply_items_effects()
	
	entity.init(_zone_min_pos, _zone_max_pos, _player, self)
	
	return entity


func on_enemy_wanted_to_spawn_an_enemy(enemy_scene:PackedScene, at_position:Vector2)->void :
	spawn_entity_birth(EntityType.ENEMY, enemy_scene, at_position)


func _on_boss_died(boss:Node2D)->void :
	if not _cleaning_up:
		bosses.erase(boss)


func _on_enemy_died(enemy:Node2D)->void :
	if not _cleaning_up:
		enemies.erase(enemy)
		emit_signal("enemy_number_updated", enemies.size(), births.size())


func _on_neutral_died(neutral:Node2D)->void :
	if not _cleaning_up:
		neutrals.erase(neutral)


func _on_structure_died(structure:Node2D)->void :
	if not _cleaning_up:
		structures.erase(structure)


func get_spawn_pos_in_area(base_pos:Vector2, area:int, spawn_dist_from_edges:int = 0, spawn_edge_of_map:bool = false)->Vector2:
	
	var d = spawn_dist_from_edges
	if spawn_edge_of_map:
		var spawn_direction = _possible_edge_spawns[randi() % _possible_edge_spawns.size()]
		return Utils.get_rand_pos_from_direction_at_distance(spawn_direction, _zone_min_pos, _zone_max_pos, Utils.EDGE_MAP_DIST)
	elif area == - 1:
		return Vector2(rand_range(_zone_min_pos.x + d, _zone_max_pos.x - d), rand_range(_zone_min_pos.y + d, _zone_max_pos.y - d))
	else :
		return ZoneService.get_rand_pos_in_area(base_pos, area)


func get_rand_enemy(ignore_unit:Node2D = null)->Node2D:
	if enemies.size() <= 0 or (enemies.size() <= 1 and ignore_unit != null):
		return null
	
	var unit = Utils.get_rand_element(enemies)
	
	if ignore_unit != null and enemies.size() > 1:
		while unit == ignore_unit:
			unit = Utils.get_rand_element(enemies)
	
	return unit


func get_all_enemies()->Array:
	return enemies + bosses


func _on_StructureTimer_timeout()->void :
	if _cleaning_up:return 
	var cur_time = ((_wave_timer.wait_time - _wave_timer.time_left) as int)
	
	var spawn_radius = min(600, 400 + (RunData.effects["structures"].size() * 10))
	var base_pos = ZoneService.get_rand_pos(600)
	var nb_turrets = 0
	var spawn_all = false
	
	if not _base_structures_spawned:
		spawn_all = true
		_base_structures_spawned = true
	
	for struct in RunData.effects["structures"]:
		if (struct.spawn_cooldown != - 1 and cur_time % struct.spawn_cooldown == 0) or spawn_all:
			
			if struct is TurretEffect:
				nb_turrets += 1
			
			for nb in struct.value:
				var pos = get_spawn_pos_in_area(base_pos, spawn_radius) if RunData.effects["group_structures"] and struct.can_be_grouped else ZoneService.get_rand_pos()
				
				if struct.spawn_around_player != - 1:
					pos = get_spawn_pos_in_area(_player.global_position, struct.spawn_around_player)
				
				add_entity_to_spawn(EntityType.STRUCTURE, struct.scene, pos, struct)
	
	if nb_turrets >= ChallengeService.get_chal("chal_turrets").value:
		ChallengeService.complete_challenge("chal_turrets")


func clean_up_room()->void :
	_cleaning_up = true
	_structure_timer.stop()
	_spawn_timer.stop()
	
	queue_to_spawn.clear()
	
	for birth in births:
		if birth:
			birth.call_deferred("queue_free")
	
	for boss in bosses:
		boss.die(Vector2.ZERO, _cleaning_up)
	
	for enemy in enemies:
		enemy.die(Vector2.ZERO, _cleaning_up)
	
	for neutral in neutrals:
		neutral.die(Vector2.ZERO, _cleaning_up)
	
	for structure in structures:
		structure.die(Vector2.ZERO, _cleaning_up)
