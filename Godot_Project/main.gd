extends Node3D

var xr_interface : XRInterface
var passthrough_enabled : bool = false

const TELEPORT_DEMO_SCENE_PATH = "res://scenes/teleport_demo/teleport_demo.tscn"

# Called when the node enters the scene tree for the first time.
func _ready():
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized")

		# Turn off v-sync!
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

		get_viewport().use_xr = true

		passthrough_enabled = enable_passthrough()
	else:
		print("OpenXR not initialized, please check if your headset is connected")

	#if not passthrough_enabled:
		#load_teleport_demo()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func enable_passthrough() -> bool:
	xr_interface = XRServer.primary_interface
	if xr_interface and xr_interface.is_passthrough_supported():
		if !xr_interface.start_passthrough():
			return false
		else:
			var modes: Array = xr_interface.get_supported_environment_blend_modes()
			if xr_interface.XR_ENV_BLEND_MODE_ALPHA_BLEND in modes:
				xr_interface.set_environment_blend_mode(xr_interface.XR_ENV_BLEND_MODE_ALPHA_BLEND)
			else:
				return false

		get_viewport().transparent_bg = true

	return true

func load_teleport_demo():
	# Load the teleport demo scene
	var teleport_demo_scene = load(TELEPORT_DEMO_SCENE_PATH)

	# Instance the teleport demo
	var teleport_demo_instance = teleport_demo_scene.instantiate()

	# Add the teleport demo instance as a child of the Main node
	add_child(teleport_demo_instance)

	# Optionally adjust the position or other properties if needed
	#teleport_demo_instance.translation = Vector3(0, 0, 0)  # Adjust position if necessary
