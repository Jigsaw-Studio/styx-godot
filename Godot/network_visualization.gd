extends Node

class_name NetworkVisualization

func calculate_top_traffic(api_endpoint, data_array) -> Dictionary:
    var traffic_dict: Dictionary = {}

    for entry in data_array:
        var address: String = ""
        if api_endpoint == "raw":
            address = entry["remote"]
            if "address" in entry.keys():
                address = entry["address"]
        elif api_endpoint == "remote":
            address = entry["address"]
        var total_traffic = entry["sent"] + entry["received"]
        traffic_dict[address] = total_traffic

    # Convert the dictionary to an array of key-value pairs and sort it
    var sorted_traffic: Array = traffic_dict.keys()
    sorted_traffic.sort_custom(func(a, b):
        return traffic_dict[a] > traffic_dict[b]  # Sort in descending order
    )

    var top_traffic: Dictionary = {}
    for i in range(min(10, sorted_traffic.size())):
        var key = sorted_traffic[i]
        top_traffic[key] = traffic_dict[key]

    return top_traffic

# Function to visualize the data as 3D columns
func visualize_data(traffic_data) -> void:
    # Ensure ColumnsNode exists or create it dynamically
    var columns_node: Node = get_node_or_null("ColumnsNode")
    if columns_node == null:
        columns_node = Node3D.new()  # Use Node3D, Spatial, or Node depending on your scene type
        columns_node.name = "ColumnsNode"
        add_child(columns_node)

    if traffic_data.size() == 0:
        print("No traffic data to visualize.")
        return

    var max_traffic: int = 0
    # Find the maximum traffic to scale the columns
    for traffic in traffic_data.values():
        if traffic > max_traffic:
            max_traffic = traffic

    var index: int = 0
    for address in traffic_data.keys():
        var total_traffic = traffic_data[address]
        var height_ratio: float = float(total_traffic) / float(max_traffic)

        # Load the column script
        var column_script = load("res://column_api.gd")
        if column_script == null:
            print("Error: Script not loaded properly.")
            return

        # Create a new instance of the column script (which extends MeshInstance3D)
        var column = column_script.new()
        if column == null:
            print("Error: Could not create instance of the column script.")
            return

        # Adjust the mesh size based on the height ratio
        if column.mesh != null:
            column.mesh.size = Vector3(0.1, height_ratio * 10, 0.1)  # Scale height by the ratio
        else:
            print("Error: Mesh not initialized properly.")

        # Set the position of the column in the scene
        column.transform.origin = Vector3(index * 0.2, height_ratio * 5 - 2, 7)

        # Set the address for the column
        column.domain_name = address

        # Add the column to the dynamically created ColumnsNode
        columns_node.add_child(column)

        index += 1
