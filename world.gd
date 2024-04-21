extends Node3D

const TILE_SIZE := 1.62
const DEF_HEX_TILE = preload("res://hex_cell.tscn")

@export_range(0.0, 40.0) var grid_size := 10.0
@export var player: Node3D
@export var move_speed: float

@onready var hex_grid: Node3D = $HexGrid
var nav_move_path: PackedVector3Array

#ASTAR
const FORMAT_KEY_POINT := "%d,%d"
@export var use_astar: bool
var  astar_move_path: PackedVector2Array
var astar = AStar2D.new()
var points := {}
var point_from_hex := {}
var hex_from_point := {}

func _ready() -> void:
	_generate_grid()
	_connect_points()

func _physics_process(delta: float) -> void:
	if player == null:
		return
		
	_move_player(delta)
	_move_player_astar(delta)

func _generate_grid()->void:
	for x in range(-grid_size, grid_size):
		var tile_coordinates := Vector2.ZERO
		
		tile_coordinates.x = x * TILE_SIZE * 3/2
	
		var delta_y = 0 if x % 2 == 0 else TILE_SIZE * sqrt(3)/2
		
		for y in range(-grid_size, grid_size):
			var tile = DEF_HEX_TILE.instantiate()
			hex_grid.add_child(tile)
			tile_coordinates.y = y * TILE_SIZE * sqrt(3) + delta_y
			tile.translate(Vector3(tile_coordinates.x, 0, tile_coordinates.y))
			
			var pos_point = _add_point(tile.global_position)
			
			point_from_hex[pos_point] = Vector2(x, y)
			hex_from_point[FORMAT_KEY_POINT % [x, y]] = pos_point
			
			tile.pos_point = "{1} ({0})".format(["",FORMAT_KEY_POINT % [x, y]])

func _add_point(tile_position: Vector3)->String:
	var id = astar.get_available_point_id()
	astar.add_point(id, Vector2(tile_position.x, tile_position.z))
	
	var pos_str = world_to_astar(tile_position)
	
	points[pos_str] = id
	
	return pos_str
		
func _connect_points()->void:
	var axial_direction_vectors = [Vector2(-1, -1), Vector2(0, -1), Vector2(+1, -1),
								Vector2(-1, 0), Vector2(0, +1), Vector2(+1, 0),]
	
	for point in points:
		var pos_str = point.split(",")
		var world_pos := Vector2(pos_str[0].to_int(), pos_str[1].to_int())
		
		#var hex_pos = point_from_hex[world_to_astar(Vector3(world_pos.x, 0, world_pos.y), true)]
		var hex_pos = point_from_hex[point]
		
		for axil_dir in axial_direction_vectors:
			var potential_neighbor = hex_pos + axil_dir
			if hex_from_point.has(FORMAT_KEY_POINT % [potential_neighbor.x, potential_neighbor.y]):
				var currrnt_id = points[point]
				var neighbor_id = points[hex_from_point.get(FORMAT_KEY_POINT % [potential_neighbor.x, potential_neighbor.y])]
				
				if ! astar.are_points_connected(currrnt_id, neighbor_id):
					astar.connect_points(currrnt_id, neighbor_id)
					
func _move_player(delta: float)->void:
	if ! nav_move_path.is_empty():
		var direction := Vector3()
		var step := delta * move_speed
		
		var destination := nav_move_path[0]
		
		direction = Vector3(destination.x, 0.0, destination.z) - player.position
		
		if step > direction.length():
			step = direction.length()
			nav_move_path.remove_at(0)
			
		direction.y = 0.0
			
		var diff = direction.normalized() * step
		
		var new_rot = lerp(player.rotation.y, atan2(-direction.normalized().x, -direction.normalized().z), 3 * delta)
		
		if abs(new_rot - player.rotation.y) < 0.0005:
			var look_at_point := player.position + direction.normalized()
			player.look_at(look_at_point, Vector3.UP)
		else:
			player.rotation.y = new_rot
			
		player.position += diff

func _move_player_astar(delta: float)->void:
	var direction := Vector3()
	var step := delta * move_speed
		
	if ! astar_move_path.is_empty():
		var destination := astar_move_path[0]
		
		if astar_move_path.size() > 1:
			destination += astar_move_path[1]
			destination = destination / 2.0
			
		direction = Vector3(destination.x, 0.0, destination.y) - player.position
		
		if step > direction.length():
			step = direction.length()
			astar_move_path.remove_at(0)
			
		direction.y = 0.0
			
		var diff = direction.normalized() * step
		
		var new_rot = lerp(player.rotation.y, atan2(-direction.normalized().x, -direction.normalized().z), 2 * delta)
		
		if abs(new_rot - player.rotation.y) < 0.0005:
			var look_at_point := player.position + direction.normalized()
			player.look_at(look_at_point, Vector3.UP)
		else:
			player.rotation.y = new_rot
			
		player.position += diff
		
func _on_click_area_input_event(camera: Node, event: InputEvent, pos: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if use_astar:
			astar_move_path = find_path(player.position, pos)
			pass
		else :
			var map := get_world_3d().navigation_map
			var target_point := NavigationServer3D.map_get_closest_point(map, pos)
		
			if player != null:
				nav_move_path = NavigationServer3D.map_get_path(map, player.position, target_point, true)

func find_path(from: Vector3, to: Vector3)->Array:
	var start_id = astar.get_closest_point(Vector2(from.x, from.z))
	var end_id   = astar.get_closest_point(Vector2(to.x, to.z))
	return astar.get_point_path(start_id, end_id)

func world_to_astar(world_point: Vector3, is_normalized: bool = false)->String:
	var x; var z
	if is_normalized:
		x = round(world_point.x)
		z = round(world_point.z)
	else:
		x = round(world_point.x*100)
		z = round(world_point.z*100)
	
	return FORMAT_KEY_POINT % [x, z]
