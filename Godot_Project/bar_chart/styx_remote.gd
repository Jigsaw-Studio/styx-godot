extends Node

func _ready() -> void:
	var styx_api = StyxApi.new()
	styx_api.init("remote")
	add_child(styx_api)
	styx_api.send_request()
