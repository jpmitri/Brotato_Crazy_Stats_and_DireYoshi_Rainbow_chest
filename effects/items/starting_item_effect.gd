class_name StartingItemEffect
extends Effect

export (Resource) var item = null


static func get_id()->String:
	return "starting_item"


func apply()->void :
	for i in value:
		RunData.effects[key].push_back(item)


func unapply()->void :
	for i in value:
		RunData.effects[key].erase(item)


func get_args()->Array:
	return [str(value), Text.text(item.name)]


func serialize()->Dictionary:
	var serialized = .serialize()
	
	if item != null:
		serialized.item = item.my_id
	
	return serialized


func deserialize_and_merge(serialized:Dictionary)->void :
	.deserialize_and_merge(serialized)
	
	if serialized.has("item"):
		var item_data = ItemService.get_element(ItemService.items, serialized.item)
		item = item_data
