# Correcting for audio/video sync issues with the ffmpeg program’s ITSOFFSET switch

The ffmpeg program has numerous “switches” that help to adjust and convert audio and video files. Some of them are not explained very well in the documentation, and many websites have confusing postings by well-meaning people trying to make use of the switches. I will try to explain how to use a couple of these switches to correct common sync problems with videos. It will take some time to learn, but is very powerful once you understand it.

The itsoffset switch is used to nudge (forward or backward) the start time of either an audio or video “stream”. A typical video camera will record one video stream and one audio stream which are merged into one file. On my camera, they merge into an MTS high-def formatted file. But sometimes during a conversion to another file format (such as mp4), the audio and video will not remain in sync and the itsoffset switch can be used to adjust them.

The itsoffset switch is nearly always used in conjunction with the “map” switch, since this tells ffmpeg which stream you want to affect, and what streams you wish to merge into a new output file.

For our purposes, we will deal with just one input file that has two streams out of sync (the most common problem). We will use this one input file twice, once for its audio portion, and once for its video portion. We will use itsoffset and map to delay one of the streams, and then merge them back together into another file.

![](https://wjwoodrow.files.wordpress.com/2013/02/in-sync1.png)

There are a few different ways to accomplish the same result with minor variations, and I will try to demonstrate them. First I will demonstrate the syntax of the “map” and “itsoffset” switches and what they mean. Here is a picture to better clarify the description (click pic for better view):

![](https://wjwoodrow.files.wordpress.com/2013/02/ffcmd.png)

Map syntax:
-map “input file number”:”stream number”
The input file number will be 0 or 1, and stream will be 0 (video) or 1 (audio)

**An important side note on file numbering with ffmpeg: 0 is the first, 1 is the second**

“-map 0:1” means first input file mentioned on the command-line and its stream 1 (audio)
“-map 1:0” means second input file and stream 0 (video)
“-map 1:1” means second input file and stream 1 (audio)

“Itsoffset” is used with a specific amount of time that you want to apply to a file. If the audio is off by 1 second, you might type -itsoffset 1.0 (or -itsoffset 00:00:01.0000). Itsoffset applies to both streams of a file, and we use “map” to split out the stream we want to change. This is why we have to specify the input file twice, once for the stream we don’t change, and once for the stream we do change.

I’ll talk more about how to find the correct time shortly.

“-itsoffset 1.0 -i clip.mts” means to apply a 1 second delay to the input file clip.mts

> Also, it matters **WHERE** you put the itsoffset switch in the command-line.
 It applies to the input file that comes just after it.
 
 Trial and Error with a small clip
Finding the correct adjustment time can be tricky. Sometimes it may be out of sync by a tiny amount like 0.150 seconds, but it makes all the difference in the world when you get it correct. Trial and error is the only way I know to get it, so working with a 1 minute clip instead of the whole video you can get a fast answer. Once you have the clip fixed the way you like, you can apply the settings to the whole video.

To extract just a 1 minute portion of a video, try this:

```
ffmpeg -ss 15:30 -i 00001.MTS -vcodec copy -acodec copy -t 1:00 clip.mts
```

(takes the video 00001.MTS, goes to fifteen minutes and thirty seconds [-ss 15:30] and then takes 1 minute [-t 1:00] from there and creates a new file called clip.mts. There is often more action in the middle of a video, so I chose to start there.)

So we take the short clip and use it to adjust the sync. Go ahead and create a clip so you can experiment with it.

Examples
The following examples move a stream by 2.0 seconds so you can better perceive the change (assuming that you follow the examples with a clip of your own).

The following commandlines all result the same thing, “delay the audio by 2 seconds”. This means that in the output file, you will see the video start and then 2 seconds later the audio will start. The differences are the location of “itsoffset” and what stream is mapped:

ffmpeg -i clip.mts -itsoffset 2.0 -i clip.mts -vcodec copy -acodec copy -map 0:0 -map 1:1 delay1.mts
Applies itsoffset to file “1” (because it is placed just before the 2nd input), and the map for file 1 points to stream 1 (audio)

ffmpeg -i clip.mts -itsoffset 2.0 -i clip.mts -vcodec copy -acodec copy -map 1:1 -map 0:0 delay2.mts
Applies itsoffset to file “1” (because it is placed just before the 2nd input), and the map for
file 1 points to stream 1 (audio). I just changed the order of which map came first, it doesn’t matter.

ffmpeg -itsoffset 2.0 -i clip.mts -i clip.mts -vcodec copy -acodec copy -map 0:1 -map 1:0 delay3.mts
Applies itsoffset to file “0” (because it is placed just before the 1st input), and the map for
file 0 points to stream 1 (audio). So I changed the location of itsoffset and the mapping.

ffmpeg -i clip.mts -itsoffset -2.0 -i clip.mts -vcodec copy -acodec copy -map 0:1 -map 1:0 delay4.mts
This one adjusts the video forward 2 seconds rather than delaying the audio, but accomplishes the same thing. I gave a negative 2.0 value to itsoffset. Itsoffset is just before file 1, and map for file 1 points to stream 0 (video). That is, instead of waiting two seconds to start the audio, we tell the video to nudge back two seconds.

*Note: “-vcodec copy -acodec copy” can be shortened to “-c:v copy -c:a copy” This command keeps the same video and audio format in the output file as was in the input file.

That’s it for experiments with the clip.

Now lets deal with the two most common sync problems. Remember that we are using the out of sync file as the input twice, splitting out just one stream from each input, applying a delay to one of the streams, and then merging the streams back into an output file.

![](https://wjwoodrow.files.wordpress.com/2013/02/aud-ahead.png)

![](https://wjwoodrow.files.wordpress.com/2013/02/vid-ahead.png)

CASE 1: Audio happens before video (aka “need to delay audio stream 1”):
ffmpeg -i clip.mp4 -itsoffset 0.150 -i clip.mp4 -vcodec copy -acodec copy -map 0:0 -map 1:1 output.mp4

The “itsoffset” in the above example is placed before file 1 (remember that linux counts from 0, so 0 is the first and 1 is the second), so when the mapping happens, it says “Take the video of file 0 and the audio of file 1, leave the video of file 0 alone and apply the offset to the audio of file 1 and merge them into a new output file”. The delay is only .15 seconds.

CASE 2: Video happens before audio (aka “need to delay video stream 0”):
ffmpeg -i clip.mp4 -itsoffset 0.150 -i clip.mp4 -vcodec copy -acodec copy -map 0:1 -map 1:0 output.mp4

The “itsoffset” in the above example is placed before file 1. When the mapping happens, it says “Take the audio of file 0 and the video of file 1, leave the audio of file 0 alone and apply the offset to the video of file 1 and merge them into a new output file”. The delay is only .15 seconds.

I hope this all made sense to you and helps clarify what can be a very confusing command-line.
