class_name PlayerExplosion
extends Node2D

export (Array, Resource) var explosion_sounds = []
export (float) var sound_db_mod = - 10.0

onready  var _hitbox = $Hitbox
onready  var _explosion_smoke = $ExplosionSmoke

var sound_played = false
var nb_killed = 0


func _ready()->void :
	
	if not ProgressData.settings.explosions:
		$Sprite.hide()
	
	$AnimationPlayer.play("explode")


func _physics_process(_delta:float)->void :
	if not sound_played:
		sound_played = true
		if sound_db_mod > - 50:
			SoundManager2D.play(Utils.get_rand_element(explosion_sounds), global_position, sound_db_mod, 0.2)


func emit_smoke()->void :
	$ExplosionSmoke.emit()


func _on_Timer_timeout()->void :
	queue_free()


func set_damage(p_value:int, p_accuracy:float = 1.0, p_crit_chance:float = 0.0, p_crit_damage:float = 0.0, p_burning_data:BurningData = null, is_healing:bool = false, ignored_objects:Array = [])->void :
	if not _hitbox:return 
	
	_hitbox.set_damage(p_value, p_accuracy, p_crit_chance, p_crit_damage, p_burning_data, is_healing)
	_hitbox.ignored_objects = ignored_objects


func set_area(p_area:float)->void :
	var explosion_scale = max(0.1, p_area + (p_area * (Utils.get_stat("explosion_size") / 100.0)))
	scale = Vector2(explosion_scale, explosion_scale)


func set_smoke_amount(value:int)->void :
	_explosion_smoke.amount = value


func _on_Hitbox_killed_something(_thing_killed)->void :
	nb_killed += 1
	if nb_killed >= 15:
		ChallengeService.complete_challenge("chal_fireworks")
