extends Control

@onready var StreamBoxParent = $StreamBoxParent
@onready var StreamBox_1 = $StreamBoxParent/StreamBox1
@onready var StreamBox_2 = $StreamBoxParent/StreamBox2

var min_size = Vector2(0, 290)

func clear():
	$Label.visible = true
	$StreamBoxParent.visible = false
	$TimestampStickParent.visible = false

func config(timestamp_data: Dictionary, stream_data: Dictionary) -> void:
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
	
	# prerequisite data formatting
	
	var stream_1_data = stream_data["stream 1"]
	var stream_2_data = stream_data["stream 2"]
	
	var min_value = min(
		stream_1_data["started at timestamp utc"],
		stream_2_data["started at timestamp utc"]
	)
	
	# make the timestamps relative to the smallest value
	# also makes the minimum value 0
	stream_1_data["started at relative timestamp"] = stream_1_data["started at timestamp utc"] - min_value
	stream_2_data["started at relative timestamp"] = stream_2_data["started at timestamp utc"] - min_value
	stream_1_data["ended at relative timestamp"] = stream_1_data["ended or current timestamp utc"] - min_value
	stream_2_data["ended at relative timestamp"] = stream_2_data["ended or current timestamp utc"] - min_value
	
	# ----- ----- ----- ----- -----
	
	# turn the custom timestamp the user submitted into a unix timestamp
	
	var custom_timestamp_utc
	match timestamp_data["key"]:
		"HH:MM:SS":
			var relative_timestamp = timestamp_data["hours"]*3600.0 + timestamp_data["minutes"]*60.0 + timestamp_data["seconds"]
			match timestamp_data["relative to"]:
				"stream 1":
					custom_timestamp_utc = stream_1_data["started at timestamp utc"] + relative_timestamp
				"stream 2":
					custom_timestamp_utc = stream_2_data["started at timestamp utc"] + relative_timestamp
		
		"YYYY-MM-DD HH:MM:SS":
			var local_timestamp_at_date = Time.get_unix_time_from_datetime_string("{years}-{months}-{days}T{hours}:{minutes}:{seconds}".format(timestamp_data))
			custom_timestamp_utc = local_timestamp_at_date - Time.get_time_zone_from_system()["bias"]*60
		
		"Seconds":
			match timestamp_data["relative to"]:
				"UTC":
					custom_timestamp_utc = timestamp_data["seconds"]
				"stream 1":
					custom_timestamp_utc = stream_1_data["started at timestamp utc"] + timestamp_data["seconds"]
				"stream 2":
					custom_timestamp_utc = stream_2_data["started at timestamp utc"] + timestamp_data["seconds"]
	
	var custom_relative_timestamp = custom_timestamp_utc - min_value
	
	# ----- ----- ----- ----- -----
	
	# get the value delta
	
	var max_value = max(
		stream_1_data["ended at relative timestamp"],
		stream_2_data["ended at relative timestamp"],
		custom_relative_timestamp
	)
	
	# since the above section effectivly makes the min value 0 its unneccessary
	# to do value_delta = max_value - min_value
	# make it float to allow division with decimal precision
	var value_delta = float(max_value)
	
	# ----- ----- ----- ----- -----
	
	# resize and reposition StreamBox_1
	
	var StreamBox_1_left_edge_x_ratio = stream_1_data["started at relative timestamp"] / value_delta
	var StreamBox_1_left_edge = StreamBox_1_left_edge_x_ratio * StreamBoxParent.size.x
	var StreamBox_1_right_edge_x_ratio = stream_1_data["ended at relative timestamp"] / value_delta
	var StreamBox_1_right_edge = StreamBox_1_right_edge_x_ratio * StreamBoxParent.size.x
	
	StreamBox_1.position.x = StreamBox_1_left_edge
	StreamBox_1.size.x = StreamBox_1_right_edge - StreamBox_1_left_edge
	
	# ----- ----- ----- ----- -----
	
	# resize and reposition StreamBox_2
	
	var StreamBox_2_left_edge_x_ratio = stream_2_data["started at relative timestamp"] / value_delta
	var StreamBox_2_left_edge = StreamBox_2_left_edge_x_ratio * StreamBoxParent.size.x
	var StreamBox_2_right_edge_x_ratio = stream_2_data["ended at relative timestamp"] / value_delta
	var StreamBox_2_right_edge = StreamBox_2_right_edge_x_ratio * StreamBoxParent.size.x
	
	StreamBox_2.position.x = StreamBox_2_left_edge
	StreamBox_2.size.x = StreamBox_2_right_edge - StreamBox_2_left_edge
	
	# ----- ----- ----- ----- -----
	
	# update StreamBox label and such
	
	StreamBox_1.config(stream_1_data)
	StreamBox_2.config(stream_2_data)
	
	# ----- ----- ----- ----- -----
	
	# configure the timestamp sticks
	
	# calculate the custom timestamp's x position
	var custom_relative_timestamp_x_ratio = custom_relative_timestamp / value_delta
	var custom_relative_timestamp_x = custom_relative_timestamp_x_ratio * StreamBoxParent.size.x
	
	var StreamBox_1_left_edge_timestamps = {
		"stream 1": {"unix": stream_1_data["started at timestamp utc"],       "relative": 0},
		"stream 2": {"unix": stream_1_data["started at timestamp utc"],       "relative": stream_1_data["started at timestamp utc"] - stream_2_data["started at timestamp utc"]}}
	var StreamBox_1_right_edge_timestamps = {
		"stream 1": {"unix": stream_1_data["ended or current timestamp utc"], "relative": stream_1_data["uptime"]},
		"stream 2": {"unix": stream_1_data["ended or current timestamp utc"], "relative": stream_1_data["ended or current timestamp utc"] - stream_2_data["started at timestamp utc"]}}
	var StreamBox_2_left_edge_timestamps = {
		"stream 1": {"unix": stream_2_data["started at timestamp utc"],       "relative": stream_2_data["started at timestamp utc"] - stream_1_data["started at timestamp utc"]},
		"stream 2": {"unix": stream_2_data["started at timestamp utc"],       "relative": 0}}
	var StreamBox_2_right_edge_timestamps = {
		"stream 1": {"unix": stream_2_data["ended or current timestamp utc"], "relative": stream_2_data["ended or current timestamp utc"] - stream_1_data["started at timestamp utc"]},
		"stream 2": {"unix": stream_2_data["ended or current timestamp utc"], "relative": stream_2_data["uptime"]}}
	var CustomTimestamps = {
		"stream 1": {"unix": custom_timestamp_utc,                            "relative": custom_timestamp_utc - stream_1_data["started at timestamp utc"]},
		"stream 2": {"unix": custom_timestamp_utc,                            "relative": custom_timestamp_utc - stream_2_data["started at timestamp utc"]}}
	
	$TimestampStickParent/s1StartTimestampStick.config( StreamBox_1_left_edge,       StreamBox_1_left_edge_timestamps)
	$TimestampStickParent/s1EndTimestampStick.config(   StreamBox_1_right_edge,      StreamBox_1_right_edge_timestamps)
	$TimestampStickParent/s2StartTimestampStick.config( StreamBox_2_left_edge,       StreamBox_2_left_edge_timestamps)
	$TimestampStickParent/s2EndTimestampStick.config(   StreamBox_2_right_edge,      StreamBox_2_right_edge_timestamps)
	$TimestampStickParent/InnerTimestampStick.config(   custom_relative_timestamp_x, CustomTimestamps)
	
	# ----- ----- ----- ----- -----
	
	# make sure there are no overlapping timestamp sticks. this is done by
	# hiding 1 of 2 sticks that are in the same place
	# (this is needed if the streams end at the exact same time)
	# (this doesnt fix the label overlap caused by streams ending 1 sec apart)
	var sticks = $TimestampStickParent.get_children()
	
	# skip the "inner stick"
	sticks.erase($TimestampStickParent/InnerTimestampStick)
	
	for stick in sticks:
		# skip any already hidden sticks
		if not stick.visible:
			continue
		
		# compare this stick to all other sticks
		for sub_stick in sticks:
			# skip self
			if sub_stick == stick:
				continue
			
			# hide if the two sticks' x coord is the same
			if stick.position.x == sub_stick.position.x:
				sub_stick.hide()
	
	# ----- ----- ----- ----- -----
	
	# finally, show the sprite the were configured above
	
	$Label.visible = false
	$StreamBoxParent.visible = true
	$TimestampStickParent.visible = true



