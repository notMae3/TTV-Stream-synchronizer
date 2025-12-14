# Stream synchronizer
Takes a timestamp relative to twitch VOD 1 and calculates the translated timestamp of VOD 2. This allows you to easily view a moment from a twitch collab from a different persepctive without having to search for the timestamp.

![Example image of the program showing the timestamp 02:12:35, which is relative to stream 2, translated onto stream 1 where the timestamp is 04:56:11](/demo%20img.png)

> [!NOTE]
> **This project was never intended for public consumption.**
> Thus, in order to use it, you need to supply a Twitch client-id, Twitch client-secret and a Google API key.
> Additionally, the credentials are stored as plaintext in a JSON file in the directory of the main exe, which is obviously a major security flaw.
