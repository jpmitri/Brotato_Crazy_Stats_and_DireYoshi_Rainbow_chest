class_name Enemy
extends Unit

signal healed(enemy)
signal stats_boosted(enemy)
signal wanted_to_spawn_an_enemy(enemy_scene, at_position)
signal state_changed(enemy)

export (Resource) var outline_shader
export (bool) var can_be_boosted: = true

var is_boosted: = false
var _idle_playback_speed = rand_range(1, 3)
var _current_attack_cd:float
var _current_attack_behavior:AttackBehavior

onready  var _attack_behavior = $AttackBehavior
onready  var _hitbox = $Hitbox


func _ready()->void :
	_current_attack_behavior = _attack_behavior
	_animation_player.playback_speed = _idle_playback_speed


func init(zone_min_pos:Vector2, zone_max_pos:Vector2, player_ref:Node2D = null, entity_spawner_ref:EntitySpawner = null)->void :
	.init(zone_min_pos, zone_max_pos, player_ref, entity_spawner_ref)
	
	init_current_stats()
	
	_hitbox.connect("hit_something", self, "_on_hit_something")
	_hitbox.damage = current_stats.damage
	
	_attack_behavior.init(self)


func _physics_process(delta:float)->void :
	if dead:
		return 
	
	_current_attack_cd = max(_current_attack_cd - Utils.physics_one(delta), 0)
	var is_being_knocked_back = get_knockback_value().length() > get_move_input().length()
	
	if not _hitbox.is_disabled() and is_being_knocked_back:
		_hitbox.disable()
	elif _hitbox.is_disabled() and not is_being_knocked_back:
		_hitbox.enable()
	
	_current_attack_behavior.physics_process(delta)


func update_stats(hp_coef:float, damage_coef:float, speed_coef:float)->void :
	.update_stats(hp_coef, damage_coef, speed_coef)
	_hitbox.damage = current_stats.damage


func start_shoot()->void :
	_current_attack_behavior.start_shoot()


func shoot()->void :
	_current_attack_behavior.shoot()


func die(knockback_vector:Vector2 = Vector2.ZERO, p_cleaning_up:bool = false)->void :
	.die(knockback_vector, p_cleaning_up)
	_hitbox.disable()


func set_boosted()->void :
	can_be_boosted = false
	is_boosted = true
	_sprite.material.shader = outline_shader


func on_hurt()->void :
	if RunData.effects["remove_speed"][0] > 0 and current_stats.speed > max_stats.speed * (1 - (RunData.effects["remove_speed"][1] / 100.0)):
		current_stats.speed -= (max_stats.speed * (RunData.effects["remove_speed"][0] / 100.0))


func _on_hit_something(_thing_hit:Node)->void :
	add_decaying_speed( - 200)


func _on_AnimationPlayer_animation_finished(anim_name:String)->void :
	if anim_name != "idle" and anim_name != "death":
		_animation_player.play("idle")
		_animation_player.playback_speed = _idle_playback_speed
	
	_current_attack_behavior.animation_finished(anim_name)


func _on_AttackBehavior_wanted_to_spawn_an_enemy(enemy_scene:PackedScene, at_position:Vector2)->void :
	emit_signal("wanted_to_spawn_an_enemy", enemy_scene, at_position)

