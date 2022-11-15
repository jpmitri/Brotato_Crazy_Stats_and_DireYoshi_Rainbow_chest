class_name Player
extends Unit

signal healed(unit, value)

const MIN_IFRAMES = 0.2
const MAX_IFRAMES = 0.4

export (Array, Resource) var hp_regen_sounds
export (Array, Resource) var step_sounds
export (Array, Resource) var alien_sounds

var not_moving_bonuses_applied = false
var current_weapons: = []

var consumables_in_range: = []

var _sprites: = []
var _item_appearances: = []

var _explode_on_hit_stats = null

var _alien_eyes_timer:Timer
var _total_healed_this_wave = 0
var _chal_medicine_value = 0
var _chal_medicine_completed = false

var _hp_regen_val = 1

onready  var _lifesteal_timer = $LifestealTimer
onready  var _invincibility_timer = $InvincibilityTimer
onready  var _legs = $Animation / Legs
onready  var _shadow: = $Animation / Shadow as Sprite
onready  var _item_attract_area: = $ItemAttractArea as Area2D
onready  var _item_pickup_area: = $ItemPickupArea as Area2D

onready  var _weapons_container = $Weapons

onready  var life_bar:TextureProgress = $LifeBar
onready  var highlight:Sprite = $Animation / Highlight

onready  var _running_smoke:Particles2D = $RunningSmoke
onready  var _health_regen_timer:Timer = $HealthRegenTimer
onready  var _lose_health_timer:Timer = $LoseHealthTimer


func _ready()->void :
				_chal_medicine_value = ChallengeService.get_chal("chal_medicine").value
				
				_running_smoke.stop()
				
				if DebugService.invulnerable:
								disable_hurtbox()
				
				_health_regen_timer.wait_time = RunData.get_hp_regeneration_timer(Utils.get_stat("stat_hp_regeneration"))
				
				if RunData.effects["torture"] > 0:
								_health_regen_timer.wait_time = 1
				
				if RunData.effects["double_hp_regen"] > 0:
								_hp_regen_val = 2
				
				if RunData.effects["explode_on_hit"].size() > 0:
								init_exploding_stats()
				
				if RunData.effects["lose_hp_per_second"] > 0:
								_lose_health_timer.start()
				
				if RunData.effects["alien_eyes"].size() > 0:
								_alien_eyes_timer = Timer.new()
								_alien_eyes_timer.wait_time = AlienEyesEffect.ALIEN_EYES_CD
								var _alien_eyes = _alien_eyes_timer.connect("timeout", self, "on_alien_eyes_timeout")
								add_child(_alien_eyes_timer)
								_alien_eyes_timer.start()
				
				if ProgressData.settings.character_highlighting:
								highlight.show()


func update_animation(movement:Vector2)->void :
				
				if not not_moving_bonuses_applied and RunData.effects["temp_stats_while_not_moving"].size() > 0 and movement.x == 0 and movement.y == 0:
								not_moving_bonuses_applied = true
								for temp_stat_while_not_moving in RunData.effects["temp_stats_while_not_moving"]:
												TempStats.add_stat(temp_stat_while_not_moving[0], temp_stat_while_not_moving[1])
								reset_weapons_cd()
				elif not_moving_bonuses_applied and (movement.x != 0 or movement.y != 0):
								for temp_stat_while_not_moving in RunData.effects["temp_stats_while_not_moving"]:
												TempStats.remove_stat(temp_stat_while_not_moving[0], temp_stat_while_not_moving[1])
								not_moving_bonuses_applied = false
								reset_weapons_cd()
				
				if movement.x > 0:
								_shadow.scale.x = abs(_shadow.scale.x)
								for sprite in _sprites:
												sprite.scale.x = abs(sprite.scale.x)
				elif movement.x < 0:
								_shadow.scale.x = - abs(_shadow.scale.x)
								for sprite in _sprites:
												sprite.scale.x = - abs(sprite.scale.x)

				if _animation_player.current_animation == "idle" and movement != Vector2.ZERO:
								_animation_player.play("move")
								_running_smoke.emit()
				elif _animation_player.current_animation == "move" and movement == Vector2.ZERO:
								_animation_player.play("idle")
								_running_smoke.stop()


func reset_weapons_cd()->void :
				for weapon in current_weapons:
								if is_instance_valid(weapon):
												weapon._current_cooldown = min(weapon._current_cooldown, weapon.current_stats.cooldown)


func disable_hurtbox()->void :
				_hurtbox.disable()


func enable_hurtbox()->void :
				_hurtbox.enable()


func disable_gold_pickup()->void :
				_item_attract_area.set_collision_mask_bit(6, false)
				_item_pickup_area.set_collision_mask_bit(6, false)


func get_all_possible_targets()->Array:
				return _entity_spawner_ref.enemies


func get_nb_weapons()->int:
				return current_weapons.size()


