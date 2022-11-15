class_name Unit
extends Entity

signal speed_removed(enemy)
signal health_updated(current_health, max_health)
signal took_damage(unit, value, knockback_direction, knockback_amount, is_crit, is_miss, effect_scale, hit_type)

export (Array, Resource) var crit_sounds
export (Array, Resource) var hurt_sounds
export (Array, Resource) var burn_sounds
export (Array, Resource) var dodge_sounds
export (Resource) var stats
export (bool) var mirror_sprite_with_movement = true
export (bool) var always_play_hurt_sound = false

const MIN_DEATH_KNOCKBACK_AMOUNT: = 15.0

var current_stats:LiveStats = LiveStats.new()
var max_stats:LiveStats = LiveStats.new()

var can_drop_loot: = true
var bonus_speed:int = 0

var _speed_rand_value: = 0
var _knockback_vector: = Vector2.ZERO

var player_ref:Node2D
var _entity_spawner_ref:EntitySpawner
var _can_move:bool = true
var _current_movement:Vector2
var _move_locked: = false
var decaying_bonus_speed: = 0.0

var burning_particles = null
var _burning:BurningData

var _current_movement_behavior:MovementBehavior

onready  var _flash_timer: = $FlashTimer as Timer
onready  var _hurtbox: = $Hurtbox as Area2D
onready  var _movement_behavior: = $MovementBehavior
onready  var _burning_timer: = $BurningTimer as Timer
onready  var _burning_particles: = $BurningParticles
onready  var _sprite = $Animation / Sprite


func _ready()->void :
	_current_movement_behavior = _movement_behavior


func init(zone_min_pos:Vector2, zone_max_pos:Vector2, p_player_ref:Node2D = null, entity_spawner_ref:EntitySpawner = null)->void :
	
	_burning_timer.wait_time = max(0.1, _burning_timer.wait_time * (1.0 - (RunData.effects["burning_cooldown_reduction"] / 100.0)))
	
	player_ref = p_player_ref
	_entity_spawner_ref = entity_spawner_ref
	
	_movement_behavior.init(self)
	_speed_rand_value = rand_range( - stats.speed_randomization, stats.speed_randomization) as int
	
	.init(zone_min_pos, zone_max_pos)


func init_current_stats()->void :
	max_stats.copy_stats(stats)
	
	var str_factor = RunData.effects["enemy_strength"] / 100.0
	max_stats.health = round((stats.health + (stats.health_increase_each_wave * (RunData.current_wave - 1))) * (RunData.current_run_accessibility_settings.health + str_factor))
	
	current_stats.copy(max_stats)
	reset_stats()


func reset_stats(dmg_coef:float = 0.0, speed_coef:float = 0.0, armor_coef:float = 0.0)->void :
	var str_factor = RunData.effects["enemy_strength"] / 100.0
	var base_damage = (stats.damage + (stats.damage_increase_each_wave * (RunData.current_wave - 1))) * (1.0 + dmg_coef)
	var base_speed = (stats.speed + (stats.speed * (RunData.effects["enemy_speed"] / 100.0))) * (1.0 + speed_coef)
	var base_armor = (stats.armor + (stats.armor_increase_each_wave * (RunData.current_wave - 1))) * (1.0 + armor_coef)
	
	current_stats.damage = round(base_damage * (RunData.current_run_accessibility_settings.damage + str_factor))
	current_stats.speed = round(base_speed * RunData.current_run_accessibility_settings.speed)
	current_stats.armor = round(base_armor)
	
	max_stats.copy(current_stats, true)


func update_stats(hp_coef:float, damage_coef:float, speed_coef:float)->void :
	current_stats.health = max_stats.health * (1 + hp_coef)
	reset_stats(damage_coef, speed_coef)


