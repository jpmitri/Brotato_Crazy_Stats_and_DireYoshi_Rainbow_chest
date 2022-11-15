class_name StatsContainer
extends PanelContainer

signal stat_focused(stat_button, stat_title, stat_value)
signal stat_unfocused()
signal stat_hovered(stat_button, stat_title, stat_value)
signal stat_unhovered()

var all_stats:Array


func _ready()->void :
	var container = $MarginContainer / VBoxContainer2 / VBoxContainer
	all_stats = container.get_children()
	
	for stat in all_stats:
		stat.connect("focused", self, "on_stat_focused")
		stat.connect("unfocused", self, "on_stat_unfocused")
		stat.connect("hovered", self, "on_stat_hovered")
		stat.connect("unhovered", self, "on_stat_unhovered")


func disable_focus_except_mouse()->void :
	for stat_container in all_stats:
		stat_container.disable_focus_except_mouse()


func set_neighbour_right(node:Node)->void :
	for stat_container in all_stats:
		stat_container.set_neighbour_right(node)


func update_stats()->void :
	for stat in all_stats:
		stat.update_stat()


func enable_focus()->void :
	for stat in all_stats:
		stat.enable_focus()


func disable_focus()->void :
	for stat in all_stats:
		stat.disable_focus()


func on_stat_focused(stat_button, stat_title, stat_value)->void :
	emit_signal("stat_focused", stat_button, stat_title, stat_value)


func on_stat_unfocused()->void :
	emit_signal("stat_unfocused")


func on_stat_hovered(stat_button, stat_title, stat_value)->void :
	emit_signal("stat_hovered", stat_button, stat_title, stat_value)


func on_stat_unhovered()->void :
	emit_signal("stat_unhovered")