func get_remote_transform()->RemoteTransform2D:
				return $RemoteTransform2D as RemoteTransform2D


func get_dmg_value(dmg_value:int, armor_applied:bool = true)->int:
				var armor_coef = RunData.get_armor_coef(current_stats.armor)
				return max(1, round(dmg_value * armor_coef)) as int if armor_applied else dmg_value


func apply_items_effects()->void :
				
				var animation_node = $Animation
	

				for weapon in RunData.weapons:
								add_weapon(weapon)
				
				RunData.sort_appearances()
				var appearances_behind = []
				
				
				for appearance in RunData.appearances_displayed:
								var item_sprite = Sprite.new()
								item_sprite.texture = appearance.sprite
								animation_node.add_child(item_sprite)
								
								if appearance.depth < - 1:
												appearances_behind.push_back(item_sprite)
								
								_item_appearances.push_back(item_sprite)
				
				var popped = appearances_behind.pop_back()
				
				while popped != null:
								animation_node.move_child(popped, 0)
								popped = appearances_behind.pop_back()
				
				_sprites = animation_node.get_children()
				
				
				update_player_stats()
				
				current_stats.copy(max_stats)


func update_player_stats()->void :
				
				var old_max_health = max_stats.health
				
				max_stats.health = clamp(Utils.get_stat("stat_max_hp"), 1, RunData.effects["hp_cap"]) as int
				max_stats.speed = stats.speed * (1 + (Utils.get_stat("stat_speed") / 100.0)) as float
				max_stats.armor = Utils.get_stat("stat_armor") as int
				max_stats.dodge = min(RunData.effects["dodge_cap"] / 100.0, Utils.get_stat("stat_dodge") / 100.0)
				
				if RunData.effects["explode_on_hit"].size() > 0:
								init_exploding_stats()
				
				current_stats.copy(max_stats, true)
				
				if old_max_health != max_stats.health:
								emit_signal("health_updated", current_stats.health, max_stats.health)
								check_hp_regen()


func add_weapon(weapon:WeaponData)->void :
				var instance = weapon.scene.instance()
				
				instance.stats = weapon.stats.duplicate()
				instance.weapon_id = weapon.weapon_id
				instance.tier = weapon.tier
				instance.weapon_classes = weapon.weapon_classes
				
				for effect in weapon.effects:
								instance.effects.push_back(effect.duplicate())
				
				_weapons_container.add_child(instance)
				instance.global_position = position
				current_weapons.push_back(instance)
				_weapons_container.update_weapons_positions(current_weapons)


func take_damage(value:int, hitbox:Hitbox = null, dodgeable:bool = true, armor_applied:bool = true, custom_sound:Resource = null, base_effect_scale:float = 1.0, bypass_invincibility:bool = false)->int:
				
				if hitbox and hitbox.is_healing:
								on_healing_effect(value)
				elif _invincibility_timer.is_stopped() or bypass_invincibility:
								var dmg_taken = .take_damage(value, hitbox, dodgeable, armor_applied, custom_sound, base_effect_scale)
								
								if dmg_taken > 0 and consumables_in_range.size() > 0:
												for cons in consumables_in_range:
																cons.attracted_by = self
								
								if dodgeable:
												disable_hurtbox()
												_invincibility_timer.start(get_iframes(dmg_taken))
								
								if dmg_taken > 0:
												if RunData.effects["explode_on_hit"].size() > 0:
																var effect = RunData.effects["explode_on_hit"][0]
																var stats = _explode_on_hit_stats
																WeaponService.explode(effect, global_position, stats.damage, stats.accuracy, stats.crit_chance, stats.crit_damage, stats.burning_data)
												
												if RunData.effects["temp_stats_on_hit"].size() > 0:
																for temp_stat_on_hit in RunData.effects["temp_stats_on_hit"]:
																				TempStats.add_stat(temp_stat_on_hit[0], temp_stat_on_hit[1])
												
												check_hp_regen()
								
								return dmg_taken
				
				return 0


func get_iframes(damage_taken:float)->float:
				var pct_dmg_taken = (damage_taken / max_stats.health)
				var iframes = clamp((pct_dmg_taken * MAX_IFRAMES) / 0.15, MIN_IFRAMES, MAX_IFRAMES)
				

				
				return iframes


func check_hp_regen()->void :
				if (RunData.effects["torture"] > 0 or Utils.get_stat("stat_hp_regeneration") > 0) and _health_regen_timer.is_stopped() and current_stats.health < max_stats.health and not cleaning_up:
								_health_regen_timer.start()


func play_step_sound()->void :
				SoundManager.play(Utils.get_rand_element(step_sounds), - 6, 0.1)


