extends Control

var icons = {
	"ttv": preload("res://assets/twitch.png"),
	"yt": preload("res://assets/youtube.png"),
	"red dot": preload("res://assets/red_dot.png"),
	"gray dot": preload("res://assets/alt_gray_dot.png")
	}

func config(stream_data):
	$LiveDot/UptimeLabel.text = $/root/main.format_seconds(stream_data["uptime"])
	$LiveDot/UptimeLabel.tooltip_text = $LiveDot/UptimeLabel.text
	
	if stream_data["is live"]:
		$LiveDot/TextureRect.texture = icons["red dot"]
		$LiveDot/TextureRect/ColorRect.tooltip_text = "Is live"
	else:
		$LiveDot/TextureRect.texture = icons["gray dot"]
		$LiveDot/TextureRect/ColorRect.tooltip_text = "Is not live"
	
	$subtext/TextureRect.texture = icons[stream_data["platform"]]
	$subtext/TextureRect.tooltip_text = "Twitch" if stream_data["platform"] == "ttv" else "Youtube"
	
	$TitleLabel.text = stream_data["stream title"]
	$TitleLabel.tooltip_text = $TitleLabel.text
	
	$subtext/StreamerLabel.text = "{0} (\"{1}\")".format([stream_data["streamer name"], stream_data["raw input"]])
	$subtext/StreamerLabel.tooltip_text = $subtext/StreamerLabel.text
