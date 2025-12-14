extends Control

var min_size = Vector2(512, 228)

@onready var MainNode = $/root/main
@onready var OverlapSection = $/root/main/OverlapSection
@onready var DataSection = $/root/main/DataSection

@onready var ValueInputs = $ValueInputs
@onready var StreamInput1 = $ValueInputs/StreamInput1
@onready var StreamInput2 = $ValueInputs/StreamInput2
@onready var TimeInput = $ValueInputs/TimeInput
@onready var ApiKeysButton = $ApiKeyButton

@onready var ApiInputs = $ApiInputs
@onready var ClientIDInput = $ApiInputs/ClientIDInput
@onready var ClientSecretInput = $ApiInputs/ClientSecretInput
@onready var AccessTokenInput = $ApiInputs/AccessTokenInput
@onready var AccessTokenRefreshButton = $ApiInputs/AccessTokenInput/RefreshButton
@onready var AccessTokenTimeRemainingLabel = $ApiInputs/AccessTokenInput/TimeRemainingLabel
@onready var AccessTokenRefreshButtonFlashTimer = $ApiInputs/AccessTokenInput/RefreshButton/FlashTimer
@onready var ApiKeyInput = $ApiInputs/ApiKeyInput

@onready var SubmitButton = $ValueInputs/SubmitButton
@onready var SubmitButtonFlashTimer = $ValueInputs/SubmitButton/FlashTimer
@onready var SubmitLoadingAnimationSprite = $ValueInputs/SubmitButton/LoadingAnimation/LoadingAnimationSprite

@onready var CredentialsSaveButton = $ApiInputs/CredentialsSaveButton
@onready var CredentialsSaveLoadingAnimationSprite = $ApiInputs/CredentialsSaveButton/LoadingAnimation/LoadingAnimationSprite


func _process(delta):
	
	# example text : "00:00:04"
	# text if fetching new token : "__:__:__"
	
	# dont update the time remaining label if currently fetching a new token
	if AccessTokenTimeRemainingLabel.text == "__:__:__":
		return
	
	AccessTokenTimeRemainingLabel.text = MainNode.format_time_til_timestamp(
		MainNode.api_credentials["accessToken expiry timestamp"]
		)
	
	# if the accessToken has or will expire in the next 5 sec
	if MainNode.api_credentials["accessToken expiry timestamp"] - (Time.get_unix_time_from_system()+5) < 0:
		if AccessTokenTimeRemainingLabel.modulate != Color.RED:
			AccessTokenTimeRemainingLabel.modulate = Color.RED
	else:
		if AccessTokenTimeRemainingLabel.modulate != Color.WHITE:
			AccessTokenTimeRemainingLabel.modulate = Color.WHITE

func _on_api_key_button_pressed():
	ValueInputs.visible = not ValueInputs.visible
	ApiInputs.visible = not ApiInputs.visible
	
	if ApiInputs.visible:
		ClientIDInput.text = MainNode.api_credentials["clientID"]
		ClientSecretInput.text = MainNode.api_credentials["clientSecret"]
		AccessTokenInput.text = MainNode.api_credentials["accessToken"]
		ApiKeyInput.text = MainNode.api_credentials["apiKey"]


func _on_access_token_refresh_button_pressed():
	# cant fetch new token if dont have Client ID or client secret
	# therefore throw visual error
	if ClientIDInput.text == "" or ClientSecretInput.text == "":
		AccessTokenRefreshButton.set_modulate(Color.RED)
		AccessTokenRefreshButtonFlashTimer.start()
		return
	
	AccessTokenRefreshButton.disabled = true
	AccessTokenInput.text = ""
	AccessTokenTimeRemainingLabel.text = "__:__:__"
	AccessTokenTimeRemainingLabel.modulate = Color.WHITE
	
	MainNode.generate_twitch_api_access_token_thread = Thread.new()
	MainNode.generate_twitch_api_access_token_thread.start(MainNode._generate_twitch_api_access_token)
	
	ApiKeysButton.disabled = true
	CredentialsSaveButton.disabled = true
	
	AccessTokenRefreshButton.set_modulate(Color.WEB_GREEN)
	AccessTokenRefreshButtonFlashTimer.start()
	
	CredentialsSaveLoadingAnimationSprite.show()
	CredentialsSaveLoadingAnimationSprite.play("loading")

func _on_finished_generating_twitch_api_access_token():
	var new_token = MainNode.generate_twitch_api_access_token_return_value["access_token"]
	var new_token_expiry_timestamp = Time.get_unix_time_from_system() + MainNode.generate_twitch_api_access_token_return_value["expires_in"]
	MainNode.generate_twitch_api_access_token_return_value = {}
	
	AccessTokenRefreshButton.disabled = false
	AccessTokenInput.text = new_token
	AccessTokenTimeRemainingLabel.text = MainNode.format_time_til_timestamp(new_token_expiry_timestamp)
	
	CredentialsSaveLoadingAnimationSprite.hide()
	CredentialsSaveLoadingAnimationSprite.stop()
	
	ApiKeysButton.disabled = false
	CredentialsSaveButton.disabled = false
	
	MainNode.api_credentials["accessToken"] = new_token
	MainNode.api_credentials["accessToken expiry timestamp"] = new_token_expiry_timestamp
	_on_credentials_save_button_pressed(false)

func _on_access_token_refresh_button_error_flash_timer_timeout():
	AccessTokenRefreshButton.set_modulate(Color.WHITE)



