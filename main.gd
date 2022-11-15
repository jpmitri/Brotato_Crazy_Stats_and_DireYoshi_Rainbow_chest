extends Node

signal consumable_to_process_added(consumable_data)
signal upgrade_to_process_added(consumable_data)

export (PackedScene) var gold_bag_scene:PackedScene
export (PackedScene) var gold_scene:PackedScene
export (PackedScene) var consumable_scene:PackedScene
export (Array) var gold_sprites:Array
export (Array, Resource) var gold_pickup_sounds:Array
export (Array, Resource) var gold_alt_pickup_sounds:Array
export (Resource) var level_up_sound:Resource
export (Array, Resource) var run_won_sounds:Array
export (Array, Resource) var run_lost_sounds:Array
export (Array, Resource) var end_wave_sounds:Array

const EDGE_SIZE = 96
const MAX_GOLDS = 50
const MIN_MAP_SIZE = 12

const MOUSE_DIST_FROM_PLAYER_MANUAL_AIM = 200

var _cleaning_up: = false
var _golds: = []
var _consumables: = []
var _upgrades_to_process: = []
var _consumables_to_process: = []
var _end_wave_timer_timedout: = false

var _player:Player
var _is_run_lost:bool
var _gold_bag:Node

var _landmine_timer:Timer = null
var _is_chal_ui_displayed = false

var _last_rjoy_input:Vector2 = Vector2.ZERO

var _proj_on_death_stat_cache:Dictionary = {}
var _items_spawned_this_wave: = 0

var _nb_bosses_killed_this_wave: = 0
var _update_stats_on_gold_changed: = false
var _last_gold_amount_used_to_reload_stats: = 0
var _is_horde_wave: = false
var _is_elite_wave: = false
var _elite_killed_bonus: = 0
var _elite_killed: = false
var _bosses_spawned:int = 0

onready  var _entities_container = $Entities
onready  var _entity_spawner = $EntitySpawner
onready  var _effects_manager = $EffectsManager
onready  var _wave_manager = $WaveManager
onready  var _floating_text_manager = $FloatingTextManager
onready  var _camera = $Camera
onready  var _screenshaker = $Camera / Screenshaker
onready  var _items_container = $Items
onready  var _consumables_container = $Consumables
onready  var _births_container = $Births
onready  var _pause_menu = $UI / PauseMenu
onready  var _end_wave_timer = $EndWaveTimer
onready  var _upgrades_ui = $UI / UpgradesUI as UpgradesUI
onready  var _item_box_ui = $UI / ItemBoxUI as ItemBoxUI
onready  var _rainbow_box_ui = $UI / RainbowBoxUI as RainbowBoxUI
onready  var _wave_timer = $WaveTimer

onready  var _wave_cleared_label = $UI / WaveClearedLabel
onready  var _life_label = $UI / HUD / LifeContainer / UILifeBar / MarginContainer / LifeLabel
onready  var _level_label = $UI / HUD / LifeContainer / UIXPBar / MarginContainer / LevelLabel
onready  var _hud = $UI / HUD
onready  var _life_bar = $UI / HUD / LifeContainer / UILifeBar
onready  var _xp_bar = $UI / HUD / LifeContainer / UIXPBar
onready  var _ui_gold = $UI / HUD / LifeContainer / UIGold
onready  var _ui_bonus_gold = $UI / HUD / LifeContainer / UIBonusGold
onready  var _ui_bonus_gold_pos = $UI / HUD / LifeContainer / UIBonusGold / Position2D
onready  var _current_wave_label = $UI / HUD / WaveContainer / CurrentWaveLabel
onready  var _wave_timer_label = $UI / HUD / WaveContainer / WaveTimerLabel
onready  var _ui_wave_container = $UI / HUD / WaveContainer
onready  var _ui_upgrades_to_process = $UI / HUD / ThingsToProcessContainer / Upgrades
onready  var _ui_consumables_to_process = $UI / HUD / ThingsToProcessContainer / Consumables
onready  var _ui_dim_screen = $UI / DimScreen
onready  var _tile_map = $TileMap
onready  var _tile_map_limits = $TileMapLimits
onready  var _background = $CanvasLayer / Background
onready  var _harvesting_timer = $HarvestingTimer
onready  var _challenge_completed_ui = $UI / ChallengeCompletedUI

onready  var _damage_vignette = $UI / DamageVignette
onready  var _info_popup = $UI / InfoPopup


