class_name RainbowBoxUI
extends Control

signal item_box_processed
signal item_take_button_pressed(item_data)


var taken:bool
var prepped:bool = false

var item_scene = preload("res://ui/menus/shop/item_description.tscn")

onready  var _item_ui_vbox = $MarginContainer / Content / VBoxContainer / HBoxContainer2 / ScrollContainer / VBoxContainer
onready  var _scroll = $MarginContainer / Content / VBoxContainer / HBoxContainer2 / ScrollContainer
onready  var _stats_container = $MarginContainer / Content / VBoxContainer / HBoxContainer2 / StatsContainer
onready  var _focus_manager = $FocusManager
onready  var _stat_popup = $MarginContainer / Content / StatPopup


func _ready()->void :
				_focus_manager.init(null, _stat_popup, null, null, _stats_container, null, false)


func prep()->void :
				taken = false
				_stats_container.update_stats()
				show()

				if prepped:
								return 

				prepped = true

				var __instance = null
				var __button = null
				var __prev_button = null
				var __empty = null
				var __pc:PanelContainer = null
				var __mc:MarginContainer = null
				var __hbox:HBoxContainer = null
				var __vbox:VBoxContainer = null
				var __sbc = null

				var i:int = 0
				var rc:int = 0
				var __all_items = []
				__all_items += ItemService.get_pool(0, 1)
				__all_items += ItemService.get_pool(1, 1)
				__all_items += ItemService.get_pool(2, 1)
				__all_items += ItemService.get_pool(3, 1)

				for item in __all_items:
								if rc % 4 == 0:
												__hbox = HBoxContainer.new()
												_item_ui_vbox.add_child(__hbox)
								__pc = PanelContainer.new()
								__hbox.add_child(__pc)
								__mc = MarginContainer.new()
								__mc.margin_left = 15.0
								__mc.margin_right = 15.0
								__mc.margin_top = 15.0
								__mc.margin_bottom = 15.0
								__pc.add_child(__mc)
								__vbox = VBoxContainer.new()
								__mc.add_child(__vbox)
								__instance = item_scene.instance()
								__vbox.add_child(__instance)
								__button = MyMenuButton.new()
								__empty = Control.new()
								__empty.size_flags_horizontal.fill = true
								__empty.size_flags_vertical.fill = true
								__empty.size_flags_vertical.expand = true
								__empty.set_size(Vector2(50.0, 50.0))
								__vbox.add_child(__empty)
								__button.name = "TakeButton" + str(i)
								__button.text = "Take"
								__button.__index = i
								__instance.set_item(item)
								__vbox.add_child(__button)
								
								if __prev_button:
												__button.focus_previous = __prev_button
												__prev_button.focus_next = __button
								__prev_button = __button
								__sbc = __pc.get_stylebox("panel").duplicate()
								ItemService.change_panel_stylebox_from_tier(__sbc, item.tier)
								__pc.add_stylebox_override("panel", __sbc)
								__button.connect("pressed", self, "_on_TakeButton_pressed", [item])
								__empty = Control.new()
								if rc % 4 != 3:
												__hbox.add_child(__empty)
								i += 1
								rc += 1

				_scroll.get_v_scrollbar().rect_min_size.x = 50


func _on_TakeButton_pressed(item_data:ItemParentData)->void :

				if taken:return 

				taken = true
				emit_signal("item_take_button_pressed", item_data)

				LinkedStats.reset()
				_stats_container.update_stats()
				hide()
				emit_signal("item_box_processed")
