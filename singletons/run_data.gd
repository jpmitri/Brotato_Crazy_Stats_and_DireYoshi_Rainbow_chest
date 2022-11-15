extends Node

signal levelled_up
signal gold_changed(new_value)
signal bonus_gold_changed(new_value)
signal xp_added(current_xp, max_xp)
signal stat_added(stat_name, value)
signal stat_removed(stat_name, value)

signal lifesteal_effect(value)
signal healing_effect(value)

export (Array, Resource) var backgrounds = []
export (Array, Color) var background_colors = []

var effect_keys_full_serialization = [
				"burn_chance", "structures", "explode_on_hit", "explode_on_death", "convert_stats_end_of_wave"
]

var effect_keys_with_weapon_stats = [
				"projectiles_on_death", "alien_eyes"
]

var current_run_accessibility_settings:Dictionary

var resumed_from_state: = false
var nb_of_waves: = 20

var elites_spawn: = []
var current_zone: = 0
var current_level: = 0
var current_xp: = 0.0
var max_weapons:int
var current_wave:int
var gold:int
var bonus_gold:int
var weapons:Array
var items:Array
var appearances_displayed:Array
var run_won:bool
var effects:Dictionary
var challenges_completed_this_run: = []
var reload_music = true
var current_character:CharacterData
var starting_weapon:WeaponData
var active_set_effects: = []
var active_sets = {}
var unique_effects: = []
var additional_weapon_effects: = []
var locked_shop_items = []
var current_background = null

var difficulty_unlocked = - 1
var max_endless_wave_record_beaten = - 1
var is_endless_run = false

var chal_hoarder_value = 0
var chal_hoarder_completed = false


func _ready()->void :
				chal_hoarder_value = ChallengeService.get_chal("chal_hoarder").value

				if DebugService.unlock_all_challenges:
								for chal in ChallengeService.challenges:
												ChallengeService.complete_challenge(chal.my_id)

				if DebugService.reinitialize_steam_data:
								print("steam reset data")
								


func reset(restart:bool = false)->void :

				current_run_accessibility_settings = ProgressData.settings.enemy_scaling.duplicate()

				reset_background()

				active_sets = {}
				active_set_effects = []
				unique_effects = []
				additional_weapon_effects = []
				weapons = []
				items = []

				effects = init_effects()
				init_appearances_displayed()

				if not restart:
								starting_weapon = null
								current_character = null
								is_endless_run = false
				else :
								add_character(current_character)

								if starting_weapon:
												add_weapon(starting_weapon, true)

								add_starting_items()

								var difficulty = ItemService.get_element(ItemService.difficulties, "", get_current_difficulty())

								for effect in difficulty.effects:
												effect.apply()

				DebugService.debug_items_added = false

				elites_spawn = []
				init_elites_spawn()

				current_zone = 0
				current_level = 0
				current_xp = 0
				max_weapons = 6
				gold = DebugService.starting_gold
				bonus_gold = 0
				challenges_completed_this_run = []
				run_won = false
				current_wave = DebugService.starting_wave
				locked_shop_items = []
				difficulty_unlocked = - 1
				max_endless_wave_record_beaten = - 1

				TempStats.reset()
				LinkedStats.reset()
				ItemService.init_unlocked_pool()

				InputService.hide_mouse = true





func init_elites_spawn()->void :
				var diff = get_current_difficulty()
				var nb_elites = 0
				var possible_elites = ItemService.elites.duplicate()

				if diff < 2:
								return 
				elif diff < 4:
								nb_elites = 1
				else :
								nb_elites = 3

				var wave = Utils.get_random_int(11, 12)

				for i in nb_elites:

								var type = EliteType.HORDE if randf() <= 0.4 else EliteType.ELITE

								if i == 1:
												wave = Utils.get_random_int(14, 15)
								elif i == 2:
												wave = Utils.get_random_int(17, 18)
												type = EliteType.ELITE

								var elite_id = Utils.get_rand_element(possible_elites).my_id if type == EliteType.ELITE else ""

								for elite in possible_elites:
												if elite.my_id == elite_id:
																possible_elites.erase(elite)
																break

								elites_spawn.push_back([wave, type, elite_id])


func is_elite_wave(type:int = - 1)->bool:
				var is_elite = false

				for elite_spawn in elites_spawn:
								if elite_spawn[0] == current_wave and (type == - 1 or elite_spawn[1] == type):
												is_elite = true
												break

				return is_elite


