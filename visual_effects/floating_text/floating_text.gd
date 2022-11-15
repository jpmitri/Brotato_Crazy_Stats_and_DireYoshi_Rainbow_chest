class_name FloatingText
extends Label

signal destroyed

onready  var _tween = $Tween as Tween


func display(content:String, direction:Vector2, duration:float, spread:float, color:Color = Color.white, all_caps:bool = false)->void :
	self_modulate = color
	text = content
	uppercase = all_caps
	var movement: = direction.rotated(rand_range( - spread / 2, spread / 2))
	rect_pivot_offset = rect_size / 2
	
	_tween.interpolate_property(
		self, 
		"rect_position", 
		rect_position, 
		rect_position + movement, 
		duration, 
		Tween.TRANS_ELASTIC, 
		Tween.EASE_OUT
	)
	
	_tween.start()
	yield (_tween, "tween_all_completed")
	
	_tween.interpolate_property(
		self, 
		"rect_scale", 
		Vector2.ONE, 
		Vector2.ZERO, 
		duration, 
		Tween.TRANS_ELASTIC, 
		Tween.EASE_IN_OUT
	)
	
	_tween.interpolate_property(
		self, 
		"modulate:a", 
		1.0, 
		0.0, 
		duration, 
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT
	)
	
	_tween.start()
	yield (_tween, "tween_all_completed")
	queue_free()
	emit_signal("destroyed")
