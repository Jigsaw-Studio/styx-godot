extends MeshInstance3D

var color: Array = [1, 1, 1]  # Default white
var label_enabled: bool = false  # Default no label

func _init(column_color: Array = [1, 1, 1], label_content: String = "", label_show: bool = false):
    self.color = column_color
    self.name = label_content
    self.label_enabled = label_show

    # Initialize the BoxMesh
    var box_mesh = BoxMesh.new()
    box_mesh.size = Vector3(0.1, 1.0, 0.1)  # Set base width and depth (height will be scaled externally)
    mesh = box_mesh

    # Create a new material and set the color
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(color[0], color[1], color[2])

    # Apply the material to the MeshInstance3D (this node)
    self.material_override = material

# This function is called when the node is added to the scene
func _ready():
    # Create a StaticBody3D for handling input events
    var static_body = StaticBody3D.new()
    add_child(static_body)

    # Create and add a CollisionShape3D to the StaticBody3D
    var collision_shape = CollisionShape3D.new()
    var box_shape = BoxShape3D.new()
    box_shape.size = (mesh as BoxMesh).size
    collision_shape.shape = box_shape
    static_body.add_child(collision_shape)

    # Enable input picking for the static body
    static_body.input_ray_pickable = true

    # Display the label if label_show is true
    if self.label_enabled:
        display_domain_name()

# Handle the input event (e.g., tap or click)
func _input_event(_viewport, event, _shape_idx):
    if event is InputEventMouseButton and event.is_pressed():
        print("Column tapped: ", name)
        display_domain_name()

# Function to display the domain name and traffic on the side of the column
func display_domain_name():

    # Create a new Label3D
    var label = Label3D.new()
    label.text = name

   # Rotate the label
    label.transform.basis = Basis(Vector3(0, 1, 0), -PI / 2)

    # Position the label near the column
    var column_height: float = (mesh as BoxMesh).size.y
    label.transform.origin = transform.origin + Vector3(-1.2, column_height, -7)  # Adjust position as needed
    
    # Add the label to the column node
    add_child(label)
