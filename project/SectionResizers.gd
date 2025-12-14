extends Control

@onready var InputSection = $/root/main/InputSection
@onready var DataSection = $/root/main/DataSection
@onready var OverlapSection = $/root/main/OverlapSection

@onready var MultidimentionalButton = $Multidimentional
@onready var VerticalButton = $Vertical
@onready var HorizontalButton = $Horizontal

var VerticalButton_x_ratio : float
var HorizontalButton_y_ratio : float

var button_pressed = {
	"button": null,
	"timestamp": 0
}

var last_button_pressed = {
	"button": null,
	"timestamp": 0
}

var button_is_down = false

var double_click_time_delta = 0.25

func _input(event):
	if button_is_down and event is InputEventMouseMotion and Input.is_action_pressed("LMB"):
		move_sections(event.position)

func move_sections(mouse_pos : Vector2) -> void:
	# VerticalButton and HorizontalButton resize different things on the
	# screen. If MultidimentionalButton is pressed then simply act as if
	# both Vertical and Horizontal button are being pressed.
	
	if button_pressed["button"] in [VerticalButton, MultidimentionalButton]:
		
		# get the minimum size values for each relevant section
		var InputSection_left_edge = 10
		var InputSection_min_right_edge = InputSection_left_edge + InputSection.min_size.x
		
		var DataSection_right_edge = get_viewport_rect().size.x - 10
		var DataSection_min_left_edge = DataSection_right_edge - DataSection.min_size.x
		
		# conform the x to the minimum size of the relevant sections 
		var adjusted_event_x = clampf(mouse_pos.x, InputSection_min_right_edge, DataSection_min_left_edge)
		
		# move the buttons used for resizing
		VerticalButton.position.x = adjusted_event_x - button_pressed["button"].size.x/2
		MultidimentionalButton.position.x = adjusted_event_x - MultidimentionalButton.size.x/2
		
		# resize the input section
		var InputSection_right_edge = adjusted_event_x - button_pressed["button"].size.x/2
		InputSection.size.x = InputSection_right_edge - InputSection_left_edge
		
		# resize and reposition the data section
		var DataSection_left_edge = adjusted_event_x + button_pressed["button"].size.x/2
		DataSection.size.x = DataSection_right_edge - DataSection_left_edge
		DataSection.position.x = DataSection_left_edge
	
	if button_pressed["button"] in [HorizontalButton, MultidimentionalButton]:
		
		# get the minimum size values for each relevant section
		var upper_sections_top_edge = 10
		var upper_sections_min_bot_edge = upper_sections_top_edge + max(InputSection.min_size.y, DataSection.min_size.y)
		
		var OverlapSection_bot_edge = get_viewport_rect().size.y - 10
		var OverlapSection_min_top_edge = OverlapSection_bot_edge - OverlapSection.min_size.y
		
		# conform the y to the minimum size of the relevant sections 
		var adjusted_event_y = clampf(mouse_pos.y, upper_sections_min_bot_edge, OverlapSection_min_top_edge)
		
		# move the buttons used for resizing
		HorizontalButton.position.y = adjusted_event_y - button_pressed["button"].size.y/2
		MultidimentionalButton.position.y = adjusted_event_y - MultidimentionalButton.size.y/2
		VerticalButton.size.y = adjusted_event_y - upper_sections_top_edge
		
		# resize the input and data section
		var upper_sections_bot_edge = adjusted_event_y - button_pressed["button"].size.y/2
		InputSection.size.y = upper_sections_bot_edge - upper_sections_top_edge
		DataSection.size.y = upper_sections_bot_edge - upper_sections_top_edge
		
		# resize and reposition the overlap section
		var OverlapSection_top_edge = adjusted_event_y + button_pressed["button"].size.y/2
		OverlapSection.size.y = OverlapSection_bot_edge - OverlapSection_top_edge
		OverlapSection.position.y = OverlapSection_top_edge


func just_pressed_button(button):
	button_is_down = true
	
	last_button_pressed["button"] = button_pressed["button"]
	last_button_pressed["timestamp"] = button_pressed["timestamp"]
	
	button_pressed["button"] = button
	button_pressed["timestamp"] = Time.get_unix_time_from_system()
	
	if button_pressed["timestamp"] - last_button_pressed["timestamp"] < double_click_time_delta:
		if button_pressed["button"] == last_button_pressed["button"]:
			move_sections(get_viewport_rect().size/2)

func _on_vertical_button_down():   just_pressed_button(VerticalButton)
func _on_horizontal_button_down(): just_pressed_button(HorizontalButton)
func _on_multidim_button_down():   just_pressed_button(MultidimentionalButton)
func _on_any_button_up():          button_is_down = false