func is_in_last_waves()->bool:
				return current_wave >= nb_of_waves - 1


func init_appearances_displayed()->void :
				appearances_displayed = []


func remove_bonus_gold(value:int)->void :
				set_bonus_gold(bonus_gold - value)


func add_bonus_gold(value:int)->void :
				set_bonus_gold(bonus_gold + value)


func set_bonus_gold(value:int)->void :
				bonus_gold = max(0, value) as int
				emit_signal("bonus_gold_changed", bonus_gold)


func add_xp(value:int)->void :
				current_xp += value * (1 + (RunData.effects["xp_gain"] / 100.0))
				var next_level_xp = get_next_level_xp_needed()
				emit_signal("xp_added", current_xp, next_level_xp)

				while current_xp >= next_level_xp:
								level_up()
								emit_signal("xp_added", current_xp, next_level_xp)
								next_level_xp = get_next_level_xp_needed()


func get_next_level_xp_needed()->int:
				return get_xp_needed(current_level + 1)


func get_xp_needed(level:int)->int:
				return (pow(3 + level, 2)) as int


func level_up()->void :
				current_xp = max(0, current_xp - get_next_level_xp_needed())
				current_level += 1
				emit_signal("levelled_up")


func add_gold(value:int)->void :
				gold += value
				emit_signal("gold_changed", gold)

				if LinkedStats.update_on_gold_chance:
								LinkedStats.reset()

				if gold >= chal_hoarder_value and not chal_hoarder_completed:
								chal_hoarder_completed = true
								ChallengeService.complete_challenge("chal_hoarder")


func remove_gold(value:int)->void :
				gold = max(0, gold - value)
				emit_signal("gold_changed", gold)

				if LinkedStats.update_on_gold_chance:
								LinkedStats.reset()


func add_character(character:CharacterData)->void :
				current_character = character
				add_item(character)


func add_item(item:ItemData)->void :
				items.push_back(item)
				apply_item_effects(item)
				add_item_displayed(item)
				update_unique_bonuses()
				update_additional_weapon_bonuses()
				LinkedStats.reset()


func remove_item(item:ItemData)->void :
				items.erase(item)
				unapply_item_effects(item)
				remove_item_displayed(item)
				update_unique_bonuses()
				update_additional_weapon_bonuses()
				LinkedStats.reset()


func add_weapon(weapon:WeaponData, is_starting:bool = false)->void :
				if is_starting:
								starting_weapon = weapon

				weapons.push_back(weapon)
				apply_item_effects(weapon)
				update_sets()
				update_unique_bonuses()
				update_additional_weapon_bonuses()
				LinkedStats.reset()


func remove_weapon(weapon:WeaponData)->void :
				for current_weapon in weapons:
								if current_weapon.my_id == weapon.my_id:
												weapons.erase(current_weapon)
												break
				unapply_item_effects(weapon)
				update_sets()
				update_unique_bonuses()
				update_additional_weapon_bonuses()
				LinkedStats.reset()


func update_sets()->void :

				for effect in active_set_effects:
								effect[1].unapply()

				active_set_effects = []
				active_sets = {}

				for weapon in weapons:
								for weapon_class in weapon.weapon_classes:
												if active_sets.has(weapon_class):
																active_sets[weapon_class] += 1
												else :
																active_sets[weapon_class] = 1

				for key in active_sets:
								if active_sets[key] >= 2:
												var set = ItemService.get_set(key)
												var set_effects = set.set_bonuses[min(active_sets[key] - 2, set.set_bonuses.size() - 1)]

												for effect in set_effects:
																effect.apply()
																active_set_effects.push_back([key, effect])


func update_unique_bonuses()->void :
				for effect in unique_effects:
								effects[effect[0]] -= effect[1]

				unique_effects = []
				var nb_weapons = {}

				for weapon in weapons:
								if nb_weapons.has(weapon.weapon_id):
												nb_weapons[weapon.weapon_id] += 1
								else :
												nb_weapons[weapon.weapon_id] = 1

				var nb_bonus = 0

				for nb in nb_weapons.values():
								if nb <= 1:
												nb_bonus += 1

				for i in nb_bonus:
								for effect in effects["unique_weapon_effects"]:
												effects[effect[0]] += effect[1]
												unique_effects.push_back(effect)


