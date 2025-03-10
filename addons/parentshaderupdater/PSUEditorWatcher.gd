# Used to automatically update Materials at runtime when a Shader file is saved.
# EditorPlugin (PSUEditorWatcher) detects when any resource is saved, if it's a Shader, sends message via inner class (PSUEditorCommunicator)'s EditorDebuggerPlugin "session", which is received by (PSUManager).
# PSUManager then triggers Material Gathering on the Gatherers (which need to be added as Children of Nodes in the scene tree), then updates Materials using the saved Shader file.
# PSUManager is added as auto-load singleton from here.
#
# To implement in any listener, use the following - but careful, seems only one Node can register_message_capture!
# Currently implemented in PSUManager.
#
#	func _ready():
#		EngineDebugger.register_message_capture("MessageStringFromSender", FunctionToCall)

@tool
extends EditorPlugin

class PSUEditorCommunicator extends EditorDebuggerPlugin:
	var session_id: int
	var session: EditorDebuggerSession
	var debugtext: RichTextLabel

	func _setup_session(generated_session_id: int) -> void:
		session_id = generated_session_id
		session = get_session(session_id)
		session.started.connect(func (): print("PSUEditorCommunicator: Session '", session_id, "' started."))
		session.stopped.connect(func (): print("PSUEditorCommunicator: Session '", session_id, "' stopped."))

		# Add a new tab to Debugger Session UI with text field.
		var label = Label.new()
		label.name = "PSUEditorCommunicator"
		label.text = "Session ID: " + var_to_str(session_id)
		debugtext = RichTextLabel.new()
		debugtext.custom_minimum_size.y = 300
		var boxcontainer := VBoxContainer.new()
		boxcontainer.name = "PSU | Resource Saved"
		boxcontainer.add_child(label)
		boxcontainer.add_child(debugtext)
		session.add_session_tab(boxcontainer)
		
	# Called by Watcher, who has necessary infos. Data is [path, classname] of saved resource.
	func message(message_string: String, data:Array[String]):
		get_session(session_id).send_message(message_string, data)
		debugtext.text += "\n- Message String: '{}'   Data: ['{}', '{}']".format(
			[message_string, data[0], data[1]], "{}"
			)


var communicator: PSUEditorCommunicator
var debug_print: bool = false # Use this to quickly disable Output printing (Reload Plugin!)


func _enter_tree() -> void:
	add_autoload_singleton("PSUManager", "res://addons/parentshaderupdater/PSUManager.gd")
	communicator = PSUEditorCommunicator.new()
	resource_saved.connect(_on_resource_saved) # Connect to EditorPlugin's Resource_Saved signal.
	add_debugger_plugin(communicator)


func _exit_tree() -> void:
	resource_saved.disconnect(_on_resource_saved) # Disconnect from EditorPlugin's Resource_Saved signal.
	remove_debugger_plugin(communicator)


# Generic func call on any saved resource, differentiates based on resource class (for future exendability).
func _on_resource_saved(res) -> void:
	var resource_path: String = res.resource_path
	var resource_class: String = res.get_class()
		
	if resource_class == "Shader":
		_on_shader_saved(resource_path, resource_class) # Call func to trigger Shader specific messaging.
		return
	else:
		if debug_print: print("PSUEditorWatcher: Saved '", resource_class, "' at '", resource_path, "' -> not a Shader. Doing nothing...")
		return


# Specific func call on Shader type resources, send message via PSUEditorCommunicator subclass that can then be captured by PSUManager to trigger shader update.
func _on_shader_saved(res_path, res_class):
	communicator.message("res_shader_saved:done", [res_path, res_class])	# Colon and any string after it are required, so listener detects message correctly.
	if debug_print: print("PSUEditorWatcher: Saved '", res_class, "' at '", res_path, "' - messaging PSUManager.")
	return
