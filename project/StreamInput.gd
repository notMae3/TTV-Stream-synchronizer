extends Control

@onready var InputLineEdit = $InputLineEdit

@onready var PlatformButton = $PlatformButton
@onready var PlatformButtonTwitchIcon = preload("res://assets/twitch.png")
@onready var PlatformButtonYoutubeIcon = preload("res://assets/youtube.png")

var platform = "ttv"
var text = ""

@export var start_as = "ttv"
@export var custom_tooltip = ""


func _ready():
	call("set_to_" + start_as)
	
	$InputLineEdit.tooltip_text = custom_tooltip


func _on_platform_button_pressed():
	if PlatformButton.icon == PlatformButtonTwitchIcon:
		set_to_yt()
	else:
		set_to_ttv()

func set_to_yt():
	platform = "yt"
	PlatformButton.icon = PlatformButtonYoutubeIcon
	InputLineEdit.placeholder_text = "Youtube stream or vod shortcode (\"dQw4w9WgXcQ\")"

func set_to_ttv():
	platform = "ttv"
	PlatformButton.icon = PlatformButtonTwitchIcon
	InputLineEdit.placeholder_text = "Twitch streamer (\"xQc\") or video ID (\"2186735246\")"


func _on_input_line_edit_text_changed(new_text):
	text = new_text
