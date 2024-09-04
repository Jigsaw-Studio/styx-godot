extends Node

#var network_visualization = preload("res://network_visualization.gd")
#var nv = null

var udp_client: PacketPeerUDP = PacketPeerUDP.new()
var packet_fragments := {}
var expected_fragments := {}

var server_ip: String = "172.16.100.1"
var server_port: int = 8192
var api_endpoint = "remote"
var traffic_data = {}

func _ready():
    #nv = network_visualization.new()
    # Create and bind the UDP client to any available port
    var bind_result = udp_client.bind(0)
    if bind_result != OK:
        print("Failed to bind UDP client.")
        return

    send_request()

func send_request():
    var json_data = {"GET": "/api/v1/" + api_endpoint + "?relative=1h"}
    var json_str = JSON.stringify(json_data)

    # Connect to the server's IP and port
    udp_client.connect_to_host(server_ip, server_port)

    # Convert to bytes and send the UDP packet
    var packet = json_str.to_utf8_buffer()
    var sent = udp_client.put_packet(packet)
    if sent == OK:
        print("Sent:", json_str)
    else:
        print("Failed to send request.")

#func receive_response():
    #while udp_client.get_available_packet_count() > 0:
        #var packet = udp_client.get_packet()
        #var response = packet.get_string_from_utf8()
        ##print("Received response: %s" % response)
        ##nv.on_request_completed(null, 200, [], response)
        ##nv.visualize_data()
        #_on_request_completed(null, 200, [], response)

func _process(_delta):
    # Continuously check for incoming packets
    receive_response()

func receive_response():
    while udp_client.get_available_packet_count() > 0:
        var packet = udp_client.get_packet()
        var response = packet.get_string_from_utf8()
        
        # Parse the fragment
        var delimiter_index = response.find(":")
        if delimiter_index == -1:
            print("Received malformed packet: %s" % response)
            continue
        
        var header = response.substr(0, delimiter_index)
        var body = response.substr(delimiter_index + 1)

        # Parse the header (format: "fragment_num/total_fragments")
        var fragment_info = header.split("/")
        if fragment_info.size() != 2:
            print("Received malformed packet header: %s" % header)
            continue
        
        var fragment_num = int(fragment_info[0])
        var total_fragments = int(fragment_info[1])
        
        # Store the fragment
        if !packet_fragments.has(fragment_num):
            packet_fragments[fragment_num] = body
        
        # Check if all fragments have been received
        if packet_fragments.size() == total_fragments:
            var complete_response = ""
            for i in range(1, total_fragments + 1):
                complete_response += packet_fragments[i]
            
            # All fragments received, process the response
            #print("Received complete response: %s" % complete_response)
            _on_request_completed(null, 200, [], complete_response)
            
            # Clear stored fragments for the next message
            packet_fragments.clear()

# Function to handle the completion of the HTTP request
func _on_request_completed(_result, response_code, _headers, body):
    if response_code == 200:
        var json = JSON.new()
        
        # Debug: Print the raw JSON data
        #print("Response body: ", body)

        var json_result = json.parse(body)

        if json_result == OK:
            var parsed_data = json.get_data()
            if parsed_data.size() > 0:
                traffic_data = calculate_top_traffic(parsed_data)
                print("Traffic Data:", traffic_data)
                visualize_data()
            else:
                print("No data found in the JSON response")
        else:
            print("Failed to parse JSON: ", json.error_string)
    else:
        print("Request failed with response code: ", response_code)

# Function to calculate the top 10 addresses based on total traffic
func calculate_top_traffic(data_array):
    var traffic_dict = {}
    
    for entry in data_array:
        var address = ""
        if api_endpoint == "raw":
            address = entry["remote"]
            if "address" in entry.keys():
                address = entry["address"]
        elif api_endpoint == "remote":
            address = entry["address"]
        var total_traffic = entry["sent"] + entry["received"]
        traffic_dict[address] = total_traffic

    # Convert the dictionary to an array of key-value pairs and sort it
    var sorted_traffic = traffic_dict.keys()
    sorted_traffic.sort_custom(func(a, b):
        return traffic_dict[a] > traffic_dict[b]  # Sort in descending order
    )

    var top_traffic = {}
    for i in range(min(10, sorted_traffic.size())):
        var key = sorted_traffic[i]
        top_traffic[key] = traffic_dict[key]

    return top_traffic

# Function to visualize the data as 3D columns
func visualize_data():
    # Ensure ColumnsNode exists or create it dynamically
    var columns_node = get_node_or_null("ColumnsNode")
    if columns_node == null:
        columns_node = Node3D.new()  # Use Node3D, Spatial, or Node depending on your scene type
        columns_node.name = "ColumnsNode"
        add_child(columns_node)

    if traffic_data.size() == 0:
        print("No traffic data to visualize.")
        return

    var max_traffic = 0
    # Find the maximum traffic to scale the columns
    for traffic in traffic_data.values():
        if traffic > max_traffic:
            max_traffic = traffic

    var index = 0
    for address in traffic_data.keys():
        var total_traffic = traffic_data[address]
        var height_ratio = float(total_traffic) / float(max_traffic)

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
