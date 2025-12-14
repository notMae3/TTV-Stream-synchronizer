import requests, sys

def get_access_token(client_id, client_secret) -> dict:
    # only needs to be used once the access_token
    # expires, which happens every ~60 days

    client_id = client_id.split(" ")[1]
    client_secret = client_secret.split(" ")[1]

    base_url = "https://id.twitch.tv/oauth2/token"

    headers = {
        "client_id": client_id,
        "client_secret": client_secret,
        "grant_type": "client_credentials"
    }

    response = requests.post(base_url, json=headers)
    data = response.json()

    # handle potential errors
    if "message" in data.keys():
        raise Exception(data["message"])
    
    else:
        return data

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
    try:
        parsed_args = parse_cmd_args()
        access_token = get_access_token(*parsed_args)
        sys.stdout.write(str(access_token))
    except Exception as err:
        sys.stderr.write(f"Error : {type(err).__name__} - {err}")

# example input (args must be in order)
# .exe -clientID [clientID] -clientSecret [clientSecret]

# example output
# {'access_token': 'am8mgl3z5ea6z7ae34zlug5pxxebe9', 'expires_in': 5347715, 'token_type': 'bearer'}