func _physics_process(delta)->void :
	_current_movement = get_movement() if _can_move else Vector2.ZERO
	var move_input:Vector2 = get_move_input()
	var final_movement:Vector2 = move_input - get_knockback_value()
	
	_knockback_vector = _knockback_vector.linear_interpolate(Vector2.ZERO, 0.1)
	
	var _movement = move_and_slide(final_movement)
	
	update_animation(_current_movement)
	
	if decaying_bonus_speed > 0:
		decaying_bonus_speed -= Utils.physics_one(delta)
	elif decaying_bonus_speed < 0:
		decaying_bonus_speed += Utils.physics_one(delta) * 5


func get_movement()->Vector2:
	return _current_movement_behavior.get_movement() if not _move_locked else _current_movement


func get_move_input()->Vector2:
	return _current_movement.normalized() * max(0.0, (current_stats.speed + bonus_speed + decaying_bonus_speed + _speed_rand_value))


func get_knockback_value()->Vector2:
	return (_knockback_vector * (100 - (stats.knockback_resistance * 100)))


func get_direction()->int:
	return sprite.scale.x as int


func update_animation(movement:Vector2)->void :
	if mirror_sprite_with_movement:
		if movement.x > 0:
			sprite.scale.x = abs(sprite.scale.x)
		elif movement.x < 0:
			sprite.scale.x = - abs(sprite.scale.x)


func _get_movement()->Vector2:
	return Vector2.ZERO


func take_damage(value:int, hitbox:Hitbox = null, dodgeable:bool = true, armor_applied:bool = true, custom_sound:Resource = null, base_effect_scale:float = 1.0)->int:
	if dead:
		return 0
	
	var crit_damage = 0.0
	var crit_chance = 0.0
	var knockback_direction = Vector2.ZERO
	var knockback_amount = 0.0
	var effect_scale = base_effect_scale
	
	if hitbox != null:
		crit_damage = hitbox.crit_damage
		crit_chance = hitbox.crit_chance
		knockback_direction = hitbox.knockback_direction
		knockback_amount = hitbox.knockback_amount
		effect_scale = hitbox.effect_scale
	
	var is_crit = false
	var is_miss = false

	var actual_value = get_dmg_value(value, armor_applied)
	



	if dodgeable and randf() < min(current_stats.dodge, RunData.effects["dodge_cap"] / 100.0):
		actual_value = 0
	else :
		flash()
	
	var sound = Utils.get_rand_element(hurt_sounds)
	
	if actual_value == 0:
		sound = Utils.get_rand_element(dodge_sounds)
	elif not is_miss and randf() < crit_chance:
		
		if hitbox:
			hitbox.critically_hit_something(self)
		
		actual_value = get_dmg_value(round(value * crit_damage))
		is_crit = true
		sound = Utils.get_rand_element(crit_sounds)
	
	if custom_sound:
		sound = custom_sound
	
	SoundManager2D.play(sound, global_position, 0, 0.2, always_play_hurt_sound)
	
	current_stats.health = max(0.0, current_stats.health - actual_value)
	
	_knockback_vector = knockback_direction * knockback_amount
	
	emit_signal("health_updated", current_stats.health, max_stats.health)
	
	var hit_type = HitType.NORMAL
	
	if current_stats.health <= 0:
		if hitbox:
			hitbox.killed_something(self)
		die(knockback_direction * max(knockback_amount, MIN_DEATH_KNOCKBACK_AMOUNT))
		
		if is_crit:
			var gold_added = 0
			
			for effect in RunData.effects["gold_on_crit_kill"]:
				if randf() < effect[1] / 100.0:
					gold_added += 1
			
			for effect in hitbox.effects:
				if effect.key == "gold_on_crit_kill" and randf() <= effect.value / 100.0:
					gold_added += 1
			
			if gold_added > 0:
				RunData.add_gold(gold_added)
				hit_type = HitType.GOLD_ON_CRIT_KILL
	
	emit_signal(
		"took_damage", 
		self, 
		actual_value, 
		knockback_direction, 
		knockback_amount, 
		is_crit, 
		is_miss, 
		effect_scale, 
		hit_type
	)
	
	return actual_value