func _ready()->void :
				var _popup = _challenge_completed_ui.connect("started", self, "on_chal_popup")
				var _popout = _challenge_completed_ui.connect("finished", self, "on_chal_popout")

				_background.texture.gradient.colors[1] = RunData.get_background_gradient_color()
				_tile_map.tile_set.tile_set_texture(0, RunData.get_background().tiles_sprite)
				_tile_map.outline.modulate = RunData.get_background().outline_color
				TempStats.reset()
				var _temp_stats = TempStats.connect("temp_stat_updated", self, "on_stat_updated")
				var _stat_added = RunData.connect("stat_added", self, "on_stat_updated")
				var _stat_removed = RunData.connect("stat_removed", self, "on_stat_updated")

				_gold_bag = Utils.instance_scene_on_main(gold_bag_scene, get_gold_bag_pos())
				var current_zone = ZoneService.get_zone_data(RunData.current_zone).duplicate()
				var current_wave_data = ZoneService.get_wave_data(RunData.current_zone, RunData.current_wave)

				var map_size_coef = (1 + (RunData.effects["map_size"] / 100.0))
				var map_size_adj = ProgressData.settings.map_size

				if map_size_coef * map_size_adj < 0.5:
					map_size_coef=0.5
				else:
					map_size_coef*=map_size_adj

				RunData.effects["map_size"]=map_size_coef

				current_zone.width = max(MIN_MAP_SIZE, (current_zone.width * map_size_coef)) as int
				current_zone.height = max(MIN_MAP_SIZE, (current_zone.height * map_size_coef)) as int

				_tile_map.init(current_zone)
				_tile_map_limits.init(current_zone)

				ZoneService.current_zone_max_position = Vector2(current_zone.width * Utils.TILE_SIZE, current_zone.height * Utils.TILE_SIZE)

				_entity_spawner.init(
								_entities_container, 
								_births_container, 
								ZoneService.current_zone_min_position, 
								ZoneService.current_zone_max_position, 
								current_wave_data, 
								_wave_timer
				)

				_current_wave_label.text = Text.text("WAVE", [str(RunData.current_wave)]).to_upper()
				
				_wave_timer.wait_time = 1 if DebugService.instant_waves else current_wave_data.wave_duration * ProgressData.settings.round_modification
				_wave_timer.start()
				_wave_timer_label.wave_timer = _wave_timer
				var _error_wave_timer = _wave_timer.connect("tick_started", self, "on_tick_started")

				var _error_group_spawn = _wave_manager.connect("group_spawn_timing_reached", _entity_spawner, "on_group_spawn_timing_reached")
				_wave_manager.init(_wave_timer, current_wave_data)

				var _error_upg_select = _upgrades_ui.connect("upgrade_selected", self, "on_upgrade_selected")
				var _error_take_button = _item_box_ui.connect("item_take_button_pressed", self, "on_item_box_take_button_pressed")
				var _error_take_rainbow_button = _rainbow_box_ui.connect("item_take_button_pressed", self, "on_item_box_take_button_pressed")
				var _error_discard_button = _item_box_ui.connect("item_discard_button_pressed", self, "on_item_box_discard_button_pressed")

				var _error_consumable_added = connect("consumable_to_process_added", _ui_consumables_to_process, "add_element")
				var _error_upgrade_added = connect("upgrade_to_process_added", _ui_upgrades_to_process, "add_element")

				var _error_level_up = RunData.connect("levelled_up", self, "on_levelled_up")
				var _error_level_up_floating_text = RunData.connect("levelled_up", _floating_text_manager, "on_levelled_up")
				var _error_xp_added = RunData.connect("xp_added", _xp_bar, "update_value")
				var _error_gold_ui = RunData.connect("gold_changed", _ui_gold, "on_gold_changed")
				var _error_gold_changed = RunData.connect("gold_changed", self, "on_gold_changed")
				var _error_bonus_gold_ui = RunData.connect("bonus_gold_changed", _ui_bonus_gold, "update_value")
				var _error_bonus_gold = RunData.connect("bonus_gold_changed", self, "on_bonus_gold_changed")
				on_bonus_gold_changed(RunData.bonus_gold)

				var _error_gamepad = InputService.connect("game_lost_focus", _pause_menu, "on_game_lost_focus")

				var _error_ui_upgrades_mouse_entered = _ui_upgrades_to_process.connect("ui_element_mouse_entered", self, "on_ui_element_mouse_entered")
				var _error_ui_consumables_mouse_entered = _ui_consumables_to_process.connect("ui_element_mouse_entered", self, "on_ui_element_mouse_entered")
				var _error_ui_upgrades_mouse_exited = _ui_upgrades_to_process.connect("ui_element_mouse_exited", self, "on_ui_element_mouse_exited")
				var _error_ui_consumables_mouse_exited = _ui_consumables_to_process.connect("ui_element_mouse_exited", self, "on_ui_element_mouse_exited")

				init_camera()
				set_level_label()
				_ui_dim_screen.color.a = 0

				if RunData.effects["gain_pct_gold_start_wave"] != 0:
								RunData.add_gold(RunData.gold * (RunData.effects["gain_pct_gold_start_wave"] / 100.0))

				for stat_link in RunData.effects["stat_links"]:
								if stat_link[2] == "materials":
												_update_stats_on_gold_changed = true

				if ProgressData.is_manual_aim():
								ProgressData.update_mouse_cursor()
								InputService.hide_mouse = false

				var _error_options_1 = _pause_menu.menu_gameplay_options.connect("character_highlighting_changed", self, "on_character_highlighting_changed")
				var _error_options_2 = _pause_menu.menu_gameplay_options.connect("hp_bar_on_character_changed", self, "on_hp_bar_on_character_changed")
				var _error_options_3 = _pause_menu.menu_gameplay_options.connect("weapon_highlighting_changed", self, "on_weapon_highlighting_changed")
				var _error_options_4 = _pause_menu.menu_gameplay_options.connect("darken_screen_changed", self, "on_darken_screen_changed")

				_is_horde_wave = RunData.is_elite_wave(EliteType.HORDE)
				_is_elite_wave = RunData.is_elite_wave(EliteType.ELITE)

				DebugService.log_run_info()


