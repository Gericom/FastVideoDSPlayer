FastVideoDS Player
===================
Player for the FastVideoDS format. Opens the video file supplied by argv, or otherwise `testVideo.fv` on the root of your sd card.

## Features
- Supports long videos
- Smooth playback by adjusting the lcd refresh rate to an integer multiple of the frame rate
- Supports up to 60 fps on dsi (~30 fps on ds)
- Uses the 3d engine for motion compensation
- Loads data from the sd card and decodes audio on the arm7 while the arm9 is fully available for decoding video
- Argv support (for use with TWiLight Menu++ for example)
- Video controls: play/pause and keyframe seeking
- Disables the backlight of the bottom screen while playing to save energy

## Controls
### Buttons
- A - Play/pause
- Dpad left - Jump to previous keyframe (hold to keep going)
- Dpad right - Jump to next keyframe (hold to keep going)

### Touch
The touch screen can be used to play/pause the video and to seek by tapping/dragging the seek bar.

## Libraries Used
- [FatFS](http://elm-chan.org/fsw/ff/00index_e.html)