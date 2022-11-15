class_name MenuGameplayOptions
extends Control

signal character_highlighting_changed(value)
signal weapon_highlighting_changed(value)
signal hp_bar_on_character_changed(value)
signal darken_screen_changed(value)
signal back_button_pressed


onready  var enemy_health_slider = $"%EnemyHealthSlider"
onready  var enemy_damage_slider = $"%EnemyDamageSlider"
onready  var enemy_speed_slider = $"%EnemySpeedSlider"
onready  var font_size_slider = $"%FontSizeSlider"
onready  var character_highlighting_button = $"%CharacterHighlightingButton" as CheckButton
onready  var weapon_highlighting_button = $"%WeaponHighlightingButton" as CheckButton
onready  var projectile_highlighting_button = $"%ProjectileHighlightingButton" as CheckButton
onready  var hp_bar_button = $"%HPbarOnCharacterButton" as CheckButton
onready  var boss_hp_bar_button = $"%BossHPBarButton" as CheckButton
onready  var keep_lock_button = $"%KeepLockButton" as CheckButton
onready  var explosions_button = $"%ExplosionsButton" as CheckButton
onready  var gold_sounds_button = $"%GoldSoundsButton" as CheckButton
onready  var darken_screen_button = $"%DarkenScreenButton" as CheckButton

onready  var mouse_only_button = $"%MouseOnlyButton" as CheckButton
onready  var manual_aim_button = $"%ManualAimButton" as CheckButton
onready  var manual_aim_on_mouse_press_button = $"%ManualAimOnMousePressButton" as CheckButton
onready  var score_storing_button = $"%ScoreStoringButton" as OptionButton


func init()->void :
				$BackButton.grab_focus()
				
				font_size_slider.set_value(ProgressData.settings.font_size)
				
				score_storing_button.select(ProgressData.settings.endless_score_storing)
				
				mouse_only_button.pressed = ProgressData.settings.mouse_only
				manual_aim_button.pressed = ProgressData.settings.manual_aim
				manual_aim_on_mouse_press_button.pressed = ProgressData.settings.manual_aim_on_mouse_press
				character_highlighting_button.pressed = ProgressData.settings.character_highlighting
				weapon_highlighting_button.pressed = ProgressData.settings.weapon_highlighting
				projectile_highlighting_button.pressed = ProgressData.settings.projectile_highlighting
				hp_bar_button.pressed = ProgressData.settings.hp_bar_on_character
				boss_hp_bar_button.pressed = ProgressData.settings.hp_bar_on_bosses
				keep_lock_button.pressed = ProgressData.settings.keep_lock
				explosions_button.pressed = ProgressData.settings.explosions
				gold_sounds_button.pressed = ProgressData.settings.alt_gold_sounds

				enemy_health_slider.set_value(ProgressData.settings.enemy_scaling.health)
				enemy_damage_slider.set_value(ProgressData.settings.enemy_scaling.damage)
				enemy_speed_slider.set_value(ProgressData.settings.enemy_scaling.speed)
				darken_screen_button.pressed = ProgressData.settings.darken_screen


func _on_BackButton_pressed()->void :
				emit_signal("back_button_pressed")


func _on_MenuOptions_hide()->void :
				ProgressData.save()


func _on_MouseOnlyButton_toggled(button_pressed:bool)->void :
				ProgressData.settings.mouse_only = button_pressed


func _on_ManualAimButton_toggled(button_pressed:bool)->void :
				ProgressData.settings.manual_aim = button_pressed


func _on_EnemySpeedSlider_value_changed(value)->void :
				ProgressData.settings.enemy_scaling.speed = value


func _on_EnemyDamageSlider_value_changed(value)->void :
				ProgressData.settings.enemy_scaling.damage = value


func _on_EnemyHealthSlider_value_changed(value)->void :
				ProgressData.settings.enemy_scaling.health = value


func _on_ScoreButton_item_selected(index:int)->void :
				ProgressData.settings.endless_score_storing = index


func _on_FontSizeSlider_value_changed(value)->void :
				ProgressData.set_font_size(value)


func _on_HPbarOnCharacterButton_toggled(button_pressed:bool)->void :
				ProgressData.settings.hp_bar_on_character = button_pressed
				emit_signal("hp_bar_on_character_changed", button_pressed)


func _on_CharacterHighlightingButton_toggled(button_pressed:bool)->void :
				ProgressData.settings.character_highlighting = button_pressed
				emit_signal("character_highlighting_changed", button_pressed)


func _on_VisualEffectsButton_toggled(button_pressed:bool)->void :
				ProgressData.settings.visual_effects = button_pressed


func _on_DamageDisplayButton_toggled(button_pressed:bool)->void :
				ProgressData.settings.damage_display = button_pressed


func _on_WeaponHighlightingButton_toggled(button_pressed:bool)->void :
				ProgressData.settings.weapon_highlighting = button_pressed
				emit_signal("weapon_highlighting_changed", button_pressed)


func _on_ExplosionsButton_toggled(button_pressed:bool)->void :
				ProgressData.settings.explosions = button_pressed


func _on_GoldSoundsButton_toggled(button_pressed:bool)->void :
				ProgressData.settings.alt_gold_sounds = button_pressed


func _on_KeepLockButton_toggled(button_pressed:bool)->void :
				ProgressData.settings.keep_lock = button_pressed


func _on_DarkenScreenButton_toggled(button_pressed:bool)->void :
				ProgressData.settings.darken_screen = button_pressed
				emit_signal("darken_screen_changed", button_pressed)


func _on_BossHPBarButton_toggled(button_pressed:bool)->void :
				ProgressData.settings.hp_bar_on_bosses = button_pressed


func _on_ManualAimOnMousePressButton_toggled(button_pressed:bool)->void :
				ProgressData.settings.manual_aim_on_mouse_press = button_pressed


func _on_ProjectileHighlightingButton_toggled(button_pressed:bool)->void :
				ProgressData.settings.projectile_highlighting = button_pressed
