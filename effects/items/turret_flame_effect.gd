class_name TurretFlameEffect
extends TurretEffect


static func get_id()->String:
	return "turret_flame"


func get_args()->Array:
	
	var burning_ticks = effects[0].burning_data.duration
	
	var scaling_stats_value = WeaponService.get_scaling_stats_value(stats.scaling_stats)
	var scaling_stats_names = WeaponService.get_scaling_stats_icons(stats.scaling_stats)
	
	var burning_dmg = max(1.0, round(effects[0].burning_data.damage + scaling_stats_value))
	
	return [str(burning_dmg), str(burning_ticks), scaling_stats_names]