func _input(event:InputEvent)->void :
				var is_right_stick_motion = event is InputEventJoypadMotion and (event.axis == JOY_AXIS_2 or event.axis == JOY_AXIS_3) and abs(event.axis_value) > 0.5
				var is_mouse_press = event is InputEventMouseButton

				if (is_mouse_press or is_right_stick_motion) and not _cleaning_up:
								if ProgressData.settings.manual_aim_on_mouse_press and not ProgressData.settings.manual_aim:
												ProgressData.update_mouse_cursor()

												if is_mouse_press:
																if event.pressed:
																				InputService.hide_mouse = false
																else :
																				InputService.hide_mouse = true
												else :
																InputService.hide_mouse = false

				if InputService.using_gamepad and not InputService.hide_mouse and not ProgressData.is_manual_aim():
								InputService.hide_mouse = true


func add_timer(cooldown:int)->Timer:
				var timer = Timer.new()
				timer.wait_time = cooldown
				add_child(timer)
				timer.start()
				return timer


func on_ui_element_mouse_entered(ui_element:Node, text:String)->void :
				if _cleaning_up:
								_info_popup.display(ui_element, tr(text))


func on_ui_element_mouse_exited(_ui_element:Node)->void :
				_info_popup.hide()


func on_character_highlighting_changed(value:int)->void :
				if not is_instance_valid(_player) or not _player.is_inside_tree():return 
				_player.highlight.visible = value


func on_weapon_highlighting_changed(value:int)->void :
				if not is_instance_valid(_player) or not _player.is_inside_tree():return 
				_player.update_weapon_highlighting(value)


func on_darken_screen_changed(_value:int)->void :
				_damage_vignette.update_from_hp()


func on_hp_bar_on_character_changed(value:int)->void :
				if not is_instance_valid(_player) or not _player.is_inside_tree():return 

				if value:
								_player.life_bar.update_value(_player.current_stats.health, _player.max_stats.health)

								if _player.current_stats.health < _player.max_stats.health:
												_player.life_bar.show()

								if not _player.is_connected("health_updated", _player, "on_health_updated"):
												var _error_hp_lifebar = _player.connect("health_updated", _player, "on_health_updated")
				else :
								_player.life_bar.hide()
								if _player.is_connected("health_updated", _player, "on_health_updated"):
												_player.disconnect("health_updated", _player, "on_health_updated")


func on_stat_updated(_stat_name:String, _value:int)->void :
				reload_stats()


func reload_stats()->void :
				_player.update_player_stats()

				LinkedStats.reset()

				for weapon in _player.current_weapons:
								if is_instance_valid(weapon):
												weapon.init_stats(false)


				if RunData.effects["burn_chance"].chance > 0.0:
								for struct in _entity_spawner.structures:
												if is_instance_valid(struct):
																struct.reload_data()

				_proj_on_death_stat_cache.clear()


func _physics_process(_delta:float)->void :
				_gold_bag.global_position = get_gold_bag_pos()

				if not _cleaning_up and ProgressData.is_manual_aim() and InputService.using_gamepad:
								var rjoy = Input.get_vector("rjoy_left", "rjoy_right", "rjoy_up", "rjoy_down").normalized()
								var player_pos = _player.get_global_transform_with_canvas().origin

								player_pos.y -= 32
								if rjoy.length() > 0.5:
												get_viewport().warp_mouse(player_pos + MOUSE_DIST_FROM_PLAYER_MANUAL_AIM * rjoy)
												_last_rjoy_input = rjoy
								else :
												get_viewport().warp_mouse(player_pos + MOUSE_DIST_FROM_PLAYER_MANUAL_AIM * _last_rjoy_input)


func on_tick_started()->void :
				_wave_timer_label.modulate = Color.red


func on_bonus_gold_changed(value:int)->void :
				if value == 0:
								_ui_bonus_gold.hide()


func init_camera()->void :
				var max_pos = ZoneService.current_zone_max_position
				var min_pos = ZoneService.current_zone_min_position

				var zone_w = max_pos.x - min_pos.x
				var zone_h = max_pos.y - min_pos.y

				_camera.center_horizontal_pos = zone_w / 2
				_camera.center_vertical_pos = zone_h / 2

				if zone_w + EDGE_SIZE * 2 <= Utils.project_width:
								_camera.center_horizontal = true
				else :
								_camera.limit_right = max_pos.x + EDGE_SIZE
								_camera.limit_left = min_pos.x - EDGE_SIZE

				if zone_h + EDGE_SIZE * 2 <= Utils.project_height:
								_camera.center_vertical = true
				else :
								_camera.limit_bottom = max_pos.y + EDGE_SIZE
								_camera.limit_top = min_pos.y - EDGE_SIZE * 2


