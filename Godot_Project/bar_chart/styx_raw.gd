extends Node

var styx_api

func _ready() -> void:
	styx_api = StyxApi.new()
	styx_api.init("raw")
	add_child(styx_api)

	# Create a timer to repeat the API request every 2 seconds
	var timer = Timer.new()
	timer.set_wait_time(2.0)  # 2 seconds interval
	timer.set_one_shot(false)  # Keep repeating
	add_child(timer)

	# Connect and start the timer
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	timer.start()

	# Perform the first request immediately
	styx_api.send_request()

func _on_timer_timeout() -> void:
	print("Timer timeout reached, sending request.")
	styx_api.send_request()
