class_name MenuModsOptions
extends Control

signal back_button_pressed


onready  var rainbow_slider = $"%RainbowChestBaseSlider"
onready  var shop_slider = $"%ShopWeightSlider"
onready  var luck_everything_slider = $"%LuckEverythingSlider"

onready  var fixed_reroll_button = $"%FixedRerollButton" as CheckButton
onready  var remove_inflation_button = $"%RemoveInflationButton" as CheckButton
onready  var elites_drop_button = $"%ElitesDropRainbowButton" as CheckButton

onready  var enemy_slider = $"%EnemyMultiplier"
onready  var map_slider = $"%MapSize"
onready  var max_enemy_slider = $"%MaxEnemy"
onready  var round_modification_slider = $"%RoundCounter"

func init()->void :
				$BackButton.grab_focus()

				fixed_reroll_button.pressed = ProgressData.settings.fixed_reroll
				remove_inflation_button.pressed = ProgressData.settings.remove_inflation
				elites_drop_button.pressed = ProgressData.settings.elites_drop_rainbow

				luck_everything_slider.set_value(ProgressData.settings.luck_everything)
				shop_slider.set_value(ProgressData.settings.shop_tag_chance)
				rainbow_slider.set_value(ProgressData.settings.rainbow_box_chance)

				enemy_slider.set_value(ProgressData.settings.enemy_multiplier)
				map_slider.set_value(ProgressData.settings.map_size)
				max_enemy_slider.set_value(ProgressData.settings.max_Var_enemy)
				round_modification_slider.set_value(ProgressData.settings.round_modification)

func _on_BackButton_pressed()->void :
				emit_signal("back_button_pressed")


func _on_MenuOptions_hide()->void :
				ProgressData.save()


func _on_FixedRerollButton_toggled(button_pressed:bool)->void :
				ProgressData.settings.fixed_reroll = button_pressed


func _on_RemoveInflationButton_toggled(button_pressed:bool)->void :
				ProgressData.settings.remove_inflation = button_pressed


func _on_ElitesDropRainbowButton_toggled(button_pressed:bool)->void :
				ProgressData.settings.elites_drop_rainbow = button_pressed


func _on_LuckEverythingSlider_value_changed(value)->void :
				ProgressData.settings.luck_everything = value


func _on_RainbowChestBaseSlider_value_changed(value)->void :
				ProgressData.settings.rainbow_box_chance = value


func _on_ShopWeightSlider_value_changed(value)->void :
				ProgressData.settings.shop_tag_chance = value

func _on_EnemyMultiplier_value_change(value)->void :
				ProgressData.settings.enemy_multiplier = value

func _on_MapSize_value_change(value)->void :
				ProgressData.settings.map_size = value

func _on_MaxEnemy_value_change(value)->void :
				ProgressData.settings.max_Var_enemy = value

func _on_RoundCounter_value_change(value)->void :
				ProgressData.settings.round_modification = value