func _on_player_died(_p_player:Player)->void :
				_is_run_lost = true
				clean_up_room(false, _is_run_lost)
				_end_wave_timer.start()
				ProgressData.reset_run_state()
				ChallengeService.complete_challenge("chal_rookie")


func _on_enemy_died(enemy:Enemy)->void :
				if not _cleaning_up:
								if enemy is Boss:
												_nb_bosses_killed_this_wave += 1
												if RunData.current_wave < RunData.nb_of_waves:
																_elite_killed = true

												if (_nb_bosses_killed_this_wave >= _bosses_spawned) and RunData.current_wave == RunData.nb_of_waves:
																_wave_timer.wait_time = 0.1
																_wave_timer.start()

								if randf() < RunData.effects["dmg_when_death_from_luck"][0] / 100.0 and _entity_spawner.get_all_enemies().size() > 0:
												var dmg_from_luck = max(1, (RunData.effects["dmg_when_death_from_luck"][1] / 100.0) * Utils.get_stat("stat_luck"))
												var dmg = RunData.get_dmg(dmg_from_luck) as int
												var other_enemy = Utils.get_rand_element(_entity_spawner.get_all_enemies())
												other_enemy.take_damage(dmg)

								if RunData.effects["projectiles_on_death"].size() > 0:
												for proj_on_death_effect in RunData.effects["projectiles_on_death"]:
																for i in proj_on_death_effect[0]:
																				var stats = proj_on_death_effect[1]

																				if _proj_on_death_stat_cache.has(i):
																								stats = _proj_on_death_stat_cache[i]
																				else :
																								stats = WeaponService.init_ranged_stats(proj_on_death_effect[1])
																								_proj_on_death_stat_cache[i] = stats

																				var _projectile = WeaponService.manage_special_spawn_projectile(
																								enemy, 
																								stats, 
																								proj_on_death_effect[2], 
																								_entity_spawner
																				)

								if RunData.effects["explode_on_death"].size() > 0:
												var explosion_chance = 0.0

												for explosion in RunData.effects["explode_on_death"]:
																explosion_chance += explosion.chance

												if randf() <= explosion_chance:
																var dmg = 0
																var first = RunData.effects["explode_on_death"][0]
																var exploding_effect = ExplodingEffect.new()

																for explosion in RunData.effects["explode_on_death"]:
																				var explosion_stats = WeaponService.init_base_stats(explosion.stats, "", [], [exploding_effect])
																				dmg += explosion_stats.damage

																WeaponService.explode(first, enemy.global_position, dmg, first.stats.accuracy, first.stats.crit_chance, first.stats.crit_damage, first.stats.burning_data)

								spawn_loot(enemy, EntityType.ENEMY)

								ProgressData.add_data("enemies_killed")


func _on_neutral_died(neutral:Neutral)->void :
				if not _cleaning_up:
								spawn_loot(neutral, EntityType.NEUTRAL)


func spawn_loot(unit:Unit, entity_type:int)->void :

				if not unit.can_drop_loot:
								return 

				if unit.stats.can_drop_consumables:
								spawn_consumables(unit)

				var gold_drops = (RunData.effects["gold_drops"] / 100.0)



				if entity_type == EntityType.ENEMY:
								gold_drops += RunData.effects["enemy_gold_drops"] / 100.0

				var wave_factor = (RunData.current_wave * 0.015)
				var diff_factor = (RunData.effects["diff_gold_drops"] / 100.0)
				var spawn_chance = (1.0 + diff_factor) * gold_drops if (RunData.current_wave < 5) else max(0.25, (1.0 - wave_factor + diff_factor) * gold_drops)

				if _is_horde_wave:
								spawn_chance *= 0.5

				if entity_type == EntityType.ENEMY and randf() > spawn_chance:
								return 

				if _golds.size() > MAX_GOLDS:
								var gold_boosted = Utils.get_rand_element(_golds)
								gold_boosted.value += unit.stats.value
								gold_boosted.scale += Vector2(unit.stats.value * 0.05, unit.stats.value * 0.05)
				else :
								spawn_gold(unit, entity_type)


