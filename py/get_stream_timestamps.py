import requests, datetime, sys
from googleapiclient.discovery import build


class Errors:
    class NotEnoughArgumentsError(Exception): pass
    class InvalidPlatformerror(Exception): pass

    class BadTwitchApiRequest(Exception): pass
    class BadTwitchApiResponse(Exception): pass

    class BadYoutubeApiResponse(Exception): pass
    class VideoNotAStreamError(Exception): pass


class Utils:

    def get_stream_uptime(starting_timestamp : float) -> float:
        timestamp_delta = datetime.datetime.now(datetime.UTC).timestamp() - starting_timestamp
        return round(timestamp_delta, 3)
    
    def get_video_uptime(duration : str) -> int:
        # example : "15h35m30s"

        hours, rem = duration.split("h")
        minutes, seconds = rem.split("m")
        seconds = seconds.strip("s")

        return int(hours)*3600 + int(minutes)*60 + int(seconds)
    
    def time_string_to_timestamp(time_string : str) -> float:
        # only supports the below date format
        date_format = "%Y-%m-%dT%H:%M:%SZ"
        date_obj = datetime.datetime.strptime(time_string, date_format)

        return date_obj.timestamp()


class Stream:
    def __init__(self, data, platform) -> None:
        for k,v in data.items():
            setattr(self, k, v)
        
        self.platform = platform
        
        if platform == "twitch":    
            if self.type == "live":
                self.started_at_timestamp_utc = Utils.time_string_to_timestamp(self.started_at)
                self.uptime = Utils.get_stream_uptime(self.started_at_timestamp_utc)
            else:
                self.started_at_timestamp_utc = Utils.time_string_to_timestamp(self.created_at)
                self.uptime = Utils.get_video_uptime(self.duration)


class TwitchApi:

    def __init__(self, credentials) -> None:
        self.client_id = credentials["clientID"]
        self.access_token = credentials["accessToken"]

        self.headers = {
            'Authorization': 'Bearer ' + self.access_token,
            'Client-Id': self.client_id
        }

    def get_video_by_id(self, id : int) -> dict:
        url = f"https://api.twitch.tv/helix/videos?id={id}"

        response = requests.get(url, headers=self.headers)
        data = response.json()

        # handle possible errors
        if "error" in data:
            if data["error"] == "Unauthorized":
                raise Errors.BadTwitchApiRequest(f"likely unauthorized due to either clientID \"{self.client_id}\" or accessToken \"{self.access_token}\" being incorrect")
            else:
                raise Errors.BadTwitchApiRequest(f"likely due to video ID \"{id}\" containing non integers, which is not allowed")
        if data["data"] == []:
            raise Errors.BadTwitchApiResponse(f"likely due to a video associated with the ID \"{id}\" not being found")

        return Stream(data["data"][0], "twitch")

    def get_live_stream_by_streamer(self, streamer_name : str) -> Stream:
        url = f"https://api.twitch.tv/helix/streams?user_login={streamer_name}"

        response = requests.get(url, headers=self.headers)
        data = response.json()

        # handle possible errors
        if "error" in data:
            raise Errors.BadTwitchApiRequest(f"likely due to streamer name \"{streamer_name}\" being misspelled")
        if data["data"] == []:
            raise Errors.BadTwitchApiResponse(f"likely due to streamer \"{streamer_name}\" not being live")

        return Stream(data["data"][0], "twitch")


class YoutubeApi:
    def __init__(self, credentials) -> None:
        self.api_key = credentials["apiKey"]

    def get_stream_from_shortcode(self, shortcode : str):
        youtube = build("youtube", "v3", developerKey=self.api_key)

        video_request=youtube.videos().list( 
            part="liveStreamingDetails",
            id=shortcode)

        try:
            video_data = video_request.execute()
        except Exception as err:
            raise Errors.BadYoutubeApiResponse(f"likely due to the api key \"{self.api_key}\" being incorrect")

        # handle possible errors
        if video_data["items"] == []:
            raise Errors.BadYoutubeApiResponse(f"likely due to shortcode \"{shortcode}\" not being found, not being a string, or otherwise being invalid")
        if "liveStreamingDetails" not in video_data["items"][0]:
            raise Errors.VideoNotAStreamError(f"the video associated with the shortcode \"{shortcode}\" is not and has never been a livestream")

        # ----- ----- ----- ----- -----

        # parse data

        live_streaming_data = video_data["items"][0]["liveStreamingDetails"]
        start_time = live_streaming_data["actualStartTime"]

        # its a vod
        if "actualEndTime" in live_streaming_data:
            uptime = Utils.time_string_to_timestamp(live_streaming_data["actualEndTime"]) - Utils.time_string_to_timestamp(live_streaming_data["actualStartTime"])

        # its live
        else:
            uptime = datetime.datetime.now(datetime.UTC).timestamp() - Utils.time_string_to_timestamp(live_streaming_data["actualStartTime"])

        return Stream(
            {
                "started_at_timestamp_utc": Utils.time_string_to_timestamp(start_time),
                "uptime": uptime
            },
            "youtube")


