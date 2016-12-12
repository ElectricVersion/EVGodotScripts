extends TileMap

export var world_seed = 128
export var world_size = 32
export var room_count = 16
export var min_room_size = 4
export var max_room_size = 6 
export var hallway_thickness = 1 #thickness of hallways
export var padding = 1 #minimum space between rooms

var room_data = []

var floor_tile = 0
var wall_tile = 1

#get the center of a rectangle
func rect_center(rect):
	return rect.pos + (rect.size/2)

#random integer in range
func randi_range(a, b, inclusive = false):
	if inclusive:
		b += 1 
	return floor(rand_range(a, b))

#fills an area with a tile
func fill(a, b, tile_type):
	for t_iy in range(floor(min(a.y, b.y)), floor(max(a.y, b.y))):
		for t_ix in range(floor(min(a.x, b.x)), floor(max(a.x, b.x))):
			set_cell(t_ix, t_iy, tile_type)

#generates a randomly positioned room
func generate_room():
	var w = randi_range(min_room_size, max_room_size, true)
	var h = randi_range(min_room_size, max_room_size, true)
	var x = randi_range(0, world_size-w, false)
	var y = randi_range(0, world_size-h, false)
	var this_room = Rect2(x,y,w,h)
	var valid_room = true
	for i in room_data: # check if it overlaps any existing rooms
		if this_room.intersects(i.rect.grow(padding)):
			valid_room = false
	if valid_room: #if the room can be made
		room_data.push_back({accessible=false, rect=this_room, hallways=0, center=rect_center(this_room)})
		fill(this_room.pos, this_room.end, floor_tile)

#connect the rooms
func make_hallway(point1, point2):
	var min_point = Vector2(min(point1.x, point2.x), min(point1.y, point2.y))
	var max_point = Vector2(max(point1.x, point2.x), max(point1.y, point2.y))
	var half_thickness = hallway_thickness/2.0
	fill(Vector2(point1.x-half_thickness, point1.y), Vector2(point1.x+half_thickness, point2.y), floor_tile)
	fill(Vector2(point1.x-half_thickness, point2.y-half_thickness), Vector2(point1.x+half_thickness, point2.y+half_thickness), floor_tile)
	fill(Vector2(point1.x, point2.y-half_thickness), Vector2(point2.x, point2.y+half_thickness), floor_tile)


func generate_dungeon():
	fill(Vector2(0,0), Vector2(world_size, world_size), wall_tile)
	seed(world_seed)
	while room_data.size() < 2:
		for i in range(0,room_count):
			generate_room()
		if room_data.size() < 2:
			seed(randi())
	room_data[0].accessible=true # the starting room is accessible of course
	#make sure every room is connected
	for i in room_data:
		if !i.accessible:
			# find the nearest room
			var nearest_room = null # the index of the nearest room
			var least_distance = 0
			for j in room_data:
				if j.accessible and j != i:
					if i.center.distance_to(j.center) < least_distance or nearest_room == null:
						least_distance = i.center.distance_to(j.center)
						nearest_room = j
			# now make a hallway to the nearest room
			if nearest_room != null:
				make_hallway(i.center, nearest_room.center)
				i.accessible = true

func _ready():
	generate_dungeon()