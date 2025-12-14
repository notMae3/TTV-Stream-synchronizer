extends Control

var min_size = Vector2(560, 200)

var is_live_ttv = {
	"stream 1": false,
	"stream 2": false
}
var url_funcs = {
	"ttv": func(id, time_str): return "https://www.twitch.tv/videos/{0}?t={1}".format([id, time_str]),
	"yt" : func(id, time_str): return "https://www.youtube.com/watch?v={0}&t={1}".format([id, time_str]),
}
var stream_url_parts = {
	"stream 1": {"platform": "", "id": 0},
	"stream 2": {"platform": "", "id": 0}
}

func _ready():
	$/root/main.connect("timestamp_stick_pressed", _on_timestamp_stick_pressed)

func clear():
	$StreamsDataSection/Label.visible = true
	$StreamsDataSection/VSeparator.visible = false
	$StreamsDataSection/StreamDataTable1.visible = false
	$StreamsDataSection/StreamDataTable2.visible = false
	
	$TimestampStickSection/Label.visible = true
	$TimestampStickSection/VSeparator.visible = false
	$TimestampStickSection/TimestampStickDataTable1.visible = false
	$TimestampStickSection/TimestampStickDataTable2.visible = false

func config_stream_data(stream_data: Dictionary) -> void:
	# ======================================================
	
	# Example input values:
	
	# { "years": 3, "months": 3, "days": 3, "hours": 3, "minutes": 3, "seconds": 3, "key": "YYYY-MM-DD HH:MM:SS", "relative to": "UTC" }
	
	# {
	# 	"stream 1": {
	# 		"started at timestamp utc": 1718478356,
	# 		"ended or current timestamp utc": 1718500262,
	# 		"uptime": 21906,
	# 		"is live": false,
	# 		"platform": "yt",
	# 		"stream title": "🔴LIVE! REDDIT RECAP THEN ONE GAME VALO THEN GTAV RP! 48 HOUR ELDEN RING STREM STARTING THE 18TH!",
	# 		"streamer name": "Valkyrae",
	# 		"raw input": "HLaxxqna1Rc"
	# 		},
	# 	"stream 2": {
	# 		"started at timestamp utc": 1719259242,
	# 		"ended or current timestamp utc": 1719274620,
	# 		"uptime": 15378,
	# 		"is live": false,
	# 		"platform": "ttv",
	# 		"stream title": "im going to maldtown",
	# 		"streamer name": "Sydeon",
	# 		"raw input": 2180802166
	# 		}
	# 	}
	
	# ======================================================
	
	is_live_ttv["stream 1"] = stream_data["stream 1"]["is live"] and stream_data["stream 1"]["platform"] == "ttv"
	is_live_ttv["stream 2"] = stream_data["stream 2"]["is live"] and stream_data["stream 2"]["platform"] == "ttv"
	
	stream_url_parts["stream 1"]["platform"] = stream_data["stream 1"]["platform"]
	stream_url_parts["stream 1"]["id"]       = stream_data["stream 1"]["raw input"]
	stream_url_parts["stream 2"]["platform"] = stream_data["stream 2"]["platform"]
	stream_url_parts["stream 2"]["id"]       = stream_data["stream 2"]["raw input"]
	
	for stream_num in stream_data:
		var current_data = stream_data[stream_num]
		
		current_data["started at timestamp utc"] = format_unix(current_data["started at timestamp utc"])
		current_data["ended or current timestamp utc"] = format_unix(current_data["ended or current timestamp utc"])
		current_data["uptime"] = format_uptime(current_data["uptime"])
		current_data["platform"] = "Twitch" if current_data["platform"] == "ttv" else "Youtube"
		
		if current_data["platform"] == "Twitch":
			if str(current_data["raw input"]).is_valid_float(): current_data["url"] = "https://www.twitch.tv/videos/" + str(current_data["raw input"])    # ttv vod
			else:                                               current_data["url"] = "https://www.twitch.tv/" + str(current_data["raw input"])           # ttv stream
		else:                                                   current_data["url"] = "https://www.youtube.com/watch?v=" + str(current_data["raw input"]) # yt stream and vod
		
		stream_data[stream_num] = current_data
	
	$StreamsDataSection/StreamDataTable1.data = stream_data["stream 1"]
	$StreamsDataSection/StreamDataTable2.data = stream_data["stream 2"]
	
	$StreamsDataSection/Label.visible = false
	$StreamsDataSection/VSeparator.visible = true
	$StreamsDataSection/StreamDataTable1.visible = true
	$StreamsDataSection/StreamDataTable2.visible = true


func format_unix(timestamp):
	var date_dict = Time.get_datetime_dict_from_unix_time(timestamp)
	var outp_list = [
		# 1722953910
		str(timestamp),
		"\n",
		# 2024-08-06T14:18:30Z
		str(date_dict["year"]) + "-",
		str(date_dict["month"]).lpad(2, "0") + "-",
		str(date_dict["day"]).lpad(2, "0") + "T",
		str(date_dict["hour"]).lpad(2, "0") + ":",
		str(date_dict["minute"]).lpad(2, "0") + ":",
		str(date_dict["second"]).lpad(2, "0") + "Z",
		"\n",
		# 14:18:30 2024-08-06 UTC
		str(date_dict["hour"]).lpad(2, "0") + ":",
		str(date_dict["minute"]).lpad(2, "0") + ":",
		str(date_dict["second"]).lpad(2, "0") + " ",
		str(date_dict["year"]) + "-",
		str(date_dict["month"]).lpad(2, "0") + "-",
		str(date_dict["day"]).lpad(2, "0") + " UTC"
		]
	return "".join(outp_list)

func format_uptime(uptime):
	var date_dict = Time.get_datetime_dict_from_unix_time(uptime)
	var outp_list = [
		str(uptime) + "s",
		"\n",
		str(date_dict["hour"]).lpad(2, "0") + ":",
		str(date_dict["minute"]).lpad(2, "0") + ":",
		str(date_dict["second"]).lpad(2, "0"),
	]
	return "".join(outp_list)


func _on_timestamp_stick_pressed(timestamp_data):
	$TimestampStickSection/Label.visible = false
	$TimestampStickSection/VSeparator.visible = true
	$TimestampStickSection/TimestampStickDataTable1.visible = true
	$TimestampStickSection/TimestampStickDataTable2.visible = true
	
	$TimestampStickSection/TimestampStickDataTable1.config(timestamp_data["stream 1"])
	$TimestampStickSection/TimestampStickDataTable2.config(timestamp_data["stream 2"])
