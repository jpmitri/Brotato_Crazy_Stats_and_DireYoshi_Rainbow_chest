class_name ItemData
extends ItemParentData

export (bool) var unique = false
export (int) var max_nb = - 1
export (Array, Resource) var item_appearances = []
export (Array, String) var tags = []


func get_category()->int:
	return Category.ITEM
