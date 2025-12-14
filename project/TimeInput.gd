extends Control

@onready var DateInput = $"YYYY-MM-DD HH∶MM∶SS"
@onready var TimeInput = $"HH∶MM∶SS"
@onready var SecondsInput = $Seconds
@onready var InputParents = [DateInput, TimeInput, SecondsInput]

@onready var MenuButtonNode = $Dropdown/MenuButton
@onready var MenuButtonNode_popup = MenuButtonNode.get_popup()

var currently_selected_item = 0
var input_relative_to_utc : bool
var input_relative_to_str = ""

@onready var LineEdits = {
	"Time_hours": {
		"Node": $"HH∶MM∶SS/hours",
		"min value": 0,
		"max value": 999,
		"affiliation": "HH:MM:SS",
		"min length": 2
	},
	"Time_minutes": {
		"Node": $"HH∶MM∶SS/minutes",
		"min value": 0,
		"max value": 59,
		"affiliation": "HH:MM:SS",
		"min length": 2
	},
	"Time_seconds": {
		"Node": $"HH∶MM∶SS/seconds",
		"min value": 0,
		"max value": 59,
		"affiliation": "HH:MM:SS",
		"min length": 2
	},
	"Date_years": {
		"Node": $"YYYY-MM-DD HH∶MM∶SS/YYYY-MM-DD/years",
		"min value": 0,
		"max value": 9999,
		"affiliation": "YYYY-MM-DD HH:MM:SS",
		"min length": 0
	},
	"Date_months": {
		"Node": $"YYYY-MM-DD HH∶MM∶SS/YYYY-MM-DD/months",
		"min value": 1,
		"max value": 12,
		"affiliation": "YYYY-MM-DD HH:MM:SS",
		"min length": 2
	},
	"Date_days": {
		"Node": $"YYYY-MM-DD HH∶MM∶SS/YYYY-MM-DD/days",
		"min value": 1,
		"max value": 31,
		"affiliation": "YYYY-MM-DD HH:MM:SS",
		"min length": 2
	},
	"Date_hours": {
		"Node": $"YYYY-MM-DD HH∶MM∶SS/HH∶MM∶SS/hours",
		"min value": 0,
		"max value": 24,
		"affiliation": "YYYY-MM-DD HH:MM:SS",
		"min length": 2
	},
	"Date_minutes": {
		"Node": $"YYYY-MM-DD HH∶MM∶SS/HH∶MM∶SS/minutes",
		"min value": 0,
		"max value": 59,
		"affiliation": "YYYY-MM-DD HH:MM:SS",
		"min length": 2
	},
	"Date_seconds": {
		"Node": $"YYYY-MM-DD HH∶MM∶SS/HH∶MM∶SS/seconds",
		"min value": 0,
		"max value": 59,
		"affiliation": "YYYY-MM-DD HH:MM:SS",
		"min length": 2
	},
	"Seconds_seconds": {
		"Node": $Seconds/seconds,
		"min value": 0,
		"max value": 9999999999,
		"affiliation": "Seconds",
		"min length": 0
	},
}

@onready var LineEdit_values = {
	"HH:MM:SS": {
		"hours": null,
		"minutes": null,
		"seconds": null,
	},
	"YYYY-MM-DD HH:MM:SS": {
		"years": null,
		"months": null,
		"days": null,
		"hours": null,
		"minutes": null,
		"seconds": null
	},
	"Seconds": {
		"seconds": null
	}
}


func _ready():
	MenuButtonNode_popup.connect("id_pressed", _on_menu_button_item_pressed)


func show_appropriate_input_node():
	var previous_input_parent = InputParents.filter(func(node): return node.visible)[0]
	previous_input_parent.hide()
	
	var appropriate_input_parent
	if currently_selected_item == 0:
		if input_relative_to_utc:      appropriate_input_parent = DateInput
		else:                          appropriate_input_parent = TimeInput
	elif currently_selected_item == 1: appropriate_input_parent = SecondsInput
	appropriate_input_parent.show()
	
	# clear the LineEdit text and any stored values. if the new format for inputs
	# is the same as the previous the values are transfered over
	# ie changing from Stream 1 Seconds -> UTC Seconds doesnt clear the input fields
	# ie changing from Stream 1 HH:MM:SS -> UTC YYYY-MM-DD HH:MM:SS clears the input fields
	
	var previous_values
	var previous_input_parent_name = previous_input_parent.name.replace("∶", ":")
	var appropriate_input_parent_name = appropriate_input_parent.name.replace("∶", ":")
	if previous_input_parent_name == appropriate_input_parent_name:
		previous_values = LineEdit_values[previous_input_parent_name]
	
	# clear all previously shown labels
	for key in LineEdits.keys().filter(func(key): return LineEdits[key]["affiliation"] == previous_input_parent_name):
		LineEdits[key]["Node"].text = ""
	
	# insert the new values if applicable
	if previous_input_parent_name == appropriate_input_parent_name:
		# for each relevant label
		for key in LineEdits.keys().filter(func(key): return LineEdits[key]["affiliation"] == appropriate_input_parent_name):
			# eg key: "Date_seconds"
			var text = previous_values[key.split("_")[1]]
			LineEdits[key]["Node"].text = str(text).lpad(LineEdits[key]["min length"], "0") if text != null else ""
	
	# otherwise clear the value storage
	else:
		for group_name in LineEdit_values.keys():
			for key in LineEdit_values[group_name].keys():
				LineEdit_values[group_name][key] = null
	
