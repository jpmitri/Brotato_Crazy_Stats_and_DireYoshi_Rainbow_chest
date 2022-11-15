extends TextureRect

func _ready()->void :
	modulate = Utils.GOLD_COLOR


func set_icon(icon:Texture)->void :
	texture = icon
	modulate = Color.white
