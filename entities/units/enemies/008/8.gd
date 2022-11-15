extends Enemy

export (float) var proj_chance = 0.25


func on_hurt()->void :
	.on_hurt()
	
	if randf() < proj_chance:
		_attack_behavior.shoot()