func spawn_consumables(unit:Unit)->void :
				var luck = (Utils.get_stat("stat_luck") / 100.0)
				var drop_chance = unit.stats.base_drop_chance * (1 + luck)

				if randf() <= drop_chance or unit.stats.always_drop_consumables:
								var pos = unit.global_position
								var consumable_to_spawn:Resource
								var item_chance = (unit.stats.item_drop_chance * (1 + luck)) / (1 + _items_spawned_this_wave)
								if ProgressData.settings.luck_everything > 0:
												item_chance = (unit.stats.item_drop_chance * (1 + luck * ProgressData.settings.luck_everything)) / (1 + _items_spawned_this_wave)

								if unit.stats.always_drop_consumables and unit.stats.item_drop_chance >= 1.0:
												item_chance = 1.0

								if unit is Boss:
												if ProgressData.settings.elites_drop_rainbow:
																consumable_to_spawn = ItemService.rainbow_box
												else :
																consumable_to_spawn = ItemService.legendary_item_box

								elif ProgressData.settings.rainbow_box_chance and not _items_spawned_this_wave:
												consumable_to_spawn = ItemService.rainbow_box
												_items_spawned_this_wave += 1

								elif randf() <= item_chance:
												if Utils.is_chance_factor(ProgressData.settings.rainbow_box_chance):
																consumable_to_spawn = ItemService.rainbow_box
												else :
																consumable_to_spawn = ItemService.item_box
												_items_spawned_this_wave += 1

								else :
												var consumable_tier = Utils.get_random_int(unit.stats.min_consumable_tier, unit.stats.max_consumable_tier)
												consumable_to_spawn = ItemService.get_consumable_to_drop(consumable_tier)

								var dist = rand_range(50, 100 + unit.stats.gold_spread)
								var consumable = consumable_scene.instance()
								consumable.consumable_data = consumable_to_spawn
								consumable.global_position = pos
								_consumables_container.call_deferred("add_child", consumable)
								consumable.call_deferred("set_texture", consumable_to_spawn.icon)
								var _error = consumable.connect("picked_up", self, "on_consumable_picked_up")
								consumable.push_back_destination = Vector2(rand_range(pos.x - dist, pos.x + dist), rand_range(pos.y - dist, pos.y + dist))
								_consumables.push_back(consumable)


func on_consumable_picked_up(consumable:Node)->void :
				_consumables.erase(consumable)

				if (consumable.consumable_data.my_id == "consumable_item_box" or consumable.consumable_data.my_id == "consumable_legendary_item_box") and RunData.effects["item_box_gold"] != 0:
								RunData.add_gold(RunData.effects["item_box_gold"])

				if consumable.consumable_data.to_be_processed_at_end_of_wave:
								_consumables_to_process.push_back(consumable.consumable_data)
								emit_signal("consumable_to_process_added", consumable.consumable_data)

				RunData.apply_item_effects(consumable.consumable_data)


func spawn_gold(unit:Unit, entity_type:int)->void :
				var pos = unit.global_position
				var value = unit.stats.value

				if entity_type == EntityType.NEUTRAL:
								value += (value * round(RunData.effects["neutral_gold_drops"] / 100.0))

				for i in value:
								var dist = rand_range(50, 100 + unit.stats.gold_spread)
								var gold = gold_scene.instance()

								if RunData.bonus_gold > 0:
												var gold_value = gold.value
												gold.value += min(gold.value, RunData.bonus_gold)
												gold.boosted = 2
												gold.scale.x = 1.25
												gold.scale.y = 1.25
												RunData.remove_bonus_gold(gold_value)

								gold.global_position = pos
								gold.rotation = rand_range(0, 2 * PI)
								_items_container.call_deferred("add_child", gold)
								gold.call_deferred("set_texture", gold_sprites[randi() % 11])
								var _error = gold.connect("picked_up", self, "on_gold_picked_up")
								var _error_effects = gold.connect("picked_up", _effects_manager, "on_gold_picked_up")
								var _error_floating_text = gold.connect("picked_up", _floating_text_manager, "on_gold_picked_up")
								gold.push_back_destination = Vector2(rand_range(pos.x - dist, pos.x + dist), rand_range(pos.y - dist, pos.y + dist))
								_golds.push_back(gold)

								if randf() < (RunData.effects["instant_gold_attracting"] / 100.0):
												gold.attracted_by = _player


func on_gold_picked_up(gold:Node)->void :
				_golds.erase(gold)
				if ProgressData.settings.alt_gold_sounds:
								SoundManager.play(Utils.get_rand_element(gold_alt_pickup_sounds), - 5, 0.2)
				else :
								SoundManager.play(Utils.get_rand_element(gold_pickup_sounds), 0, 0.2)

				var value = gold.value

				if randf() < RunData.effects["chance_double_gold"] / 100.0:
								value *= 2
								gold.boosted *= 2

				if randf() < RunData.effects["heal_when_pickup_gold"] / 100.0:
								RunData.emit_signal("healing_effect", 1)

				if gold.attracted_by == _player:
								if randf() < RunData.effects["dmg_when_pickup_gold_from_luck"][0] / 100.0 and _entity_spawner.get_all_enemies().size() > 0:
												var dmg_from_luck = max(1, (RunData.effects["dmg_when_pickup_gold_from_luck"][1] / 100.0) * Utils.get_stat("stat_luck"))
												var dmg = RunData.get_dmg(dmg_from_luck) as int
												var enemy = Utils.get_rand_element(_entity_spawner.get_all_enemies())
												enemy.take_damage(dmg)

								RunData.add_gold(value)
								RunData.add_xp(value)
								ProgressData.add_data("materials_collected")
				else :
								RunData.add_bonus_gold(value)


