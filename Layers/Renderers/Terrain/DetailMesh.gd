extends MeshInstance3D

var size = 100

var previous_player_position := Vector3.ZERO
var min_load_distance := 1.0


func _ready():
	var vp = preload("res://Layers/Renderers/LIDOverlay/LIDOverlayViewport.tscn").instantiate()
	vp.get_node("LIDViewport").size = Vector2(size * 2.0, size * 2.0)  # 0.5m resolution
	vp.get_node("LIDViewport/CameraRoot/LIDCamera").size = size
	add_child(vp)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Only do an update if the player has moved sufficiently since last frame
	if previous_player_position.distance_squared_to(get_parent().position_manager.center_node.position) < min_load_distance: return
	
	position.x = get_parent().position_manager.center_node.position.x
	position.z = get_parent().position_manager.center_node.position.z
	
	# FIXME: This actually depends on the terrain chunk resolution at the highest LOD.
	#  We use 2.0 here because at the highest LOD, one quad covers 2x2 meters.
	position = position.snappedf(2.0)
	
	var origin_x = get_parent().center[0] - size / 2.0 + position.x
	var origin_z = get_parent().center[1] + size / 2.0 - position.z
	
	var heightmap = get_parent().layer_composition.render_info.height_layer.get_image(
		origin_x,
		origin_z,
		size,
		size / 2,
		0
	)
	
	var texture = get_parent().layer_composition.render_info.texture_layer.get_image(
		origin_x,
		origin_z,
		size,
		size,
		0
	)
	
	var landuse = get_parent().layer_composition.render_info.landuse_layer.get_image(
		origin_x,
		origin_z,
		size,
		size,
		0
	)
	
	material_override.set_shader_parameter("use_landuse_overlay", true)
	material_override.set_shader_parameter("make_hole", false)
	material_override.set_shader_parameter("size", size)
	
	material_override.set_shader_parameter("heightmap", heightmap.get_image_texture())
	material_override.set_shader_parameter("orthophoto", texture.get_image_texture())
	material_override.set_shader_parameter("landuse", landuse.get_image_texture())
	material_override.set_shader_parameter("landuse_overlay", get_node("LIDOverlayViewport/LIDViewport").get_texture())
	
	previous_player_position = get_parent().position_manager.center_node.position
