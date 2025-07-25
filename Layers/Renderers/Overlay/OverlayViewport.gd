extends Node3D
class_name OverlayViewport

signal update_done

var has_updated_this_frame = false


# Called when the node enters the scene tree for the first time.
func _ready():
	set_notify_transform(true)


func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		update()


func set_resolution(new_resolution):
	$Viewport.size = Vector2(new_resolution, new_resolution)


func set_size(new_size):
	$Viewport/CameraRoot/Camera.size = new_size


func get_texture():
	return $Viewport.get_texture()


func _process(delta: float) -> void:
	has_updated_this_frame = false


func update():
	if not has_updated_this_frame:
		$Viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		has_updated_this_frame = true
		await get_tree().process_frame
		update_done.emit()