func on_levelled_up()->void :
				SoundManager.play(level_up_sound, 0, 0, true)
				var level = RunData.current_level
				emit_signal("upgrade_to_process_added", ItemService.upgrade_to_process_icon, level)
				_upgrades_to_process.push_back(level)
				set_level_label()
				RunData.add_stat("stat_max_hp", 1)
				RunData.emit_signal("healing_effect", 1)


func set_level_label()->void :
				_level_label.text = "LV." + str(RunData.current_level)



func set_life_label(current_health:int, max_health:int)->void :
				_life_label.text = str(max(current_health, 0.0)) + " / " + str(max_health)


func connect_visual_effects(unit:Unit)->void :
				var _error_effects = unit.connect("took_damage", _effects_manager, "_on_unit_took_damage")
				var _error_floating_text = unit.connect("took_damage", _floating_text_manager, "_on_unit_took_damage")


func clean_up_room(is_last_wave:bool = false, is_run_lost:bool = false)->void :

				if is_run_lost:
								DebugService.log_data("is_run_lost")
								_wave_timer_label.is_run_lost = true
								_wave_timer.stop()
								_wave_timer.tick_timer.stop()
								_end_wave_timer.wait_time = 2.5
								SoundManager.play(Utils.get_rand_element(run_lost_sounds), - 5, 0, true)
								_ui_dim_screen.dim()
								MusicManager.tween( - 20)
				elif is_last_wave:
								DebugService.log_data("is_last_wave")
								var character_difficulty = ProgressData.get_character_difficulty_info(RunData.current_character.my_id, RunData.current_zone)

								if character_difficulty.max_selectable_difficulty < RunData.get_current_difficulty() + 1 and RunData.get_current_difficulty() + 1 <= ProgressData.MAX_DIFFICULTY:
												RunData.difficulty_unlocked = RunData.get_current_difficulty() + 1

								ChallengeService.complete_challenge("chal_difficulty_" + str(RunData.get_current_difficulty()))

								for char_diff in ProgressData.difficulties_unlocked:
												for zone_difficulty_info in char_diff.zones_difficulty_info:
																zone_difficulty_info.max_selectable_difficulty = clamp(RunData.get_current_difficulty() + 1, zone_difficulty_info.max_selectable_difficulty, ProgressData.MAX_DIFFICULTY)

								character_difficulty.max_difficulty_beaten.set_info(
												RunData.get_current_difficulty(), 
												RunData.current_wave, 
												RunData.current_run_accessibility_settings.health, 
												RunData.current_run_accessibility_settings.damage, 
												RunData.current_run_accessibility_settings.speed, 
												false
								)

				elif RunData.is_endless_run:
								DebugService.log_data("is_endless_run")
								var character_difficulty = ProgressData.get_character_difficulty_info(RunData.current_character.my_id, RunData.current_zone)

								character_difficulty.max_endless_wave_beaten.set_info(
												RunData.get_current_difficulty(), 
												RunData.current_wave, 
												RunData.current_run_accessibility_settings.health, 
												RunData.current_run_accessibility_settings.damage, 
												RunData.current_run_accessibility_settings.speed, 
												true
								)

				ProgressData.save()

				SoundManager.play(Utils.get_rand_element(end_wave_sounds))
				_cleaning_up = true
				_effects_manager.clean_up_room()
				_floating_text_manager.clean_up_room()

				DebugService.log_data("attract bonus_gold and consumables...")
				if _golds.size() > 0:
								var attracted_by = null




								_ui_bonus_gold.show()
								attracted_by = _gold_bag
								_player.disable_gold_pickup()

								for gold in _golds:
												gold.set_collision_layer(256)
												gold.attracted_by = attracted_by

				if _consumables.size() > 0:
								for consumable in _consumables:
												if consumable.consumable_data.to_be_processed_at_end_of_wave:
																consumable.attracted_by = _player

				DebugService.log_data("clean_up other objects...")
				_entity_spawner.clean_up_room()
				_wave_manager.clean_up_room()

				if is_instance_valid(_player):
								_player.clean_up()

				DebugService.log_data("start wave_cleared_label...")
				_wave_cleared_label.start(is_last_wave, is_run_lost)
				DebugService.log_data("wave_cleared_label started...")


func get_gold_bag_pos()->Vector2:
				return get_viewport().get_canvas_transform().affine_inverse().xform(_ui_bonus_gold_pos.global_position)


