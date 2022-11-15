class_name Effect
extends Resource

enum Sign{POSITIVE, NEGATIVE, NEUTRAL, FROM_VALUE}

export (String) var key: = ""
export (String) var text_key: = ""
export (int) var value: = 0
export (Sign) var effect_sign: = Sign.FROM_VALUE


static func get_id()->String:
	return "effect"


func apply()->void :
	RunData.effects[key] += value


func unapply()->void :
	RunData.effects[key] -= value


func get_text(colored:bool = true)->String:
	var key_text = key.to_upper() if text_key.length() == 0 else text_key.to_upper()
	
	var text_sign = effect_sign
	
	if effect_sign == Sign.FROM_VALUE:
		text_sign = Sign.POSITIVE if value > 0 else Sign.NEGATIVE if value < 0 else Sign.NEUTRAL
	
	return Text.text(key_text, get_args(), text_sign, colored)


func get_args()->Array:
	return [str(value)]


func serialize()->Dictionary:
	return {
		"effect_id":get_id(), 
		"key":key, 
		"text_key":text_key, 
		"value":str(value), 
		"effect_sign":effect_sign
	}


func deserialize_and_merge(effect:Dictionary)->void :
	key = effect.key
	text_key = effect.text_key
	value = effect.value as int
	effect_sign = effect.effect_sign as int
