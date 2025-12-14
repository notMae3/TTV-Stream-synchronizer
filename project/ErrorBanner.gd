extends Control

# set at instantiation
var text = "123456789 123456 1234 123 13245678 12345 123456789 123456 12 132 123456 12345 1324567 12345"

var sec_per_char = 0.05
var min_reading_time_sec = 2.5

var max_label_width = 760

# Called when the node enters the scene tree for the first time.
func _ready():
	$Label.text = text
	
	await get_tree().process_frame
	
	if max_label_width <= $Label.size.x:
		# gets which percentage of the text the newline should be inserted
		var percent_of_max = $Label.size.x / max_label_width
		var percent_of_text_to_insert_newline = 1.0 / percent_of_max
		
		# gets the reverse-first space and saves that text idx for inserting newline
		# this simulates word wrap
		var char_split_line_1 = text.substr(0, round(len(text) * percent_of_text_to_insert_newline))
		var idx_to_insert_newline = char_split_line_1.rfind(" ")
		
		# takes the left side of the idx of where newline should be inserted and
		# adds newline at the end, then adds the right side of the idx of where
		# newline should be inserted and adds it after the inserted newline
		$Label.text = text.left(idx_to_insert_newline).strip_edges() + "\n" + text.right(len(text) - idx_to_insert_newline).strip_edges()
		
		await get_tree().process_frame
		
		#set size of the red rect to *upper text padding* + *text label size*
		# + *botton text padding*
		size.y = $Label.size.y + 2 * $Label.position.y
	
	# update the animation player with the new size and start decending
	$AnimationPlayer.get_animation_library("").get_animation("descend").track_set_key_value(0, 0, Vector2(position.x, -size.y))
	$AnimationPlayer.get_animation_library("").get_animation("ascend").track_set_key_value(0, 1, Vector2(position.x, -size.y))
	$AnimationPlayer.play("descend")


func _on_animation_finished(anim_name):
	if anim_name == "descend":
		# wait for the user to read the error message then ascend
		await get_tree().create_timer(max(min_reading_time_sec, len(text) * sec_per_char)).timeout
		$AnimationPlayer.play("ascend")
