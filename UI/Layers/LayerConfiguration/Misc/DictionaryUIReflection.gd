extends VBoxContainer


func _ready():
	$AddField.pressed.connect(_on_add_field)


func _on_add_field():
	var hbox = HBoxContainer.new()
	hbox.add_child(LineEdit.new())
	hbox.add_child(LineEdit.new())
	
	add_child(hbox)


func get_values():
	var values_dict: Dictionary = {}
	for child in get_children():
		if child is HBoxContainer:
			var key = child.get_child(0).text
			var val = child.get_child(1).text
			values_dict[key] = val
	
	return values_dict


func set_values(values_dict):
	var i = 0
	
	for child in get_children():
		if child is HBoxContainer:
			child.get_child(0).text = values_dict.keys()[i]
			child.get_child(1).text = values_dict.values()[i]
			
			i += 1
