# TabletKit

A [Pixelorama](https://github.com/Orama-Interactive/Pixelorama) extension that makes drawing on an Android tablet with a pen feel like a proper drawing app.

It was made on an XPPen Magic Note Pad (Android 14) with the X3 Pro Pencil 2, running Pixelorama 1.2.3. It should help on other Android tablets with a pen that has a side button, but it has only been tested on that one.

## What it does

**Pen**
- The pen's side button works as the eraser (or whatever tool you put on the right mouse button).
- Pressing or releasing the side button in the middle of a stroke switches between pencil and eraser without lifting the pen.
- The side button no longer zooms the canvas by accident.
- Long-press the pen to pick a colour (or use the bucket). The dot the pen made is removed again.

**Fingers**
- Fingers never draw. One finger moves the canvas (you can change this to eyedropper, erase, draw or nothing).
- Double-tap with one finger to fit the whole canvas on the screen and straighten it.
- Two fingers pinch to zoom, as before.

**Gestures**
- Tap with two fingers to undo, three fingers to redo.
- Hold two fingers still to keep undoing.
- Twist two fingers to rotate the canvas (off by default). It snaps to straight angles.

**Palm safety**
- While the pen touches the screen, and for a moment after, fingers and palms are ignored.

Everything can be switched on or off in **Preferences → Touch**.

## Install

1. Download `TabletKit.zip` from the [Releases](../../releases) page onto your tablet.
2. In Pixelorama, open **Preferences → Extensions → Add Extension** and pick the zip.
3. Close Pixelorama completely and open it again.

To update, add the new zip the same way and restart Pixelorama.

## Known limits

These come from the tablet or from Android, not from TabletKit:

- While the pen hovers just above the screen, the tablet ignores fingers completely. Move the pen away to use finger gestures.
- Some tablets have a system three-finger gesture (often for screenshots). On the tablet this was made on, it grabs three-finger touches even when switched off in settings, so three-finger taps work but holding three fingers does not.
- Two-finger rotate and some other parts need Android. On a PC, TabletKit's pen and touch fixes simply do nothing.

## Why this is needed

Pixelorama runs on the Godot engine. On Android, Godot mishandles the pen's side button in three ways, so a plain extension has to work around it. The details, with evidence, are in [docs/android-stylus-findings.md](docs/android-stylus-findings.md).

## For developers

- `extension/` is the TabletKit source. Zip the `src` folder inside it (or run `python tools/scripts/make_zip.py extension TabletKit.zip`).
- `tools/PenRecorder/` is a small extension that records pen and touch input to `Download/PenRecorder/takeN.jsonl`. It was used to find the problems.
- `examples/recordings/` holds five recordings from the tablet, made without any fix, showing what Godot actually reports.
- `docs/changes.md` explains how TabletKit grew out of the first attempt and why each change was made.

## Licence

MIT. See [LICENSE](LICENSE).