func _on_credentials_save_button_pressed(exit_api_screen = true):
	MainNode.api_credentials["clientID"] = ClientIDInput.text
	MainNode.api_credentials["clientSecret"] = ClientSecretInput.text
	MainNode.api_credentials["apiKey"] = ApiKeyInput.text
	
	ApiKeysButton.disabled = true
	AccessTokenRefreshButton.disabled = true
	
	CredentialsSaveLoadingAnimationSprite.show()
	CredentialsSaveLoadingAnimationSprite.play("loading")
	
	MainNode.save_api_credentials_to_file()
	
	ApiKeysButton.disabled = false
	AccessTokenRefreshButton.disabled = false
	
	CredentialsSaveLoadingAnimationSprite.hide()
	CredentialsSaveLoadingAnimationSprite.stop()
	
	if exit_api_screen:
		_on_api_key_button_pressed()

func check_if_submit_button_should_throw_error():
	# returns string error message or null if shouldnt throw error 
	
	# throw error based on...
	## - stream inp 1        - error : "Missing required values"
	## - stream inp 2        - error : "Missing required values"
	## - time stamp inp      - error : "Missing required values"
	## - day in date inp     - error : "Date {y}-{m}-{d} does not exist"
	## - clientID inp        - error : "Missing required API credentials"
	## - client secret inp   - error : "Missing required API credentials"
	## - accesstoken         - error : "Missing required API credentials"
	## - api key inp         - error : "Missing required API credentials"
	## - accesstoken expired - error : "Missing required API credentials"
	
	# if either stream hasnt been submitted
	if StreamInput1.text == "" or StreamInput2.text == "":
		return "Stream 1 and/or stream 2 hasn't been inputted"
	
	# if any time/date value hasnt been submitted
	var TimeInput_value = TimeInput.request_output_value()
	for key in TimeInput_value:
		if key == "key": continue
		if TimeInput_value[key] == null:
			return "One or multiple time input values hasn't been submitted"
	
	# if the date input type contains a day but that day is invalid
	if TimeInput_value["key"] == "YYYY-MM-DD HH:MM:SS":
		var days_in_month_func = func(m, y): return 30 + ((m + (1 if m > 7 else 0)) % 2) + (-1 if m == 2 and not y % 4 else -2 if m == 2 else 0)
		if days_in_month_func.call(TimeInput_value["months"], TimeInput_value["years"]) < TimeInput_value["days"]:
			return "The inputted day is invalid"
	
	# if any of the api credentials have not been submitted
	if [
			MainNode.api_credentials["clientID"] == "",
			MainNode.api_credentials["clientSecret"] == "",
			MainNode.api_credentials["accessToken"] == "",
			MainNode.api_credentials["apiKey"] == "",
		].any(func(item): return item):
		
		return "One or multiple api credential values hasn't been submitted"
	
	# if the accessToken has or will expire in the next 5 sec
	if MainNode.api_credentials["accessToken expiry timestamp"] - (Time.get_unix_time_from_system()+5) < 0:
		return "The twitch accessToken has or will soon expire"
	
	# if nothing is wrong then dont throw error
	return null

func _on_submit_button_pressed():
	var error_message = check_if_submit_button_should_throw_error()
	if error_message:
		SubmitButtonFlashTimer.start()
		SubmitButton.set_self_modulate(Color.RED)
		$/root/main.throw_error(error_message)
		return
	
	var input_values = {
		"stream 1": {
			"platform": StreamInput1.platform,
			"value": StreamInput1.text
			},
		"stream 2": {
			"platform": StreamInput2.platform,
			"value": StreamInput2.text
			}
		}
	
	MainNode.fetch_stream_data_thread = Thread.new()
	MainNode.fetch_stream_data_thread.start(MainNode._fetch_stream_data.bind(input_values))
	
	SubmitButton.disabled = true
	SubmitButtonFlashTimer.start()
	SubmitButton.set_self_modulate(Color.WEB_GREEN)
	
	SubmitLoadingAnimationSprite.show()
	SubmitLoadingAnimationSprite.play("loading")
	
	$/root/main/DataSection.clear()
	$/root/main/OverlapSection.clear()

func _on_finished_fetching_stream_data():
	SubmitButton.disabled = false
	
	SubmitLoadingAnimationSprite.hide()
	SubmitLoadingAnimationSprite.stop()
	
	# throw error and do not update OverlapSection if the required data wasnt received
	if MainNode.fetch_stream_data_return_value == {}:
		return
	
	# decode the things that needed to be encoded for data transfer from the exe
	MainNode.fetch_stream_data_return_value["stream 1"]["stream title"] = MainNode.fetch_stream_data_return_value["stream 1"]["stream title"].uri_decode()
	MainNode.fetch_stream_data_return_value["stream 2"]["stream title"] = MainNode.fetch_stream_data_return_value["stream 2"]["stream title"].uri_decode()
	MainNode.fetch_stream_data_return_value["stream 1"]["streamer name"] = MainNode.fetch_stream_data_return_value["stream 1"]["streamer name"].uri_decode()
	MainNode.fetch_stream_data_return_value["stream 2"]["streamer name"] = MainNode.fetch_stream_data_return_value["stream 2"]["streamer name"].uri_decode()
	
	OverlapSection.config(
		TimeInput.request_output_value(),
		MainNode.fetch_stream_data_return_value)
	
	DataSection.config_stream_data(
		MainNode.fetch_stream_data_return_value)
	
	MainNode.fetch_stream_data_return_value = {}

func _on_submit_button_flash_timer_timeout():
	SubmitButton.set_self_modulate(Color.WHITE)