class Program:
    class InputItem:
        def __init__(self, value) -> None:
            self.stream = None
            self.platform, self.value = value.split(" ")
            self.platform = self.platform.strip("-")

            if self.platform not in ["yt", "ttv"]:
                raise Errors.InvalidPlatformError(f"platform must be either \"yt\" or \"ttv\", not \"{self.platform}\"")

            # if the value is a twitch videoID then make it int
            if all([char.isdigit() for char in self.value]):
                self.value = int(self.value)
            
            self.value_type = type(self.value)

    class Utils:
        def __init__(self, api_credentials) -> None:
            self.twitch_api = TwitchApi(api_credentials["ttv"])
            self.youtube_api = YoutubeApi(api_credentials["yt"])

        def fetch_stream(self, item):
            if item.platform == "yt":
                stream = self.youtube_api.get_stream_from_shortcode(item.value)
            elif item.platform == "ttv":
                if item.value_type == str:
                    stream = self.twitch_api.get_live_stream_by_streamer(item.value)
                elif item.value_type == int:
                    stream = self.twitch_api.get_video_by_id(item.value)
            
            return stream

        def format_output(self, item_1, stream_1_timestamp, item_2, stream_2_timestamp):
            # remove unnecessary precision

            stream_1_timestamp = round(stream_1_timestamp, 3)
            stream_2_timestamp = round(stream_2_timestamp, 3)

            # ----- ----- ----- ----- -----

            #overlap
            def get_overlap(timestamp, stream):
                match timestamp:
                    case timestamp if timestamp < 0:
                        overlap = "start"
                    case timestamp if stream.uptime < timestamp:
                        overlap = "end"
                    case _:
                        overlap = None
                
                return overlap

            stream_1_overlap = get_overlap(stream_1_timestamp, item_1.stream)
            stream_2_overlap = get_overlap(stream_2_timestamp, item_2.stream)

            # ----- ----- ----- ----- -----

            return {
                "stream_1": {
                    "input value": item_1.value,
                    "relative timestamp": stream_1_timestamp,
                    "overlap": stream_1_overlap
                },
                "stream_2": {
                    "input value": item_2.value,
                    "relative timestamp": stream_2_timestamp,
                    "overlap": stream_2_overlap
                }
            }


    def __init__(self, *args) -> None:
        # parse the input args

        self.item_1 = Program.InputItem(args[0])
        self.item_2 = Program.InputItem(args[1])
        self.relative_timestamp_sec = self.target_timestamp_utc = float(args[2].split(" ")[1])
        # depending on arg 4 the above line of variables
        # will either be treated as a unix timestamp
        # or as a relative timestamp for stream 1.
        # having the alias "target_timestamp_utc" makes
        # the code more readable where it is deployed

        self.mode = args[3].split(" ")[1]
        self.api_credentials = {
            "ttv": {
                "clientID": args[4].split(" ")[1],
                "accessToken": args[5].split(" ")[1]
            },
            "yt": {
                "apiKey": args[6].split(" ")[1]
            }
        }

        # ----- ----- ----- ----- -----

        # fetch stream data
        self.utils = self.Utils(self.api_credentials)
        self.item_1.stream = self.utils.fetch_stream(self.item_1)
        self.item_2.stream = self.utils.fetch_stream(self.item_2)

        # ----- ----- ----- ----- -----

        # run the "converters"
        if self.mode == "stream_1_timestamp_to_stream_2_timestamp":
            output_dict = self.stream_1_timestamp_to_stream_2_timestamp()

        elif self.mode == "timestamp_utc_to_stream_1_and_stream_2_timestamps":
            output_dict = self.timestamp_utc_to_stream_1_and_stream_2_timestamps()
        
        else: return

        # ----- ----- ----- ----- -----

        # stdout is being read by another program thus
        # this is the easiest way to transfer data
        print(output_dict, end="", flush=True)


    def stream_1_timestamp_to_stream_2_timestamp(self):
        # get the target timestamp in utc
        # (the input timestamp thats relative to stream 1 converted to utc)

        # if positive then go from start of stream
        if 0 < self.relative_timestamp_sec:
            target_timestamp_utc = self.item_1.stream.started_at_timestamp_utc + self.relative_timestamp_sec
            stream_1_timestamp = self.relative_timestamp_sec

        # if negative then go from end of stream in reverse
        else:
            self.relative_timestamp_sec = self.relative_timestamp_sec * -1
            target_timestamp_utc = self.item_1.stream.started_at_timestamp_utc + self.item_1.stream.uptime - self.relative_timestamp_sec
            stream_1_timestamp = self.item_1.stream.uptime - self.relative_timestamp_sec

        stream_2_timestamp = target_timestamp_utc - self.item_2.stream.started_at_timestamp_utc

        return self.utils.format_output(self.item_1, stream_1_timestamp, self.item_2, stream_2_timestamp)


    def timestamp_utc_to_stream_1_and_stream_2_timestamps(self):
        
        stream_1_timestamp = self.target_timestamp_utc - self.item_1.stream.started_at_timestamp_utc
        stream_2_timestamp = self.target_timestamp_utc - self.item_2.stream.started_at_timestamp_utc

        return self.utils.format_output(self.item_1, stream_1_timestamp, self.item_2, stream_2_timestamp)



