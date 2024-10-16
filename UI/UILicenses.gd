extends ItemList


var current_index := 0


# Called when the node enters the scene tree for the first time.
func _ready():
	for license in Licenses.licenses:
		add_license(Licenses.licenses[license])
		
	Licenses.connect("license_added",Callable(self,"add_license"))
	Licenses.connect("license_removed",Callable(self,"remove_license"))
	connect("item_activated",Callable(self,"popup_details"))


func add_license(license):
	add_item(license.to_string())
	set_item_metadata(current_index, license)
	current_index += 1


func popup_details(idx: int):
	$AcceptDialog.window_title = get_item_metadata(idx).acronym
	$AcceptDialog.dialog_text = get_item_metadata(idx).additional_info
	$AcceptDialog.popup()