func _on_EndWaveTimer_timeout()->void :
				DebugService.log_data("_on_EndWaveTimer_timeout")
				_end_wave_timer_timedout = true
				_ui_dim_screen.dim()
				_ui_consumables_to_process.modulate = Color.white
				_ui_upgrades_to_process.modulate = Color.white
				_wave_cleared_label.hide()
				_wave_timer_label.hide()

				if _landmine_timer:
								_landmine_timer.stop()

				if _is_run_lost or RunData.current_wave == ZoneService.get_zone_data(RunData.current_zone).waves_data.size():
								DebugService.log_data("end run...")
								RunData.run_won = not _is_run_lost
								var _error = get_tree().change_scene("res://ui/menus/run/end_run.tscn")
				else :
								DebugService.log_data("process consumables and upgrades...")
								MusicManager.tween( - 8)
								if _consumables_to_process.size() > 0:
												for consumable in _consumables_to_process:
																if consumable == ItemService.rainbow_box:
																				_rainbow_box_ui.prep()
																				yield (_rainbow_box_ui, "item_box_processed")
																else :
																				var fixed_tier = - 1
																				if consumable.my_id == "consumable_legendary_item_box":
																								fixed_tier = Tier.LEGENDARY
																				var item_data = ItemService.process_item_box(RunData.current_wave, consumable, fixed_tier)
																				_item_box_ui.set_item_data(item_data)
																				yield (_item_box_ui, "item_box_processed")

																_ui_consumables_to_process.remove_element(consumable)

								if _upgrades_to_process.size() > 0:
												for upgrade_to_process in _upgrades_to_process:
																_upgrades_ui.show_upgrade_options(upgrade_to_process)
																yield (_upgrades_ui, "upgrade_selected")
																_ui_upgrades_to_process.remove_element(upgrade_to_process)

								DebugService.log_data("display challenge ui...")
								if _is_chal_ui_displayed:
												yield (_challenge_completed_ui, "finished")

								var _error = get_tree().change_scene("res://ui/menus/shop/shop.tscn")


func on_focus_lost()->void :
				if _end_wave_timer_timedout:
								if _item_box_ui.visible:
												_item_box_ui.focus()
								elif _upgrades_ui.visible:
												_upgrades_ui.focus()


func on_upgrade_selected(upgrade_data:UpgradeData)->void :
				RunData.apply_item_effects(upgrade_data)


func on_item_box_take_button_pressed(item_data:ItemParentData)->void :
				RunData.add_item(item_data)


func on_item_box_discard_button_pressed(item_data:ItemParentData)->void :
				RunData.add_gold(ItemService.get_recycling_value(RunData.current_wave, item_data.value))


func _on_PauseMenu_unpaused()->void :
				on_focus_lost()


func _on_WaveTimer_timeout()->void :

				DebugService.log_run_info(_upgrades_to_process, _consumables_to_process)

				var is_last_wave = RunData.current_wave == ZoneService.get_zone_data(RunData.current_zone).waves_data.size()

				ProgressData.update_mouse_cursor(true)

				if not _is_run_lost and is_last_wave:
								var character_chal_name = "chal_" + RunData.current_character.name.to_lower().replace("character_", "")
								ChallengeService.complete_challenge(character_chal_name)
								ProgressData.reset_run_state()

				ChallengeService.check_counted_challenges()

				if RunData.effects["stats_end_of_wave"].size() > 0:
								for stat_end_of_wave in RunData.effects["stats_end_of_wave"]:
												RunData.add_stat(stat_end_of_wave[0], stat_end_of_wave[1])

				if RunData.effects["convert_stats_end_of_wave"].size() > 0:
								for stat_to_convert in RunData.effects["convert_stats_end_of_wave"]:

												var pct = stat_to_convert.pct_converted / 100.0
												var stat_to_remove = stat_to_convert.key
												var stat_to_add = stat_to_convert.to_stat

												var stat_to_remove_value = RunData.gold if stat_to_remove == "materials" else RunData.get_stat(stat_to_remove) as int
												var nb_chunks_stat_removed = max(0, floor((stat_to_remove_value * pct) / stat_to_convert.value))

												if nb_chunks_stat_removed == 0:
																break

												var nb_stat_removed = nb_chunks_stat_removed * stat_to_convert.value
												var nb_stat_added = stat_to_convert.to_value * nb_chunks_stat_removed

												if stat_to_remove == "materials":
																RunData.remove_gold(nb_stat_removed)
												else :
																RunData.remove_stat(stat_to_remove, nb_stat_removed)

												if stat_to_add == "materials":
																RunData.add_gold(nb_stat_added)
												else :
																RunData.add_stat(stat_to_add, nb_stat_added)

				manage_harvesting()
				DebugService.log_data("start clean_up_room...")
				clean_up_room(is_last_wave, false)

				if is_last_wave:
								_end_wave_timer.wait_time = 3
								_ui_dim_screen.dim()
								SoundManager.play(Utils.get_rand_element(run_won_sounds), - 5, 0, true)

				_end_wave_timer.start()
				TempStats.reset()
				InputService.hide_mouse = true