func update_additional_weapon_bonuses()->void :
				for effect in additional_weapon_effects:
								effects[effect[0]] -= effect[1]

				additional_weapon_effects = []

				for weapon in weapons:
								for effect in effects["additional_weapon_effects"]:
												effects[effect[0]] += effect[1]
												additional_weapon_effects.push_back(effect)


func apply_item_effects(item_data:ItemParentData)->void :
				for effect in item_data.effects:
								effect.apply()
				ChallengeService.check_stat_challenges()


func unapply_item_effects(item_data:ItemParentData)->void :
				for effect in item_data.effects:
								effect.unapply()
				ChallengeService.check_stat_challenges()


func add_item_displayed(new_item:ItemData)->void :
				for new_appearance in new_item.item_appearances:

								if new_appearance == null:
												print("appearance is null : " + str(new_item.name))
												continue

								var display_appearance: = true

								if new_appearance.position != 0:
												var appearance_to_erase = null

												for appearance in appearances_displayed:
																if appearance.position != new_appearance.position or new_appearance.position == 0:
																				continue

																if new_appearance.display_priority >= appearance.display_priority:
																				appearance_to_erase = appearance
																else :
																				display_appearance = false

																break

												if appearance_to_erase:
																appearances_displayed.erase(appearance_to_erase)

								if display_appearance:
												appearances_displayed.push_back(new_appearance)

								appearances_displayed.sort_custom(Sorter, "sort_depth_ascending")


func remove_item_displayed(_item_to_remove:ItemData)->void :
				init_appearances_displayed()

				for item in items:
								add_item_displayed(item)


func has_weapon_slot_available(weapon_type:int = - 1)->bool:

				if weapon_type == - 1:
								return weapons.size() < effects["weapon_slot"]
				else :
								var nb = 0

								for weapon in weapons:
												if weapon.type == weapon_type:
																nb += 1

								var max_slots = effects["max_melee_weapons"] if weapon_type == WeaponType.MELEE else effects["max_ranged_weapons"]

								return weapons.size() < effects["weapon_slot"] and nb < min(effects["weapon_slot"], max_slots)


func has_max_weapons()->bool:
				return weapons.size() <= max_weapons + RunData.effects["weapon_slot"]


func manage_life_steal(weapon_stats:WeaponStats)->void :
				if randf() < weapon_stats.lifesteal:
								emit_signal("lifesteal_effect", 1)


func get_stat(stat_name:String)->float:
				return effects[stat_name.to_lower()] * get_stat_gain(stat_name)


func get_stat_gain(stat_name:String)->float:

				if not effects.has("gain_" + stat_name.to_lower()):
								return 1.0

				return (1 + (effects["gain_" + stat_name.to_lower()] / 100.0))


func can_combine(weapon_data:WeaponData)->bool:
				var nb_duplicates = 0

				for weapon in weapons:
								if weapon.my_id == weapon_data.my_id:
												nb_duplicates += 1

				return nb_duplicates >= 2 and weapon_data.upgrades_into != null and weapon_data.tier < RunData.effects["max_weapon_tier"]


func get_dmg(value:int)->int:
				var percent_dmg_bonus = (1 + (Utils.get_stat("stat_percent_damage") / 100.0))
				return max(1, (value * percent_dmg_bonus)) as int


func get_weapon_min_tier()->int:
				var min_tier = Tier.LEGENDARY

				for weapon in weapons:
								if weapon.tier < min_tier:
												min_tier = weapon.tier

				return min_tier


func sort_appearances()->void :
				appearances_displayed.sort_custom(Sorter, "sort_depth_ascending")


func get_armor_coef(armor:int)->float:
				var percent_dmg_taken = 10.0 / (10.0 + (abs(armor) / 1.5))




	
				if armor < 0:
								percent_dmg_taken = (1.0 - percent_dmg_taken) + 1.0

				return percent_dmg_taken


func get_hp_regeneration_timer(hp_regen:int)->float:





				if hp_regen <= 0:
								return 99.0

				var timer_duration = 5.0 / (1.0 + (abs(hp_regen - 1) / 2.25))

				return timer_duration


func reset_background()->void :
				if ProgressData.settings.background == 0:
								current_background = Utils.get_rand_element(backgrounds)
				else :
								current_background = RunData.backgrounds[ProgressData.settings.background - 1]


