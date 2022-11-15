class_name Landmine
extends Structure

export (Resource) var pressed_sprite = null
export (Array, Resource) var pressed_sounds = []
export (PackedScene) var explosion_scene = null

var area: = 1.5

onready  var _sprite = $Animation / Sprite


func _on_Area2D_body_entered(_body:Node)->void :
	
	if dead or _sprite.texture == pressed_sprite:return 
	
	SoundManager2D.play(Utils.get_rand_element(pressed_sounds), global_position, 5, 0.2)
	_sprite.texture = pressed_sprite


func _on_Area2D_body_exited(_body:Node)->void :
	
	if dead:return 
	
	var main = get_tree().current_scene
	var explosion = explosion_scene.instance()
	explosion.set_deferred("global_position", global_position)
	main.call_deferred("add_child", explosion)
	explosion.call_deferred("set_damage", stats.damage)
	explosion.call_deferred("set_area", area)
	die()
