import requests, datetime, sys, urllib.parse, json
from googleapiclient.discovery import build

class Errors:
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
    
    def time_string_to_timestamp(time_string : str) -> int:
        # only supports the below date format
        date_format = "%Y-%m-%dT%H:%M:%SZ"
        date_obj = datetime.datetime.strptime(time_string, date_format)

        return date_obj.timestamp()


class YoutubeApi:
    def __init__(self, api_key) -> None:
        self.api_key = api_key

    def get_stream_from_shortcode(self, shortcode : str) -> dict:
        youtube = build("youtube", "v3", developerKey=self.api_key)

        video_request=youtube.videos().list( 
            part="snippet,liveStreamingDetails",
            id=shortcode)

        try:
            video_data = video_request.execute()
        except:
            raise Errors.BadYoutubeApiResponse(f"likely due to the api key \"{self.api_key}\" being incorrect")

        # handle possible errors
        if video_data["items"] == []:
            raise Errors.BadYoutubeApiResponse(f"likely due to shortcode \"{shortcode}\" not being found or otherwise being invalid")
        if "liveStreamingDetails" not in video_data["items"][0]:
            raise Errors.VideoNotAStreamError(f"the video associated with the shortcode \"{shortcode}\" is not, and has never been, a livestream")

        # ----- ----- ----- ----- -----

        # parse data

        general_data = video_data["items"][0]["snippet"]
        live_streaming_data = video_data["items"][0]["liveStreamingDetails"]
        start_time = live_streaming_data["actualStartTime"]

        # its a past livestream
        if "actualEndTime" in live_streaming_data:
            end_or_current_time = Utils.time_string_to_timestamp(live_streaming_data["actualEndTime"])
            uptime = round(end_or_current_time - Utils.time_string_to_timestamp(live_streaming_data["actualStartTime"]), 3)
            is_live = False

        # its live
        else:
            end_or_current_time = round(datetime.datetime.now(datetime.UTC).timestamp(), 3)
            uptime = round(end_or_current_time - Utils.time_string_to_timestamp(live_streaming_data["actualStartTime"]), 3)
            is_live = True

        return {
            "started at timestamp utc": Utils.time_string_to_timestamp(start_time),
            "ended or current timestamp utc": end_or_current_time,
            "uptime": uptime,
            "is live": is_live,
            "platform": "yt",
            "stream title": general_data["title"],
            "streamer name": general_data["channelTitle"],
            "raw input": shortcode
            }


class TwitchApi:

    def __init__(self, clientID, accessToken) -> None:
        self.clientID = clientID
        self.accessToken = accessToken

        self.headers = {
            'Authorization': 'Bearer ' + self.accessToken,
            'Client-Id': self.clientID
        }

    def get_video_by_id(self, id : int) -> dict:
        url = f"https://api.twitch.tv/helix/videos?id={id}"

        response = requests.get(url, headers=self.headers)
        data = response.json()

        # handle possible errors
        if "error" in data:
            if data["error"] == "Unauthorized":
                raise Errors.BadTwitchApiRequest(f"unauthorized, likely due to either clientID \"{self.client_id}\" or accessToken \"{self.access_token}\" being incorrect")
        if data["data"] == []:
            raise Errors.BadTwitchApiResponse(f"likely due to ID \"{id}\" not being associated with a video")

        # parse data
        stream_data = data["data"][0]
        start_time = Utils.time_string_to_timestamp(stream_data["created_at"])
        uptime = Utils.get_video_uptime(stream_data["duration"])

        return {
            "started at timestamp utc": start_time,
            "ended or current timestamp utc": start_time + uptime,
            "uptime": uptime,
            "is live": False,
            "platform": "ttv",
            "stream title": stream_data["title"],
            "streamer name": stream_data["user_name"],
            "raw input": id
            }

    def get_live_stream_by_streamer(self, streamer_name : str) -> dict:
        url = f"https://api.twitch.tv/helix/streams?user_login={streamer_name}"

        response = requests.get(url, headers=self.headers)
        data = response.json()

        # handle possible errors
        if "error" in data:
            raise Errors.BadTwitchApiRequest(f"couldn't find streamer \"{streamer_name}\", likely because of incorrect spelling")
        if data["data"] == []:
            raise Errors.BadTwitchApiResponse(f"likely due to streamer \"{streamer_name}\" not being live")

        # parse data
        stream_data = data["data"][0]
        start_time = Utils.time_string_to_timestamp(stream_data["started_at"])
        uptime = Utils.get_stream_uptime(start_time)

        return {
            "started at timestamp utc": start_time,
            "ended or current timestamp utc": start_time + uptime,
            "uptime": uptime,
            "is live": True,
            "platform": "ttv",
            "stream title": stream_data["title"],
            "streamer name": stream_data["user_name"],
            "raw input": streamer_name
            }




class Program:
    class Stream:
        def __init__(self, platform: str, inp_value: str) -> None:
            self.platform = platform
            self.inp_value = inp_value
            self.data = {}

            # if the value is a twitch videoID then make it int
            if all([char.isdigit() for char in self.inp_value]):
                self.inp_value = int(self.inp_value)

    def __init__(self, parsed_cmd_args) -> None:
        self.stream_1 = Program.Stream(*parsed_cmd_args[0])
        self.stream_2 = Program.Stream(*parsed_cmd_args[1])

        # skip the args we just handled above
        for arg in parsed_cmd_args[2:]:
            setattr(self, arg[0], arg[1])
        
        self.youtube_api = YoutubeApi(self.apiKey)
        self.twitch_api = TwitchApi(self.clientID, self.accessToken)

        self.stream_1.data = self.fetch_stream_data(self.stream_1)
        self.stream_2.data = self.fetch_stream_data(self.stream_2)
        self.combined_stream_data = {
            "stream 1": self.stream_1.data,
            "stream 2": self.stream_2.data
        }

        # change the combined stream data to make it returnable
        self.combined_stream_data["stream 1"]["stream title"] = urllib.parse.quote(self.combined_stream_data["stream 1"]["stream title"])
        self.combined_stream_data["stream 2"]["stream title"] = urllib.parse.quote(self.combined_stream_data["stream 2"]["stream title"])
        self.combined_stream_data["stream 1"]["streamer name"] = urllib.parse.quote(self.combined_stream_data["stream 1"]["streamer name"])
        self.combined_stream_data["stream 2"]["streamer name"] = urllib.parse.quote(self.combined_stream_data["stream 2"]["streamer name"])

        # turn the dictionary to json format and write it to stdout
        json.dump(self.combined_stream_data, sys.stdout)

    
    def fetch_stream_data(self, stream) -> dict:
        match stream.platform:
            case "yt":                              return self.youtube_api.get_stream_from_shortcode(stream.inp_value)
            case "ttv":
                if type(stream.inp_value) == str:   return self.twitch_api.get_live_stream_by_streamer(stream.inp_value)
                elif type(stream.inp_value) == int: return self.twitch_api.get_video_by_id(stream.inp_value)
    





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

    # format the args to be [ ["key1", "val1"], ["key2", "val2"], ...]
    # this allows 2 keys to be identical

    outp_list = []
    for arg in args:
        key, val = arg.split(" ")
        key = key.replace("-", "")
        outp_list.append( [key, val] )
        
    return outp_list




if __name__ == "__main__":
    try:
        parsed_args = parse_cmd_args()
        Program(parse_cmd_args())
    except Exception as err:
        sys.stderr.write(f"Error : {type(err).__name__} - {err}")



# *2
#*  stream title
#*  streamer name
#*  raw input,
#*  started at timestamp utc
#*  ended at timestamp utc
#*  is live?

