class_name AlienEyesEffect
extends ProjectileEffect

const ALIEN_EYES_CD: = 3


func get_args()->Array:
	var args = .get_args()
	args.append(str(ALIEN_EYES_CD))
	return args
