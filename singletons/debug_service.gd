extends Node

export (int, 1, 21) var starting_wave: = 1
export (Array, Resource) var debug_weapons = []
export (Array, Resource) var debug_items = []
export (bool) var add_all_weapons = false
export (bool) var add_all_items = false
export (bool) var instant_waves = false
export (bool) var unlock_all_chars = false
export (bool) var reinitialize_save = false
export (int) var starting_gold = 30
export (bool) var no_fullscreen_on_launch = false
export (bool) var unlock_all_challenges = false
export (bool) var reinitialize_steam_data = false
export (bool) var invulnerable = false
export (bool) var unlock_all_difficulties = false
export (bool) var generate_full_unlocked_save_file = false
export (bool) var no_weapons = false

var debug_items_added = false


func log_run_info(upgrades:Array = [], consumables:Array = [])->void :
				
				var log_file = File.new()
				var error = log_file.open(ProgressData.LOG_PATH, File.WRITE)
				
				if error != OK:
								printerr("Could not open the file %s. Aborting save operation. Error code: %s" % 
								[ProgressData.LOG_PATH, error])
								return 
				
				log_file.store_line("Character: " + str(RunData.current_character.my_id))
				log_file.store_line("Wave: " + str(RunData.current_wave))
				log_file.store_line("Danger: " + str(RunData.get_current_difficulty()))
				log_file.store_line("Level ups: " + str(upgrades.size()))
				log_file.store_line("Consumables: " + str(consumables.size()))
				log_file.store_line("Gold: " + str(RunData.gold))
				log_file.store_line("Bonus Gold: " + str(RunData.bonus_gold))
				
				var items = ""
				
				for item in RunData.items:
								items += item.my_id + ", "
				
				log_file.store_line("Items: " + str(items))
				
				var weapons = ""
				
				for item in RunData.weapons:
								weapons += item.my_id + ", "
				
				log_file.store_line("Weapons: " + str(weapons))
				
				log_file.close()


func log_data(text:String)->void :
				var log_file = File.new()
				var _error = log_file.open(ProgressData.LOG_PATH, File.READ_WRITE)
				log_file.seek_end()
				log_file.store_string("\n" + text)
				log_file.close()