def parse_cmd_args():
    # skip this files filepath
    cmd_args = sys.argv[1:]

    # the below code goes through all args
    # passed to when this file was ran.
    # if an arg starts with "-" then it
    # means the following value should be
    # saved with the name of the previous arg.
    # if this happens we skip over the next
    # arg in cmd_args since it was just stored

    args = []
    skip_next = False
    for idx,arg in enumerate(cmd_args):
        if skip_next:
            skip_next = False
            continue

        if arg.startswith("-"):
            args.append( arg + " " + cmd_args[idx+1] )
            skip_next = True
        idx += 1

    return args



if __name__ == "__main__":
    parsed_args = parse_cmd_args()

    try:
        # minimum 8 args
        if len(parsed_args) < 7:
            raise Errors.NotEnoughArgumentsError("the minimum amount of arguments is 7. item 1, item, 2, timestamp, mode, clientID, accessToken, apiKey")

        p = Program(*parsed_args)

    except Exception as err:
        print(f"Error - {type(err).__name__}: {err}")


# dont need here, needed for new token tho
# self.client_secret = credentials["clientSecret"]
# -clientSecret [clientSecret]


#-ttv 2180802166 -ttv 2180778190 -t 3600 -mode stream_1_timestamp_to_stream_2_timestamp -clientID [clientID] -accessToken [accessToken] -apiKey [apiKey]
#-yt HLaxxqna1Rc -yt caPHvIPqzx8 -t 3600 -mode stream_1_timestamp_to_stream_2_timestamp -clientID [clientID] -accessToken [accessToken] -apiKey [apiKey]



"""
commandline support
the commands have to be in the following order

exe    base stream          "new" stream       time offset                      mode                        twitch api client id     twitch api access token       youtube api key
.exe -ttv 2180802166    -ttv 2180778190         -t 3600     -mode stream_1_timestamp_to_stream_2_timestamp  -clientID [clientID]    -accessToken [accessToken]    -apiKey [apiKey]
.exe -ttv kyedae        -ttv alveussanctuary    -t 3600     -mode stream_1_timestamp_to_stream_2_timestamp  -clientID [clientID]    -accessToken [accessToken]    -apiKey [apiKey]
.exe -ttv 2181202290    -ttv alveussanctuary    -t 3600     -mode stream_1_timestamp_to_stream_2_timestamp  -clientID [clientID]    -accessToken [accessToken]    -apiKey [apiKey]
 
.exe -yt HLaxxqna1Rc    -yt caPHvIPqzx8         -t 3600     -mode stream_1_timestamp_to_stream_2_timestamp  -clientID [clientID]    -accessToken [accessToken]    -apiKey [apiKey]
 
.exe -yt HLaxxqna1Rc    -ttv 2180802166         -t 3600     -mode stream_1_timestamp_to_stream_2_timestamp  -clientID [clientID]    -accessToken [accessToken]    -apiKey [apiKey]
.exe -yt HLaxxqna1Rc    -ttv kyedae             -t 3600     -mode stream_1_timestamp_to_stream_2_timestamp  -clientID [clientID]    -accessToken [accessToken]    -apiKey [apiKey]
"""

"""
what i want to be able to do

 # * enter a timestamp (h:m:s) for one stream and get the timestamp for the other
 #    * get stream 1 data and extract start time
 #    * get the UTC time for the stream timestamp (start + timetsamp)
 #
 #    * get stream 2 data and extract start time
 #    * stream 1 UTC timestamp - stream 2 start time = stream 2 timestamp
 #    * if negative then stream 2 started after the stream 1 timetsamp

 # * enter a date + time and get timestamp for both streams
 #        * get stream data for both
 #        * do the same as the above function except replace target_timestamp to inp timestamp


 - * enter a date + time and 2 streamer names

# be able to compare twitch vod w yt vod

# gotta do this for yt too
#     shouldnt be too difficult since have all the logic,
#     just need the api calls

in godot have a settings file w to save api credentials
    prolly have a button that links to a python file
    that regenerates the access token


test values
"kyedae"
"alveussanctuary"
2180802166
2180778190
2181202290 (recent kyedae vod)

overlapping yt streams
fuslie : https://www.youtube.com/watch?v=caPHvIPqzx8
valkyrae : https://www.youtube.com/watch?v=HLaxxqna1Rc

"""