func get_background()->Resource:
				return current_background


func get_background_gradient_color()->Resource:
				return Utils.get_rand_element(background_colors)


func add_stat(stat_name:String, value:int)->void :
				effects[stat_name] += value
				emit_signal("stat_added", stat_name, value)
				ChallengeService.check_stat_challenges()


func remove_stat(stat_name:String, value:int)->void :
				effects[stat_name] -= value
				emit_signal("stat_removed", stat_name, value)
				ChallengeService.check_stat_challenges()


func get_current_difficulty()->int:

				if current_character == null:
								return - 1

				var diff_info = ProgressData.get_character_difficulty_info(current_character.my_id, current_zone)
				return diff_info.difficulty_selected_value


func get_currency()->int:
				return get_stat("stat_max_hp") as int if effects["hp_shop"] else gold


func remove_currency(value:int)->void :
				if effects["hp_shop"]:
								remove_stat("stat_max_hp", value)
				else :
								remove_gold(value)


func apply_weapon_selection_back()->void :
				weapons = []
				items = []
				effects = init_effects()
				Utils.last_elt_selected = current_character
				current_character = null
				init_appearances_displayed()
				var _error = get_tree().change_scene(MenuData.character_selection_scene)


func add_starting_items()->void :
				if effects["starting_item"].size() > 0:
								for item in effects["starting_item"]:
												if item is ItemData:
																add_item(item)
												elif item is WeaponData:
																add_weapon(item)


func get_state(
								reset:bool = false, 
								shop_items:Array = [], 
								reroll_price:int = 0, 
								last_reroll_price:int = 0, 
								initial_free_rerolls:int = 0, 
								free_rerolls:int = 0
				)->Dictionary:

				if reset:
								return {
												"has_run_state":false
								}

				return {
								"has_run_state":true, 
								"enemy_scaling":current_run_accessibility_settings.duplicate(), 
								"nb_of_waves":nb_of_waves, 
								"current_zone":current_zone, 
								"current_level":current_level, 
								"current_xp":current_xp, 
								"max_weapons":max_weapons, 
								"current_wave":current_wave, 
								"gold":gold, 
								"bonus_gold":bonus_gold, 
								"elites_spawn":elites_spawn, 

								"weapons":weapons.duplicate(), 
								"items":items.duplicate(), 
								"effects":effects.duplicate(), 
								"challenges_completed_this_run":challenges_completed_this_run, 
								"current_character":current_character, 
								"starting_weapon":starting_weapon, 
								"active_set_effects":active_set_effects.duplicate(), 
								"unique_effects":unique_effects.duplicate(), 
								"additional_weapon_effects":additional_weapon_effects.duplicate(), 
								"locked_shop_items":locked_shop_items, 
								"current_background":current_background, 
								"appearances_displayed":appearances_displayed.duplicate(), 

								"active_sets":active_sets.duplicate(), 
								"difficulty_unlocked":difficulty_unlocked, 
								"max_endless_wave_record_beaten":max_endless_wave_record_beaten, 
								"is_endless_run":is_endless_run, 
								"chal_hoarder_value":chal_hoarder_value, 
								"chal_hoarder_completed":chal_hoarder_completed, 

								"shop_items":shop_items, 
								"reroll_price":reroll_price, 
								"last_reroll_price":last_reroll_price, 
								"initial_free_rerolls":initial_free_rerolls, 
								"free_rerolls":free_rerolls
				}


func resume_from_state(state:Dictionary)->void :

				resumed_from_state = true

				if state.has("enemy_scaling"):
								current_run_accessibility_settings = state.enemy_scaling
				else :
								current_run_accessibility_settings = ProgressData.settings.enemy_scaling.duplicate()

				nb_of_waves = state.nb_of_waves
				current_zone = state.current_zone
				current_level = state.current_level
				current_xp = state.current_xp
				max_weapons = state.max_weapons
				current_wave = state.current_wave
				gold = state.gold
				bonus_gold = state.bonus_gold

				if state.has("elites_spawn"):
								elites_spawn = state.elites_spawn

				weapons = state.weapons
				items = state.items
				effects = state.effects
				challenges_completed_this_run = state.challenges_completed_this_run
				current_character = state.current_character
				starting_weapon = state.starting_weapon
				active_set_effects = state.active_set_effects
				unique_effects = state.unique_effects
				additional_weapon_effects = state.additional_weapon_effects
				locked_shop_items = state.locked_shop_items
				current_background = state.current_background
				appearances_displayed = state.appearances_displayed

				active_sets = state.active_sets
				difficulty_unlocked = state.difficulty_unlocked
				max_endless_wave_record_beaten = state.max_endless_wave_record_beaten
				is_endless_run = state.is_endless_run
				chal_hoarder_value = state.chal_hoarder_value
				chal_hoarder_completed = state.chal_hoarder_completed

				LinkedStats.reset()