func die(knockback_vector:Vector2 = Vector2.ZERO, p_cleaning_up:bool = false)->void :
				.die(knockback_vector, p_cleaning_up)
				_weapons_container.queue_free()
				_legs.queue_free()
				_shadow.queue_free()
				_running_smoke.queue_free()
				
				for appearance in _item_appearances:
								appearance.queue_free()


func death_animation_finished()->void :
				pass


func clean_up()->void :
				if not dead:
								_running_smoke.call_deferred("stop")
								_animation_player.call_deferred("play", "idle")
				else :
								life_bar.hide()
								highlight.hide()
				_can_move = false
				_current_movement = Vector2.ZERO
				_health_regen_timer.call_deferred("stop")
				_lose_health_timer.call_deferred("stop")
				if _alien_eyes_timer:
								_alien_eyes_timer.call_deferred("stop")
				call_deferred("set_physics_process", false)
				disable_hurtbox()
				cleaning_up = true


func _on_HealthRegenTimer_timeout()->void :
				var base_val = RunData.effects["torture"] if RunData.effects["torture"] > 0 else _hp_regen_val
				var value = min(base_val, max_stats.health - current_stats.health)
				
				if value < 0:value = 0
				on_healing_effect(value, RunData.effects["torture"] > 0)
				
				if current_stats.health >= max_stats.health:
								_health_regen_timer.stop()


func on_lifesteal_effect(value:int)->void :
				if _lifesteal_timer.is_stopped():
								_lifesteal_timer.start()
								on_healing_effect(value)


func on_healing_effect(value:int, from_torture:bool = false)->void :
				
				var actual_value = min(value, max_stats.health - current_stats.health)
				var value_healed = heal(actual_value, from_torture)
				
				if value_healed > 0:
								SoundManager.play(Utils.get_rand_element(hp_regen_sounds), get_heal_db(), 0.1)
								emit_signal("health_updated", current_stats.health, max_stats.health)
								emit_signal("healed", self, actual_value)


func get_heal_db()->float:
				if _health_regen_timer.wait_time < 2.5:
								return - 10.0
				elif _health_regen_timer.wait_time < 1.0:
								return - 15.0
				else :
								return 0.0


func heal(value:int, is_from_torture:bool = false)->int:
				var value_healed = 0
				
				if dead:
								return value_healed
				
				if RunData.effects["torture"] <= 0 or is_from_torture:
								current_stats.health += value
								value_healed = value
				
				_total_healed_this_wave += value_healed
				
				if _total_healed_this_wave >= _chal_medicine_value and not _chal_medicine_completed:
								_chal_medicine_completed = true
								ChallengeService.complete_challenge("chal_medicine")
				
				return value_healed


func init_exploding_stats()->void :
				_explode_on_hit_stats = WeaponService.init_base_stats(RunData.effects["explode_on_hit"][0].stats, "", [], [ExplodingEffect.new()])


func on_health_updated(current_val:int, max_val:int)->void :
				if ProgressData.settings.hp_bar_on_character:
								if not life_bar.visible:
												life_bar.show()
								
								if current_val == max_val:
												life_bar.hide()
								
								life_bar.update_value(current_val, max_val)
				elif life_bar.visible:
								life_bar.hide()


func _on_InvincibilityTimer_timeout()->void :
				if not cleaning_up:
								enable_hurtbox()


func _on_LoseHealthTimer_timeout()->void :
				var _dmg_taken = take_damage(RunData.effects["lose_hp_per_second"], null, false, false, null, 1.0, true)


func on_alien_eyes_timeout()->void :
				var projectiles = []
				var alien_stats = WeaponService.init_ranged_stats(RunData.effects["alien_eyes"][0][1])
				
				SoundManager.play(Utils.get_rand_element(alien_sounds), 0, 0.1)
				
				for projectile in RunData.effects["alien_eyes"]:
								for i in projectile[0]:
												projectiles.push_back(projectile)
				
				for i in projectiles.size():
								var direction = (2 * PI / projectiles.size()) * i
								
								var _projectile = WeaponService.manage_special_spawn_projectile(
												self, 
												alien_stats, 
												projectiles[i][2], 
												_entity_spawner_ref, 
												direction
								)


func update_weapon_highlighting(value:int)->void :
				for weapon in current_weapons:
								weapon.update_highlighting(value)


func _on_ItemAttractArea_area_entered(area:Area2D)->void :
				var is_heal = area is Consumable
				
				if is_heal and current_stats.health >= max_stats.health:
								consumables_in_range.push_back(area)
				elif not is_heal or (is_heal and current_stats.health < max_stats.health):
								area.attracted_by = self


func _on_ItemPickupArea_area_entered(area:Area2D)->void :
				area.pickup()
				
				if consumables_in_range.has(area):
								consumables_in_range.erase(area)


func _on_ItemAttractArea_area_exited(area:Area2D)->void :
				var is_heal = area is Consumable
				
				if is_heal and consumables_in_range.has(area):
								consumables_in_range.erase(area)