func get_dmg_value(dmg_value:int, armor_applied:bool = true)->int:
	return max(1, dmg_value - current_stats.armor) as int if armor_applied else dmg_value


func flash()->void :
	sprite.material.set_shader_param("flash_modifier", 1)
	_flash_timer.start()


func die(knockback_vector:Vector2 = Vector2.ZERO, p_cleaning_up:bool = false)->void :
	.die(knockback_vector, p_cleaning_up)
	_burning_particles.emitting = false
	_knockback_vector = knockback_vector
	_can_move = false
	_hurtbox.disable()
	_collision.set_deferred("disabled", true)
	_burning_particles.deactivate_spread()


func _on_Hurtbox_area_entered(hitbox:Area2D)->void :
	
	if not hitbox.active or hitbox.ignored_objects.has(self):
		return 
	var dmg = hitbox.damage
	
	if hitbox.deals_damage:
		var is_exploding = false
		
		for effect in hitbox.effects:
			if effect is ExplodingEffect:
				if randf() < effect.chance:
					WeaponService.explode(effect, global_position, hitbox.damage, hitbox.accuracy, hitbox.crit_chance, hitbox.crit_damage, hitbox.burning_data, hitbox.is_healing)
					is_exploding = true
		
		
		if not is_exploding:
			var _dmg_taken = take_damage(dmg, hitbox)
			
			if hitbox.burning_data != null and randf() < hitbox.burning_data.chance and not hitbox.is_healing:
				apply_burning(hitbox.burning_data)
		
		if hitbox.projectiles_on_hit.size() > 0:
			for i in hitbox.projectiles_on_hit[0]:
				var projectile = WeaponService.manage_special_spawn_projectile(
					self, 
					hitbox.projectiles_on_hit[1], 
					hitbox.projectiles_on_hit[2], 
					_entity_spawner_ref
				)
				
				projectile.call_deferred("set_ignored_objects", [self])
		
		on_hurt()
	
	hitbox.hit_something(self)


func apply_burning(burning_data:BurningData)->void :
	_burning_particles.burning_data = burning_data.duplicate()
	
	if _burning != null:
		
		if _burning.damage < burning_data.damage:
			_burning.type = burning_data.type
			_burning_particles.update_color()
		
		_burning.chance = max(_burning.chance, burning_data.chance)
		_burning.damage = max(_burning.damage, burning_data.damage)
		_burning.duration = max(_burning.duration, burning_data.duration)
		_burning.spread = max(_burning.spread, burning_data.spread)
	else :
		SoundManager2D.play(Utils.get_rand_element(burn_sounds), global_position, 0, 0.2, always_play_hurt_sound)
		_burning_particles.start_emitting()
		_burning = burning_data.duplicate()
		_burning_timer.start()
	
	if _burning.spread > 0:
		_burning_particles.activate_spread()


func deactivate_burning_spread()->void :
	_burning_particles.emitting = false
	_burning_particles.deactivate_spread()


func on_hurt()->void :
	pass


func _on_FlashTimer_timeout()->void :
	sprite.material.set_shader_param("flash_modifier", 0)


func _on_BurningTimer_timeout()->void :
	if _burning != null:
		var _dmg_taken = take_damage(_burning.damage, null, false, false, Utils.get_rand_element(burn_sounds), 0.1)
		_burning.duration -= 1
		if _burning.duration <= 0:
			_burning = null
			_burning_timer.stop()
			_burning_particles.emitting = false
			_burning_particles.deactivate_spread()
		elif _burning.spread <= 0:
			_burning_particles.deactivate_spread()


func add_decaying_speed(value:int)->void :
	if decaying_bonus_speed < - (current_stats.speed * 0.8):
		value = 0
	elif decaying_bonus_speed < 0:
		value /= 20
	
	decaying_bonus_speed += value


func _on_Hitbox_body_entered(_body:Node)->void :
	pass
