extends MeshInstance3D

var domain_name: String = ""

# Called when the script instance is created
func _init():
    # Initialize the BoxMesh and assign it to the mesh property
    var box_mesh = BoxMesh.new()
    box_mesh.size = Vector3(0.1, 1.0, 0.1)  # Default size
    mesh = box_mesh

# This function is called when the node is added to the scene
func _ready():
    # Create a StaticBody3D for handling input events
    var static_body = StaticBody3D.new()
    add_child(static_body)

    # Create and add a CollisionShape3D to the StaticBody3D
    var collision_shape = CollisionShape3D.new()
    var box_shape = BoxShape3D.new()
    box_shape.size = mesh.size  # Use the size of the mesh
    collision_shape.shape = box_shape
    static_body.add_child(collision_shape)

    # Enable input picking for the static body
    static_body.input_ray_pickable = true

# Handle the input event (e.g., tap or click)
func _input_event(_viewport, event, _shape_idx):
    if event is InputEventMouseButton and event.is_pressed():
        print("Column tapped: ", domain_name)
        display_domain_name()

# Function to display the domain name and traffic on the side of the column
func display_domain_name():
    # Create a new Label3D for the domain name
    var label = Label3D.new()
    label.text = domain_name

    # Position the label on the side of the column
    label.transform.origin = transform.origin + Vector3(0, 0, -0.06)  # Adjust position as needed

    # Rotate the label to align with the side of the column
    label.transform.basis = Basis(Vector3(0, 1, 0), -PI / 2)  # Rotate 90 degrees counterclockwise

    # Add the label to the column node
    add_child(label)
