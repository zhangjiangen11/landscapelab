extends Node
class_name AbstractRequestHandler

#
# Base class for all request handlers. Each request handler implements the handling and answering of a certain request
# (specified via protocol_keyword). This protocol_keyword needs to be set by the specific subclass.
#
# Request handlers automatically register themselves with the CommunicationServer, so there is no need for any global
# access or polling in specialized classes - these should be implemented as normal local nodes.
#

var protocol_keyword = null # each subclass has to set this to identify which requests are handled
var parameter_list = {}  # FIXME: do we need this? might be practical for documentation and validation
var _server = CommunicationServer  # internal reference to the singleton

func _ready():
	logger.debug("registering %s" % [self.protocol_keyword])
	assert(!self.protocol_keyword.is_empty()) #,"AbstractRequestHandler is an abstract class - it must not be initialized")
	if not self._server.register_handler(self):
		logger.error("Could not register keyword {}".format(self.protocol_keyword))


func _exit_tree():
	self._server.unregister_handler(self)


func handle_request(_request: Dictionary) -> Dictionary:
	assert(!self.protocol_keyword.is_empty()) #,"AbstractRequestHandler.handle_request has to be implemented")
	return {}


# FIXME: in this case we probably can not use the same protocol keyword?
func send_request(_request: Dictionary, _target=null):
	assert(!self.protocol_keyword.is_empty()) #,"AbstractRequestHandler.handle_request has to be implemented")


# this is the callback for the answer from the send_request
func on_answer(_answer: Dictionary, _from):
	assert(!self.protocol_keyword.is_empty()) #,"AbstractRequestHandler.handle_request has to be implemented")


# this is an event handler sent to the request handlers before the server removes this request handler
func on_server_remove():
	self._server = null
