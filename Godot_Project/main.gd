extends Node3D

var xr_interface : XRInterface
var passthrough_enabled : bool = false
var is_running_in_web : bool = OS.get_name() == "Web" or OS.get_name() == "HTML5"

# Called when the node enters the scene tree for the first time.
func _ready():

    if not is_running_in_web:
        $WebCanvasLayer.visible = false
        
        xr_interface = XRServer.find_interface("OpenXR")
        if xr_interface and xr_interface.is_initialized():
            print("OpenXR initialized")
            
            # Turn off v-sync!
            DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

            get_viewport().use_xr = true

            passthrough_enabled = enable_passthrough()
        else:
            print("OpenXR not initialized, please check if your headset is connected")

    else:        
        $WebCanvasLayer.visible = true
    
        xr_interface = XRServer.find_interface("WebXR")
        if xr_interface:
            print("WebXR initialized")

            $WebCanvasLayer/WebButton.pressed.connect(self._on_button_pressed)
            # WebXR uses a lot of asynchronous callbacks, so we connect to various
            # signals in order to receive them.
            xr_interface.session_supported.connect(self._webxr_session_supported)
            xr_interface.session_started.connect(self._webxr_session_started)
            xr_interface.session_ended.connect(self._webxr_session_ended)
            xr_interface.session_failed.connect(self._webxr_session_failed)

            # This returns immediately - our _webxr_session_supported() method
            # (which we connected to the "session_supported" signal above) will
            # be called sometime later to let us know if it's supported or not.
            #xr_interface.is_session_supported("immersive-vr")
            xr_interface.is_session_supported("immersive-ar")

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

func _webxr_session_supported(session_mode: String, supported: bool) -> void:
    if session_mode == 'immersive-vr':
        if supported:
            $WebCanvasLayer.visible = true
        else:
            OS.alert("Your browser doesn't support VR")
    elif session_mode == 'immersive-ar':
        if supported:
            $WebCanvasLayer.visible = true
        else:
            OS.alert("Your browser doesn't support AR")
 
func _on_button_pressed() -> void:
    # Whether we want an immersive VR session ('immersive-vr'),
    # as opposed to AR ('immersive-ar'),
    # or a simple 3DoF viewer ('viewer').
    #xr_interface.session_mode = 'immersive-vr'
    xr_interface.session_mode = 'immersive-ar'
    # 'bounded-floor' is room scale, 'local-floor' is a standing or sitting
    # experience (it puts you 1.6m above the ground if you have 3DoF headset),
    # whereas as 'local' puts you down at the ARVROrigin.
    # This list means it'll first try to request 'bounded-floor', then
    # fallback on 'local-floor' and ultimately 'local', if nothing else is
    # supported.
    xr_interface.requested_reference_space_types = 'bounded-floor, local-floor, local'
    # In order to use 'local-floor' or 'bounded-floor' we must also
    # mark the features as required or optional.
    xr_interface.required_features = 'local-floor'
    xr_interface.optional_features = 'bounded-floor'
 
    # Position of XROrigin3D is getting reset and the perspective
    # falls through the floor so we manually place it back above at 1.6m
    var xr_origin = get_node_or_null("XROrigin3D")
    if xr_origin and xr_origin is Node3D:
        var xform = xr_origin.global_transform
        xform.origin.y = 1.6
        xr_origin.global_transform = xform

    # This will return false if we're unable to even request the session,
    # however, it can still fail asynchronously later in the process, so we
    # only know if it's really succeeded or failed when our
    # _webxr_session_started() or _webxr_session_failed() methods are called.
    if not xr_interface.initialize():
        OS.alert("Failed to initialize WebXR")
        return
 
func _webxr_session_started() -> void:
    $WebCanvasLayer.visible = false
    # This tells Godot to start rendering to the headset.
    get_viewport().use_xr = true
    
    passthrough_enabled = enable_passthrough()

    # This will be the reference space type you ultimately got, out of the
    # types that you requested above. This is useful if you want the game to
    # work a little differently in 'bounded-floor' versus 'local-floor'.
    print ("Reference space type: " + xr_interface.reference_space_type)
 
func _webxr_session_ended() -> void:
    $WebCanvasLayer.visible = true
    # If the user exits immersive mode, then we tell Godot to render to the web
    # page again.
    get_viewport().use_xr = false
 
func _webxr_session_failed(message: String) -> void:
    OS.alert("Failed to initialize: " + message)