func _on_menu_button_item_pressed(id):
	# 0 : HH:MM:SS or YYYY:MM:DD HH:MM:SS
	# 1 : seconds
	
	var other_id = abs(id-1)
	MenuButtonNode_popup.set_item_checked(id, true)
	MenuButtonNode_popup.set_item_checked(other_id, false)
	
	currently_selected_item = id
	show_appropriate_input_node()


func _on_input_relative_to_value_changed(value_idx, value_str):
	# if new_value is 2 it is relative to utc
	input_relative_to_utc = value_idx == 2
	input_relative_to_str = value_str
	
	if is_node_ready():
		MenuButtonNode_popup.set_item_text(
			0,
			"Date + time" if input_relative_to_utc else "Time")
		
		show_appropriate_input_node()



# ====================
# Request output value
# ====================

func request_output_value():
	var relevant_value_key
	if currently_selected_item == 0:
		if input_relative_to_utc:      relevant_value_key = "YYYY-MM-DD HH:MM:SS"
		else:                          relevant_value_key = "HH:MM:SS"
	elif currently_selected_item == 1: relevant_value_key = "Seconds"
	
	var output_values = LineEdit_values[relevant_value_key]
	output_values["key"] = relevant_value_key
	output_values["relative to"] = input_relative_to_str
	return output_values



# =======
# Padding
# =======

func _on_main_just_unfocused_text_field(node):
	if node.text == "":
		return
	
	# loop through the LineEdits dict to get how much the node should be padded
	for key in LineEdits.keys():
		if LineEdits[key]["Node"] == node:
			node.text = node.text.lpad(LineEdits[key]["min length"], "0")
			break



# =====================================
# LineEdit text regulation + submission
# =====================================

func _on_LineEdit_text_changed(LineEdits_key : StringName, new_text : String):
	var relevant_LineEdit_info = LineEdits[LineEdits_key]
	var value_type = LineEdits_key.split("_")[1]
	# eg. hours, minutes, years, ...
	
	# remove any non integer characters
	# thus making parsed_text either "" or a series of integers
	var parsed_text = ""
	for character in new_text:
		if character in "0123456789":
			parsed_text += character
	
	# if none of the characters survived the non-integer clensing
	if parsed_text == "":
		# update the value dict
		LineEdit_values[relevant_LineEdit_info["affiliation"]][value_type] = null
	
	else:
		# make sure the value does11nt subceed or exceed the min and max values
		if int(parsed_text) < relevant_LineEdit_info["min value"]:
			parsed_text = str(relevant_LineEdit_info["min value"])
		
		if relevant_LineEdit_info["max value"] < int(parsed_text):
			parsed_text = str(relevant_LineEdit_info["max value"])
		
		# update the value dict
		LineEdit_values[relevant_LineEdit_info["affiliation"]][value_type] = int(parsed_text)
	
	relevant_LineEdit_info["Node"].text = parsed_text
	relevant_LineEdit_info["Node"].set_caret_column(10)
	# 10 is greater than the max length of all the LineEdits

func _on_Time_hours_text_changed(new_text):   _on_LineEdit_text_changed(&"Time_hours", new_text)
func _on_Time_minutes_text_changed(new_text): _on_LineEdit_text_changed(&"Time_minutes", new_text)
func _on_Time_seconds_text_changed(new_text): _on_LineEdit_text_changed(&"Time_seconds", new_text)
func _on_Date_years_text_changed(new_text):   _on_LineEdit_text_changed(&"Date_years", new_text)
func _on_Date_months_text_changed(new_text):  _on_LineEdit_text_changed(&"Date_months", new_text)
func _on_Date_days_text_changed(new_text):    _on_LineEdit_text_changed(&"Date_days", new_text)
func _on_Date_hours_text_changed(new_text):   _on_LineEdit_text_changed(&"Date_hours", new_text)
func _on_Date_minutes_text_changed(new_text): _on_LineEdit_text_changed(&"Date_minutes", new_text)
func _on_Date_seconds_text_changed(new_text): _on_LineEdit_text_changed(&"Date_seconds", new_text)
func _on_Sec_seconds_text_changed(new_text):  _on_LineEdit_text_changed(&"Seconds_seconds", new_text)

