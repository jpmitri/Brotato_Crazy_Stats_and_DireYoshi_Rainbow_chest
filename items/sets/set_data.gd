class_name SetData
extends Resource

enum WeaponClass{GUN, PRIMITIVE, HEAVY, ELEMENTAL, UNARMED, PRECISE, BLUNT, SUPPORT, MEDICAL, ETHEREAL, TOOL, EXPLOSIVE, BLADE, MEDIEVAL}

export (WeaponClass) var weapon_class = WeaponClass.GUN
export (Array, Array, Resource) var set_bonuses = [[], [], [], [], []]
