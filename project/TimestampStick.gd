extends Control

#var expected_size = Vector2(48, 283)

var timestamps = {
	"stream 1": {
		"unix": null,
		"unix formatted": null,
		"relative": null,
		"relative formatted": null,
	},
	"stream 2": {
		"unix": null,
		"unix formatted": null,
		"relative": null,
		"relative formatted": null,
	}
}

#func update_time_labels(only_update = null) -> void:
	#for stream in timestamps.keys():
		#if only_update != null and only_update != stream:
			#continue
		#
		#var current_stream_time_data = timestamps[stream]
		#
		#var timestamp
		#if display_relative_time[stream]:
			#timestamp = current_stream_time_data["relative"]
		#else:
			#timestamp = current_stream_time_data["unix"]
		#
		## if the time value is negative then make it positive for the sake of
		## getting the datetime dict properly. the negative sign is added later
		#var negative = false
		#if timestamp < 0:
			#negative = true
			#timestamp = timestamp * -1
		#
		#var date_dict = Time.get_datetime_dict_from_unix_time(timestamp)
		#var outp_str = str(date_dict["hour"]).lpad(2, "0") + ":" + str(date_dict["minute"]).lpad(2, "0") + ":" + str(date_dict["second"]).lpad(2, "0")
		#
		#if negative:
			#outp_str = "-" + outp_str
		#
		## if its not relative then the label contains 2 rows. Time and date.
		## if relative have the first row be empty and place the time on row 2
		## if the current label is the bottom one then do row 1. time, 2. "\n"
		## if name is InnerTimestampStick then only have 1 row
		#if display_relative_time[stream]:
			#if name != "InnerTimestampStick":
				#if current_stream_time_data["node name"] == &"UpperTimeLabel":
					#outp_str = "\n" + outp_str
				#else:
					#outp_str = outp_str + "\n"
		#else:
			#if name == "InnerTimestampStick":
				#outp_str += " " + month_abrev[date_dict["month"]-1] + " " + str(date_dict["day"])
			#else:
				#outp_str += "\n" + month_abrev[date_dict["month"]-1] + " " + str(date_dict["day"])
		#
		#get_node(str(current_stream_time_data["node name"])).text = outp_str


func format_unix(timestamp):
	var date_dict = Time.get_datetime_dict_from_unix_time(timestamp)
	var outp_list = [
		# 14:18:30 2024-08-06
		str(date_dict["hour"]).lpad(2, "0") + ":",
		str(date_dict["minute"]).lpad(2, "0") + ":",
		str(date_dict["second"]).lpad(2, "0") + " ",
		str(date_dict["year"]) + "-",
		str(date_dict["month"]).lpad(2, "0") + "-",
		str(date_dict["day"]).lpad(2, "0")
		]
	return "".join(outp_list)

func format_relative(timestamp):
	
	# in order to not mess with the get_datetime_dict_from_unix_time make any
	# negative timestamp positive and add a "-" later
	var negative = false
	if timestamp < 0:
		negative = true
		timestamp = timestamp * -1
	
	var date_dict = Time.get_datetime_dict_from_unix_time(timestamp)
	var outp_list = [
		# -01:50:23
		"-" if negative else "",
		str(date_dict["hour"]).lpad(2, "0") + ":",
		str(date_dict["minute"]).lpad(2, "0") + ":",
		str(date_dict["second"]).lpad(2, "0"),
	]
	return "".join(outp_list)

func config(x_pos, streams : Dictionary) -> void:
	position.x = x_pos - size.x/2
	
	for stream_name in streams:
		timestamps[stream_name]["unix"] = streams[stream_name]["unix"]
		timestamps[stream_name]["unix formatted"] = format_unix(streams[stream_name]["unix"])
		timestamps[stream_name]["relative"] = streams[stream_name]["relative"]
		timestamps[stream_name]["relative formatted"] = format_relative(streams[stream_name]["relative"])
	
	$UpperTimeLabel.text = timestamps["stream 1"]["relative formatted"]
	$LowerTimeLabel.text = timestamps["stream 2"]["relative formatted"]

func _on_either_button_pressed():
	$/root/main.timestamp_stick_pressed.emit(timestamps)