func init_effects()->Dictionary:
				return {
								"stat_max_hp":10, 
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
								"gain_stat_max_hp":0, 
								"gain_stat_armor":0, 
								"gain_stat_crit_chance":0, 
								"gain_stat_luck":0, 
								"gain_stat_attack_speed":0, 
								"gain_stat_elemental_damage":0, 
								"gain_stat_hp_regeneration":0, 
								"gain_stat_lifesteal":0, 
								"gain_stat_melee_damage":0, 
								"gain_stat_percent_damage":0, 
								"gain_stat_dodge":0, 
								"gain_stat_engineering":0, 
								"gain_stat_range":0, 
								"gain_stat_ranged_damage":0, 
								"gain_stat_speed":0, 
								"gain_stat_harvesting":0, 
								"weapon_slot":6, 
								"xp_gain":0, 
								"items_price":0, 
								"number_of_enemies":0, 
								"no_melee_weapons":0, 
								"no_ranged_weapons":0, 
								"consumable_heal":0, 
								"burning_cooldown_reduction":0, 
								"burning_spread":0, 
								"piercing":0, 
								"piercing_damage":0, 
								"hp_start_wave":100, 
								"hp_start_next_wave":100, 
								"no_min_range":0, 
								"pacifist":0, 
								"pickup_range":0, 
								"chance_double_gold":0, 
								"bounce":0, 
								"bounce_damage":0, 
								"heal_when_pickup_gold":0, 
								"enemy_speed":0, 
								"gain_pct_gold_start_wave":0, 
								"item_box_gold":0, 
								"knockback":0, 
								"torture":0, 
								"recycling_gains":0, 
								"one_shot_trees":0, 
								"hp_cap":999999, 
								"lose_hp_per_second":0, 
								"cant_stop_moving":0, 
								"map_size":0, 
								"max_ranged_weapons":999, 
								"max_melee_weapons":999, 
								"gambler":0, 
								"dodge_cap":60, 
								"group_structures":0, 
								"double_hp_regen":0, 
								"can_attack_while_moving":1, 
								"trees":0, 
								"trees_start_wave":0, 
								"min_weapon_tier":0, 
								"max_weapon_tier":99, 
								"hp_shop":0, 
								"gold_drops":100, 
								"harvesting_growth":5, 
								"free_rerolls":0, 
								"instant_gold_attracting":0, 
								"leave_burning":0, 
								"inflation":0, 
								"enemy_strength":0, 
								"boss_strength":0, 
								"double_boss":0, 
								"diff_gold_drops":0, 
								"explosion_size":0, 
								"explosion_damage":0, 
								"gain_explosion_damage":0, 
								"gain_piercing_damage":0, 
								"gain_bounce_damage":0, 
								"neutral_gold_drops":0, 
								"enemy_gold_drops":0, 
								"wandering_bots":0, 
								"dmg_when_pickup_gold_from_luck":[0, 0], 
								"dmg_when_death_from_luck":[0, 0], 
								"remove_speed":[0, 0], 
								"starting_item":[], 
								"projectiles_on_death":[], 
								"burn_chance":BurningData.new(), 
								"weapon_class_bonus":[], 
								"weapon_bonus":[], 
								"unique_weapon_effects":[], 
								"additional_weapon_effects":[], 
								"gold_on_crit_kill":[], 
								"temp_stats_while_not_moving":[], 
								"temp_stats_on_hit":[], 
								"temp_stats_stacking":[], 
								"stats_end_of_wave":[], 
								"stat_links":[], 
								"structures":[], 
								"explode_on_hit":[], 
								"convert_stats_end_of_wave":[], 
								"explode_on_death":[], 
								"alien_eyes":[], 
				}
