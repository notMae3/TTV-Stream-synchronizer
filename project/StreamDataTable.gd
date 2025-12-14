extends Control

@export var stream_num : int
@export var data : Dictionary:
	set(new_data):
		data = new_data
		data_updated()

var yt_texture = preload("res://assets/youtube.png")
var ttv_texture = preload("res://assets/twitch.png")

var button_text_to_data_key = {
	"Started at utc": "started at timestamp utc",
	"Ended at/current time utc": "ended or current timestamp utc",
	"Uptime": "uptime",
	"Is live": "is live",
	"Platform": "platform",
	"Stream title": "stream title",
	"Streamer name": "streamer name",
	"Raw input": "raw input"
}

func _ready():
	$StreamNumberLabel.text = "Stream " + str(stream_num)
	$MenuButton.get_popup().connect("index_pressed", _on_item_menu_item_item_selected)

func data_updated():
	$StreamNumberLabel/PlatformIcon.texture = ttv_texture if data["platform"] == "Twitch" else yt_texture

func _on_item_menu_item_item_selected(item_idx):
	var item_text = $MenuButton.get_popup().get_item_text(item_idx)
	$MenuButton.text = item_text
	
	var key = button_text_to_data_key[item_text]
	$TextEdit.text = str(data[key])


func _on_open_stream_url_button_pressed():
	OS.shell_open(data["url"])
