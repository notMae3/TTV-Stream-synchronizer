extends Control

# example values
# yt caPHvIPqzx8
# yt HLaxxqna1Rc

@onready var ErrorBanner = preload("res://ErrorBanner.tscn")
var currently_shown_error_banner = null

signal just_unfocused_text_field(node)


var credentials_file_path = "./credentials.json"
var api_credentials : Dictionary

var generate_twitch_api_access_token_file_path = "./support exes/generate_twitch_api_access_token/generate_twitch_api_access_token.exe"
var generate_twitch_api_access_token_thread : Thread
var generate_twitch_api_access_token_return_value = {}
var generate_twitch_api_access_token_just_finished = false
signal finished_generating_twitch_api_access_token

var fetch_stream_data_file_path = "./support exes/fetch_stream_information/fetch_stream_information.exe"
var fetch_stream_data_thread : Thread
var fetch_stream_data_return_value = {}
var fetch_stream_data_just_finished = false
signal finished_fetching_stream_data

signal timestamp_stick_pressed(timestamp_data)

func _input(event):
	if event.is_action_pressed("ui_text_submit") and not get_viewport().gui_get_focus_owner() is LineEdit:
		$InputSection._on_submit_button_pressed()
	
	if event.is_action_pressed("unfocus text field") and get_viewport().gui_get_focus_owner() is LineEdit:
		just_unfocused_text_field.emit(get_viewport().gui_get_focus_owner())
		get_viewport().gui_get_focus_owner().release_focus()
	
	if event.is_action_pressed("tab") and get_viewport().gui_get_focus_owner() is LineEdit:
		just_unfocused_text_field.emit(get_viewport().gui_get_focus_owner())


func _ready():
	api_credentials = fetch_api_credentials_from_file()

func _process(_delta):
	if generate_twitch_api_access_token_just_finished:
		generate_twitch_api_access_token_just_finished = false
		finished_generating_twitch_api_access_token.emit()
	if fetch_stream_data_just_finished:
		fetch_stream_data_just_finished = false
		finished_fetching_stream_data.emit()

func fetch_api_credentials_from_file():
	# if file doesnt exist then create it and return default values
	if not FileAccess.file_exists(credentials_file_path):
		FileAccess.open(credentials_file_path, FileAccess.WRITE)
	
	# otherwise open the file and try to return its data
	# if failed then return default values
	else:
		var file = FileAccess.open(credentials_file_path, FileAccess.READ)
		var JSON_instance = JSON.new()
		var error = JSON_instance.parse(file.get_as_text())
		
		if error == OK:
			return JSON_instance.data
	
	# return default values
	return {
		"clientID": "",
		"clientSecret": "",
		"accessToken": "",
		"accessToken expiry timestamp": 0,
		"apiKey": ""
	}

func save_api_credentials_to_file():
	var file = FileAccess.open(credentials_file_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(api_credentials))


# thread function
func _generate_twitch_api_access_token():
	var std_out_err = []
	var exe_error = OS.execute(generate_twitch_api_access_token_file_path, ["-clientID", api_credentials["clientID"], "-clientSecret", api_credentials["clientSecret"]], std_out_err, true)
	
	if exe_error != OK:
		call_deferred("throw_error", "Unknown error occured when generating accessToken")
		return
	
	var result = std_out_err[0]
	if result.begins_with("Error : "):
		call_deferred("throw_error", "Api access token error: " + result.right(len(result) - len("Error : ")))
	
	else:
		result = result.replace("'", '"')
		var JSON_instance = JSON.new()
		var JSON_error = JSON_instance.parse(result)
		
		if JSON_error != OK:
			call_deferred("throw_error", "Error parsing JSON return data when generating accessToken")
		else:
			generate_twitch_api_access_token_return_value = JSON_instance.data
	
	generate_twitch_api_access_token_just_finished = true


# thread function
func _fetch_stream_data(input_values):
	var stream_1 = input_values["stream 1"]
	var stream_2 = input_values["stream 2"]
	
	# example inp
	# { "stream 1": { "platform": "yt", "value": "123" }, "stream 2": { "platform": "ttv", "value": "abc" }, "timestamp": { "hours": 3, "minutes": 4, "seconds": 4, "key": "HH:MM:SS", "relative to": "Stream 1" } }
	# { "accessToken": "abc123", "accessToken expiry timestamp": 1720221113.628, "apiKey": "r", "clientID": "e", "clientSecret": "f" }
	# note: accessToken expiry timestamp was checked in the submit button check_if_should_throw_error func  so no need to check it here
	
	# -yt ENXtjz8EMxs -ttv 2180802166 -clientID zew526hmunzkzourkxgtqj2nihxe56 -accessToken 3toj0iwg194oqin0ypfiu2sqenerlh -apiKey AIzaSyC7_E7jgCc2g1D72FcS_ywkgprZWTy-pl8
	
	var args = [
		"-%s" % [stream_1["platform"]], stream_1["value"],
		"-%s" % [stream_2["platform"]], stream_2["value"],
		"-clientID", api_credentials["clientID"],
		"-accessToken", api_credentials["accessToken"],
		"-apiKey", api_credentials["apiKey"]
	]
	
	var std_out_err = []
	var exe_error = OS.execute(fetch_stream_data_file_path, args, std_out_err, true)
	
	if exe_error != OK:
		call_deferred("throw_error", "Unknown error occured when fetching stream data")
		return
	
	var result = std_out_err[0]
	if result.begins_with("Error : "):
		call_deferred("throw_error", "Stream data error: " + result.right(len(result) - len("Error : ")))
	
	else:
		result = result.replace("'", '"')
		var JSON_instance = JSON.new()
		var JSON_error = JSON_instance.parse(result)
		
		if JSON_error != OK:
			call_deferred("throw_error", "Error parsing JSON return data when fetching stream data")
		else:
			fetch_stream_data_return_value = JSON_instance.data
	
	fetch_stream_data_just_finished = true


func throw_error(message):
	# prevents multiple error banners from existing and overlapping eachother
	if currently_shown_error_banner != null:
		currently_shown_error_banner.queue_free()
	
	var error_banner = ErrorBanner.instantiate()
	error_banner.text = message
	add_child(error_banner)
	
	currently_shown_error_banner = error_banner



func format_time_til_timestamp(unix_timestamp) -> String:
	# dont allow negative values
	var time_delta = max(0, unix_timestamp - Time.get_unix_time_from_system())
	
	return format_seconds(time_delta)

func format_seconds(seconds) -> String:
	var hours = floor(seconds/3600.0)
	seconds -= hours * 3600.0
	var minutes = floor(seconds/60.0)
	seconds -= minutes * 60.0
	seconds = floor(seconds)
	
	return str(hours).lpad(2, "0") + ":" + str(minutes).lpad(2, "0") + ":" + str(seconds).lpad(2, "0")


# Threads must be disposed (or "joined"), for portability.
func _exit_tree():
	if generate_twitch_api_access_token_thread != null and generate_twitch_api_access_token_thread.is_alive():
		generate_twitch_api_access_token_thread.wait_to_finish()
	if fetch_stream_data_thread != null and fetch_stream_data_thread.is_alive():
		fetch_stream_data_thread.wait_to_finish()







