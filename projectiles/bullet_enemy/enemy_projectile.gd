class_name EnemyProjectile
extends Projectile


func _ready()->void :
	if ProgressData.settings.projectile_highlighting:
		$Sprite.material = Utils.projectile_outline_shadermat


func _on_Hitbox_hit_something(_thing_hit)->void :
	set_to_be_destroyed()
