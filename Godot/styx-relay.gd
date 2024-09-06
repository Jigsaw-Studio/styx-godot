extends Node

var network_visualization = preload("res://network_visualization.gd")
var nv = null

var udp_client: PacketPeerUDP = PacketPeerUDP.new()
var packet_fragments := {}
var expected_fragments := {}

var server_ip: String = "172.16.100.1"
var server_port: int = 8192
var api_endpoint: String = "remote"
var traffic_data: Dictionary = {}

func _ready() -> void:
    nv = network_visualization.new()
    add_child(nv)
    # Create and bind the UDP client to any available port
    var bind_result: int = udp_client.bind(0)
    if bind_result != OK:
        print("Failed to bind UDP client.")
        return

    send_request()

func send_request():
    var json_data: Dictionary = {"GET": "/api/v1/" + api_endpoint + "?relative=1h"}
    var json_str: String = JSON.stringify(json_data)

    # Connect to the server's IP and port
    udp_client.connect_to_host(server_ip, server_port)

    # Convert to bytes and send the UDP packet
    var packet: PackedByteArray = json_str.to_utf8_buffer()
    var sent: int = udp_client.put_packet(packet)
    if sent == OK:
        print("Sent:", json_str)
    else:
        print("Failed to send request.")

func _process(_delta):
    # Continuously check for incoming packets
    receive_response()

func receive_response():
    while udp_client.get_available_packet_count() > 0:
        var packet: PackedByteArray = udp_client.get_packet()
        var response: String = packet.get_string_from_utf8()

        # Parse the fragment
        var delimiter_index: int = response.find(":")
        if delimiter_index == -1:
            print("Received malformed packet: %s" % response)
            continue

        var header: String = response.substr(0, delimiter_index)
        var body: String = response.substr(delimiter_index + 1)

        # Parse the header (format: "fragment_num/total_fragments")
        var fragment_info: PackedStringArray = header.split("/")
        if fragment_info.size() != 2:
            print("Received malformed packet header: %s" % header)
            continue

        var fragment_num: int = int(fragment_info[0])
        var total_fragments: int = int(fragment_info[1])

        # Store the fragment
        if !packet_fragments.has(fragment_num):
            packet_fragments[fragment_num] = body

        # Check if all fragments have been received
        if packet_fragments.size() == total_fragments:
            var complete_response: String = ""
            for i in range(1, total_fragments + 1):
                complete_response += packet_fragments[i]

            # All fragments received, process the response
            _on_request_completed(null, 200, [], complete_response)

            # Clear stored fragments for the next message
            packet_fragments.clear()

# Function to handle the completion of the HTTP request
func _on_request_completed(_result, response_code, _headers, body):
    if response_code == 200:
        var json = JSON.new()

        var json_result = json.parse(body)

        if json_result == OK:
            var parsed_data = json.get_data()
            if parsed_data.size() > 0:
                traffic_data = nv.calculate_top_traffic(api_endpoint, parsed_data)
                print("Traffic Data:", traffic_data)
                nv.visualize_data(traffic_data)
            else:
                print("No data found in the JSON response")
        else:
            print("Failed to parse JSON: ", json.error_string)
    else:
        print("Request failed with response code: ", response_code)
