extends Particles2D


func _ready()->void :
	process_material.color = RunData.get_background().outline_color


func emit()->void :
	emitting = true


func stop()->void :
	emitting = false
