class_name TurretEffect
extends StructureEffect

export (float) var shooting_animation_speed = 1.0


static func get_id()->String:
	return "turret"


func get_args()->Array:
	var scaling_stats_names = WeaponService.get_scaling_stats_icons(stats.scaling_stats)
	var init_stats = WeaponService.init_ranged_stats(stats, "", [], effects, true)
	
	return [str(init_stats.damage), scaling_stats_names, str(init_stats.nb_projectiles), str(init_stats.bounce)]


func serialize()->Dictionary:
	var serialized = .serialize()
	
	serialized.shooting_animation_speed = shooting_animation_speed
	
	return serialized


func deserialize_and_merge(serialized:Dictionary)->void :
	.deserialize_and_merge(serialized)
	
	shooting_animation_speed = serialized.shooting_animation_speed
