extends Control

@export var header_text = ""
@export var option_1_text = ""
@export var option_2_text = ""
@export var option_3_text = ""

@onready var label_list = [$Label1, $Label2, $Label3]

@onready var SliderNode = $Slider

var value_idx : int
var value_str : String

signal value_changed(new_value_idx, new_value_str)

# Called when the node enters the scene tree for the first time.
func _ready():
	$Header.text = header_text
	$Label1.text = option_1_text
	$Label2.text = option_2_text
	$Label3.text = option_3_text
	
	value_changed.emit(0, "stream 1")


func _on_slider_value_changed(value):
	value_idx = value
	value_str = label_list[value].text.to_lower()
	value_changed.emit(value_idx, value_str)

func _input(event):
	if event.is_action_released("LMB"):
		SliderNode.release_focus()
	

func _on_left_button_pressed():   SliderNode.value = 0
func _on_middle_button_pressed(): SliderNode.value = 1
func _on_right_button_pressed():  SliderNode.value = 2
