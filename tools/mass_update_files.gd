tool 
extends EditorScript

var temp = {}

func _run()->void :
	var dir = Directory.new()
	var dir_path = "res://weapons/"


	
	dir.open(dir_path)
	dir.list_dir_begin(true)
	
	update(dir, dir_path)


func update(dir:Directory, dir_path:String)->void :
	var file_name = dir.get_next()
	while file_name != "":

		if dir.current_is_dir():

			var new_dir = Directory.new()
			new_dir.open(dir_path + file_name)
			new_dir.list_dir_begin(true)
			update(new_dir, dir_path + file_name + "/")
		
		if file_name.ends_with(".tres"):

			var cur_file = load(dir_path + file_name)
			
			if cur_file is ItemParentData:
				
				print(cur_file.my_id + " - " + str(cur_file.value))
				
				var txt = ""
				

				


				


				


		
		file_name = dir.get_next()
