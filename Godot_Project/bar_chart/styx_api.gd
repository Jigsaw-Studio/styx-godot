extends Node

class_name StyxApi

var is_running_in_web : bool = OS.get_name() == "Web" or OS.get_name() == "HTML5"

# Load the network visualization script
var network_visualization = preload("res://bar_chart/network_visualization.gd")
var nv = null

# Network client setup
var udp_client: PacketPeerUDP = PacketPeerUDP.new()
var tcp_client: WebSocketPeer = WebSocketPeer.new()
var packet_fragments := {}
var expected_fragments := {}

# Define server settings
var server_ip: String = "172.16.100.1"
var server_port_udp: int = 8192
var server_port_tcp: int = 443

# Endpoints
var endpoints: Dictionary = {
    "remote": {
        "api_path": "/api/v1/remote?relative=1h",
        "calculate": "calculate_traffic_remote",
        "visualize": "visualize_data_remote",
        "color": [0, 0, 1], # blue
        "transform": [0, 0, -1],
        "label": true },
    "raw": {
        "api_path": "/api/v1/raw?relative=10s",
        "calculate": "calculate_traffic_raw",
        "visualize": "visualize_data_raw",
        "color": [1, 0, 0], # red
        "transform": [0, 0, 0],
        "label": false }
}

var current_endpoint: String = ""

# Initialize styx_api with a specific endpoint
func init(endpoint: String) -> void:
    current_endpoint = endpoint
    nv = network_visualization.new()
    add_child(nv)

    if not is_running_in_web:
        # Create and bind the UDP client to any available port
        var bind_result: int = udp_client.bind(0)
        if bind_result != OK:
            print("Failed to bind UDP client.")
    else:
        var endpoint_data = endpoints.get(current_endpoint)
        var url = "wss://%s%s" % [server_ip, endpoint_data.api_path]
        var connect_result = tcp_client.connect_to_url(url, TLSOptions.client_unsafe())
        if connect_result == OK:
            print("Connected to WebSocket server:", url)
        else:
            print("Failed to connect to WebSocket server. Error:", connect_result)

func send_request() -> void:
    var endpoint_data = endpoints.get(current_endpoint)
    if endpoint_data == null:
        print("Endpoint not found:", current_endpoint)
        return

    if not is_running_in_web:
        var json_data: Dictionary = {"GET": endpoint_data.api_path}
        var json_str: String = JSON.stringify(json_data)

        # Send request via UDP
        udp_client.connect_to_host(server_ip, server_port_udp)
        var packet: PackedByteArray = json_str.to_utf8_buffer()
        var sent: int = udp_client.put_packet(packet)
        if sent == OK:
            print("Sent via UDP:", json_str)
        else:
            print("Failed to send request via UDP.")
    else:
        if tcp_client.get_ready_state() == WebSocketPeer.STATE_CLOSED:
            # Get API endpoint via secure TCP WebSocket
            var url = "wss://%s%s" % [server_ip, endpoint_data.api_path]
            var connect_result = tcp_client.connect_to_url(url, TLSOptions.client_unsafe())
            if connect_result == OK:
                print("Connected to WebSocket server:", url)
                set_process(true)
            else:
                print("Failed to connect to WebSocket server. Error:", connect_result)

func _process(_delta):
    if not is_running_in_web:
        receive_udp_response()
    else:
        var state = tcp_client.get_ready_state()
        if state == WebSocketPeer.STATE_OPEN:
            receive_tcp_response()
        elif state == WebSocketPeer.STATE_CLOSING:
            pass
        elif state == WebSocketPeer.STATE_CLOSED:
            var code = tcp_client.get_close_code()
            var reason = tcp_client.get_close_reason()
            print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
            set_process(false) # Stop processing.
        else:
            print("tcp_client.get_ready_state():", state)

func receive_tcp_response():
    while tcp_client.get_available_packet_count():
        var packet: PackedByteArray = tcp_client.get_packet()
        print("packet: ", packet)
        var response: String = packet.get_string_from_utf8()
        print("response: ", response)
        process_response_tcp(response)

func process_response_tcp(response: String):
    _on_request_completed_tcp(null, 200, [], response)

# Function to handle the completion of the HTTP request
func _on_request_completed_tcp(_result, response_code, _headers, body):
    if response_code == 200:
        print("Processing response:", body)
        var endpoint_data = endpoints.get(current_endpoint)
        if endpoint_data != null:
            var calculate_method = endpoint_data.calculate
            var visualize_method = endpoint_data.visualize

            var data: Dictionary = call(calculate_method, body)
            call(visualize_method, data)
        else:
            print("Endpoint configuration not found for", current_endpoint)
    else:
        print("Request failed with response code:", response_code)

func receive_udp_response():
    while udp_client.get_available_packet_count():
        var packet: PackedByteArray = udp_client.get_packet()
        var response: String = packet.get_string_from_utf8()
        process_response_udp(response)

func process_response_udp(response: String):
    # Parse the fragment
    var delimiter_index: int = response.find(":")
    if delimiter_index == -1:
        print("Received malformed packet: %s" % response)
        return

    var header: String = response.substr(0, delimiter_index)
    var body: String = response.substr(delimiter_index + 1)

    # Parse the header (format: "fragment_num/total_fragments")
    var fragment_info: PackedStringArray = header.split("/")
    if fragment_info.size() != 2:
        print("Received malformed packet header: %s" % header)
        return

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
        _on_request_completed_udp(null, 200, [], complete_response)

        # Clear stored fragments for the next message
        packet_fragments.clear()

# Function to handle the completion of the HTTP request
func _on_request_completed_udp(_result, response_code, _headers, body):
    if response_code == 200:
        var json = JSON.new()
        var json_result = json.parse(body)

        if json_result == OK:
            var parsed_data = json.get_data()
            if parsed_data.size() > 0:
                # Call the appropriate method for traffic calculation and visualization
                var endpoint_data = endpoints.get(current_endpoint)
                if endpoint_data != null:
                    var calculate_method = endpoint_data.calculate
                    var visualize_method = endpoint_data.visualize

                    var data: Dictionary = call(calculate_method, parsed_data)
                    call(visualize_method, data)
                else:
                    print("Endpoint configuration not found for", current_endpoint)
            else:
                print("No data found in the JSON response")
        else:
            print("Failed to parse JSON: ", json.error_string)
    else:
        print("Request failed with response code: ", response_code)


func calculate_traffic_remote(parsed_data: Array) -> Dictionary:
    return nv.calculate_traffic_remote(parsed_data)

func calculate_traffic_raw(parsed_data: Array) -> Dictionary:
    return nv.calculate_traffic_raw(parsed_data)

func visualize_data_remote(data: Dictionary) -> void:
    print("Visualizing remote data:", data)
    nv.visualize_data_remote(endpoints.get(current_endpoint), data)

func visualize_data_raw(data: Dictionary) -> void:
    print("Visualizing raw data:", data)
    nv.visualize_data_raw(endpoints.get(current_endpoint), data)