func manage_harvesting()->void :

				var elite_end_wave_bonus = 0

				if Utils.get_stat("stat_harvesting") != 0 or RunData.effects["pacifist"] != 0 or elite_end_wave_bonus != 0 or _elite_killed_bonus != 0:
								var pacifist_bonus = round((_entity_spawner.get_all_enemies().size() + _entity_spawner.enemies_removed_for_perf) * (RunData.effects["pacifist"] / 100.0))

								if _is_horde_wave:
												pacifist_bonus = (pacifist_bonus / 2) as int

								var val = Utils.get_stat("stat_harvesting") + pacifist_bonus + _elite_killed_bonus + elite_end_wave_bonus

								RunData.add_gold(val)
								RunData.add_xp(val)

								_floating_text_manager.on_harvested(val)

								if Utils.get_stat("stat_harvesting") > 0:
												_harvesting_timer.start()


func _on_FiveSecondsTimer_timeout()->void :
				if _end_wave_timer.is_stopped() and RunData.effects["temp_stats_stacking"].size() > 0:
								for temp_stat_stacked in RunData.effects["temp_stats_stacking"]:
												TempStats.add_stat(temp_stat_stacked[0], temp_stat_stacked[1])


func _on_UIBonusGold_mouse_entered()->void :
				if _cleaning_up:
								_info_popup.display(_ui_bonus_gold, Text.text("INFO_BONUS_GOLD", [str(RunData.bonus_gold)]))


func _on_UIBonusGold_mouse_exited()->void :
				_info_popup.hide()


func _on_EntitySpawner_player_spawned(player:Player)->void :
				player.get_remote_transform().remote_path = _camera.get_path()
				player.current_stats.health = max(1, player.max_stats.health * (RunData.effects["hp_start_wave"] / 100.0)) as int

				if RunData.effects["hp_start_next_wave"] != 100:
								player.current_stats.health = max(1, player.max_stats.health * (RunData.effects["hp_start_next_wave"] / 100.0)) as int
								player.on_health_updated(player.current_stats.health, player.max_stats.health)
								RunData.effects["hp_start_next_wave"] = 100

				player.check_hp_regen()
				_damage_vignette.update_from_hp(player.current_stats.health, player.max_stats.health)
				_life_bar.update_value(player.current_stats.health, player.max_stats.health)

				if ProgressData.settings.hp_bar_on_character:
								player.life_bar.update_value(player.current_stats.health, player.max_stats.health)
								var _error_hp_lifebar = player.connect("health_updated", player, "on_health_updated")

				set_life_label(player.current_stats.health, player.max_stats.health)
				_xp_bar.update_value(RunData.current_xp, RunData.get_next_level_xp_needed())
				var _error_hp_vignette = player.connect("health_updated", _damage_vignette, "update_from_hp")
				var _error_hp_lifebar = player.connect("health_updated", _life_bar, "update_value")
				var _error_hp_text = player.connect("healed", _floating_text_manager, "_on_player_healed")
				var _error_hp = player.connect("health_updated", self, "set_life_label")
				var _error_died = player.connect("died", self, "_on_player_died")
				var _error_took_damage = player.connect("took_damage", _screenshaker, "_on_player_took_damage")
				var _error_healing_effect = RunData.connect("healing_effect", player, "on_healing_effect")
				var _error_lifesteal_effect = RunData.connect("lifesteal_effect", player, "on_lifesteal_effect")
				connect_visual_effects(player)
				_player = player
				TempStats.player = player
				_floating_text_manager.player = player


func _on_EntitySpawner_enemy_spawned(enemy:Enemy)->void :
				var _error_died = enemy.connect("died", self, "_on_enemy_died")
				var _error_took_damage = enemy.connect("took_damage", _screenshaker, "_on_unit_took_damage")
				var _error_stats_boost = enemy.connect("stats_boosted", _effects_manager, "on_enemy_stats_boost")
				var _error_heal = enemy.connect("healed", _effects_manager, "on_enemy_healed")
				var _error_speed_removed = enemy.connect("speed_removed", _effects_manager, "on_enemy_speed_removed")
				var _error_state_changed = enemy.connect("state_changed", _floating_text_manager, "on_enemy_state_changed")
				connect_visual_effects(enemy)


func _on_EntitySpawner_neutral_spawned(neutral:Neutral)->void :
				var _error_died = neutral.connect("died", self, "_on_neutral_died")
				var _error_took_damage = neutral.connect("took_damage", _screenshaker, "_on_unit_took_damage")
				connect_visual_effects(neutral)


func _on_HarvestingTimer_timeout()->void :
				var val = ceil(Utils.get_stat("stat_harvesting") * (RunData.effects["harvesting_growth"] / 100.0))

				if val > 0:
								RunData.add_stat("stat_harvesting", val)


func on_gold_changed(gold:int)->void :
				if _update_stats_on_gold_changed:
								if (gold / 30.0) as int != _last_gold_amount_used_to_reload_stats:
												reload_stats()
												_last_gold_amount_used_to_reload_stats = (gold / 30.0) as int


func on_chal_popup()->void :
				_is_chal_ui_displayed = true


func on_chal_popout()->void :
				_is_chal_ui_displayed = false
