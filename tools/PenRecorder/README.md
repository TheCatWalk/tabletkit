# Pen Recorder

A small Pixelorama extension that records every pen, finger and gesture event, so you can see exactly what your tablet sends.

## Use

1. Zip the `src` folder in this directory (or run `python tools/scripts/make_zip.py tools/PenRecorder PenRecorder.zip` from the repository root) and add it in **Preferences → Extensions**.
2. A **● REC** button appears in the top-right corner. Drag it if it is in the way.
3. Tap **● REC**, do what you want to record, then tap **■ STOP**.
4. The take is saved to `Download/PenRecorder/takeN.jsonl` on the tablet.

The same toggle is also in **Edit → Pen Recorder: start / stop**.

## File format

One JSON object per line.

- **Line 1** is a header: Pixelorama and Godot versions, tablet model, window size, canvas position, camera zoom, offset and rotation, project size, and the tools on each mouse button.
- **Each other line** is one input event. `t` is the time in milliseconds since recording started, `type` is the Godot event class, and the remaining fields depend on the type:

| Field | Meaning |
|---|---|
| `b`, `p`, `m` | mouse button index, pressed, button mask |
| `pos`, `rel` | position and movement in window coordinates |
| `pr`, `tilt`, `inv` | pen pressure, tilt, eraser end |
| `i`, `cancel` | finger index, touch cancelled by the system |
| `f` | zoom factor of a pinch gesture |
| `delta` | movement of a two-finger pan gesture |

The taps on the STOP button at the end are removed automatically.
