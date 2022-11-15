class_name ChallengeData
extends ItemParentData

enum RewardType{ITEM, WEAPON, ZONE, STARTING_WEAPON, CONSUMABLE, UPGRADE, CHARACTER, DIFFICULTY}

export (String) var description = ""
export (RewardType) var reward_type = RewardType.ITEM
export (Resource) var reward
export (int) var number = 0
export (String) var stat = ""


func get_title_args()->Array:
	return [str(number)]


func get_desc_args()->Array:
	if name.begins_with("CHARACTER_"):
		return [Text.text(name)]
	else :
		return [str(value), tr(stat.to_upper())]


func get_category()->int:
	return Category.CHALLENGE
