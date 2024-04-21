extends Node3D

@onready var hex_mesh: MeshInstance3D = $Model/Circle
@onready var label: Label3D = $Label3D
var pos_point

func _ready() -> void:
	await(get_tree().process_frame)
	
	hex_mesh.material_override = StandardMaterial3D.new()
	hex_mesh.material_override.albedo_color = Color(randf(), randf(), randf())
	
	label.text = pos_point
