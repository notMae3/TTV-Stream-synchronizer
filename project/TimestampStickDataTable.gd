extends Control

@onready var represented_stream = name.right(1)
var is_showing_formatted_values = true

var timestamp_data = {
	"unix": null,
	"unix formatted": null,
	"relative": null,
	"relative formatted": null
}
var url

func config(new_timestamp_data):
	timestamp_data = new_timestamp_data
	
	# cant open live ttv streamer at timestamp since would have to fetch their last
	# stream using the twich api. even then its not guarantied that the last vod
	# is the same as the one thats live
	var is_live_ttv = $/root/main/DataSection.is_live_ttv["stream " + str(represented_stream)]
	if is_live_ttv:
		$Label/OpenStreamUrlButton.disabled = is_live_ttv
		$Label/OpenStreamUrlButton.tooltip_text = "Can't open url of live\ntwitch stream at timestamp" if is_live_ttv else ""
	else:
		$Label/OpenStreamUrlButton.disabled = timestamp_data["relative"] < 0
		$Label/OpenStreamUrlButton.tooltip_text = "Can't open url of stream\nat negative timestamp" if timestamp_data["relative"] < 0 else ""
	
	
	var url_parts = $/root/main/DataSection.stream_url_parts["stream " + str(represented_stream)]
	var relevant_url_func = $/root/main/DataSection.url_funcs[url_parts["platform"]]
	url = relevant_url_func.call(
			url_parts["id"],
			generate_time_str_for_url(
				timestamp_data["relative"],
				url_parts["platform"])
			)
	
	update_labels()

func generate_time_str_for_url(timestamp, platform):
	if platform == "yt":
		return str(floor(timestamp)) + "s"
	
	var h = floor(timestamp / 3600.0) ; timestamp -= h * 3600.0
	var m = floor(timestamp / 60.0)   ; timestamp -= m * 60.0
	var s = floor(timestamp)
	return str(h).lpad(2, "0") + "h" + str(m).lpad(2, "0") + "m" + str(s).lpad(2, "0") + "s"

func update_labels():
	$Data/Unix/LineEdit.text     = str(timestamp_data["unix"     + (" formatted" if is_showing_formatted_values else "")])
	$Data/Relative/LineEdit.text = str(timestamp_data["relative" + (" formatted" if is_showing_formatted_values else "")])
	
	# GO THROUGH THIS
	
	# data section min size

func _on_toggle_format_data_button_pressed():
	is_showing_formatted_values = not is_showing_formatted_values
	update_labels()

func _on_open_stream_url_button_pressed():
	OS.shell_open(url)
