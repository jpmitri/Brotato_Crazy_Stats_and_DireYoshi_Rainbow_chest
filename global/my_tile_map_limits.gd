class_name MyTileMapLimits
extends TileMap


func init(zone:ZoneData)->void :
	
	for i in zone.width + 1:
		set_cell(i, 0, 0)
		set_cell(i, zone.height + 1, 0)

	for j in zone.height + 1:
		set_cell(0, j, 0)
		set_cell(zone.width + 1, j, 0)
