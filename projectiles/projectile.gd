class_name Projectile
extends Node2D

export (bool) var destroy_on_leaving_screen = true
var velocity = Vector2.ZERO
var to_be_destroyed: = false

onready  var _hitbox: = $Hitbox as Area2D
onready  var _destroy_timer: = $DestroyTimer as Timer


func _physics_process(delta)->void :
	position += velocity * delta


func get_damage()->int:
	return _hitbox.damage


func set_damage(value:int, accuracy:float = 1.0, crit_chance:float = 0.0, crit_damage:float = 0.0, burning_data:BurningData = BurningData.new(), is_healing:bool = false)->void :
	_hitbox.set_damage(value, accuracy, crit_chance, crit_damage, burning_data, is_healing)


func set_knockback_vector(knockback_direction:Vector2, knockback_amount:float)->void :
	_hitbox.set_knockback(knockback_direction, knockback_amount)


func set_effect_scale(effect_scale:float)->void :
	_hitbox.effect_scale = effect_scale


func _on_VisibilityNotifier2D_screen_exited()->void :
	if not to_be_destroyed and _destroy_timer.is_inside_tree() and destroy_on_leaving_screen:
		_destroy_timer.start()


func _on_DestroyTimer_timeout()->void :
	queue_free()


func set_to_be_destroyed()->void :
	to_be_destroyed = true
	_hitbox.active = false
	_hitbox.disable()
	queue_free()


func set_ignored_objects(objects:Array)->void :
	_hitbox.ignored_objects = objects


func disable_hitbox()->void :
	_hitbox.disable()


func enable_hitbox()->void :
	_hitbox.enable()


func on_entity_died(entity:Entity)->void :
	set_to_be_destroyed()
