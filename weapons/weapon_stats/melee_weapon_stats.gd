class_name MeleeWeaponStats
extends WeaponStats

enum AttackType{THRUST, SWEEP}

export (bool) var deal_dmg_on_return: = false
export (AttackType) var attack_type = AttackType.THRUST
export (bool) var alternate_attack_type = false


func get_alternate_attack_type_text()->String:
				return "" if not alternate_attack_type else "\n" + tr("ALTERNATES_ATTACK_TYPE")


func get_deal_dmg_on_return_text()->String:
				return "" if not deal_dmg_on_return else "\n" + tr("DEALS_DAMAGE_ON_RETURN")


func get_damage_text(base_stats:Resource)->String:
				return get_dmg_text_with_scaling_stats(base_stats, scaling_stats, 1)


func get_cooldown_text(base_stats:Resource)->String:
				var current_shooting_data = MeleeShootingData.new(self)
				var base_shooting_data = MeleeShootingData.new(base_stats, false)
				var cd = current_shooting_data.get_shooting_total_duration() + cooldown / 60.0
				var base_cd = base_shooting_data.get_shooting_total_duration() + base_stats.cooldown / 60.0
				var a = get_col_a( - cd, - base_cd)
				return a + str(stepify(cd, 0.01)) + "s" + col_b


func get_type_text()->String:
				return tr("MELEE")

func serialize()->Dictionary:
				var serialized = .serialize()
				
				serialized.type = "melee"
				serialized.deal_dmg_on_return = deal_dmg_on_return
				serialized.attack_type = attack_type
				serialized.alternate_attack_type = alternate_attack_type
				
				return serialized


func deserialize_and_merge(serialized:Dictionary):
				.deserialize_and_merge(serialized)
				
				deal_dmg_on_return = serialized.deal_dmg_on_return
				attack_type = serialized.attack_type as int
				alternate_attack_type = serialized.alternate_attack_type
