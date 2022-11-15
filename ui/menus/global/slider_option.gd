class_name SliderOption
extends HBoxContainer

export (bool) var percent_slider = true
export (String) var postfix = "%"

signal value_changed(value)

onready  var _label = $Label
onready  var _slider = $HSlider
onready  var _value = $Value


func _ready()->void :
				_set_value(_slider.value)


func set_value(value:float)->void :
				_slider.value = value
				_on_HSlider_value_changed(value)


func _on_HSlider_value_changed(value:float)->void :
				_set_value(value)
				emit_signal("value_changed", value)


func _set_value(value:float)->void :
				if percent_slider:
								_value.text = str(value * 100)
				else :
								_value.text = str(value)
				_value.text += postfix
