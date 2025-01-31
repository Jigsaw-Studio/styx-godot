extends TextureButton

func _pressed():
    Input.action_press("home")
    await get_tree().create_timer(0.1).timeout  # Small delay
    Input.action_release("home")
