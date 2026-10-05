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

**Canvas display quality**
- With **High quality** (the default), a rotated canvas shows straight, smooth pixel edges instead of jagged steps, like Clip Studio Paint's "High quality" display.
- The canvas is drawn at the screen's full resolution. Pixelorama otherwise draws it at a lower resolution when the interface is scaled up.
- Pixel edges, the canvas border, guides and the brush outline are smoothed only on screen. Your image, saved files and exports are not changed. When the canvas is not rotated and zoomed to whole steps, pixels show exactly as before.
- Choose **Default** to get Pixelorama's original display back.

**Top bar and layouts**
- The pen tip's and side button's main tool settings (size, density, opacity or amount) sit in the top bar, after Main Menu. Tap the left or right half to step, drag sideways to slide. They never open the on-screen keyboard.
- The top bar scrolls sideways with one finger when it does not fit, for example in portrait.
- Two layouts are added under **Window → Layouts**: **Tablet** (layers on the right) and **Tablet Portrait** (canvas on top). TabletKit adds them once and never switches layout by itself. In **Preferences → Touch → Layouts** you can choose a layout for landscape and one for portrait, and TabletKit switches when you rotate the tablet.

**Pen fixes**
- Tapping layers and other list items with the pen works every time. Godot started a scroll on the pen's tiny lift movement, which cancelled the tap; lists now need a 10 px drag before they scroll.

**Save to file automatically**
- Off by default. Turn it on in **Preferences → Backup → Save to file**, and set how many seconds between saves.
- It also saves when you leave Pixelorama. It only saves drawings that already have a file, never in the middle of a stroke.
- While it is on, the save icon in the top bar is blue.
- Pixelorama's own "autosave" only writes crash-recovery backups; it never saves your file.

Everything else can be switched on or off in **Preferences → Touch**.

**Safety**
- At start, TabletKit checks every part of Pixelorama it relies on. If a Pixelorama update changed one of them, only the affected TabletKit feature switches itself off; Pixelorama keeps working normally. **Preferences → Touch → Other → Compatibility** shows "All features available" or which feature is off and why.
- Disabling TabletKit in Preferences → Extensions restores Pixelorama exactly as it was.

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
- High quality display covers the main canvas only, not the second canvas or the small preview. Image brushes, tile mode and active selections keep Pixelorama's own brush outline.
- Finger gestures (two-finger tap undo, hold, twist) only count when the first finger lands on the main canvas.
- Automatic saving also saves mistakes. Pixelorama's crash-recovery backups (Preferences → Backup) keep earlier versions.

## Other extensions

Tested together with TabletKit 1.1.0 on Pixelorama 1.2.3 (Android), all loading without problems: LospecPaletteImporter, ColorChecker, TimeTracking, Skeletor, LineArt, ReferenceUpdater and CopyLayerFx.

Known conflict:

- **LocalCheckerSize.** With Display quality set to High quality, TabletKit sets the transparency checkerboard size every frame from Pixelorama's global setting (scaled to the screen), so LocalCheckerSize's per-project sizes are overwritten. Set Display quality to Default if you need per-project checker sizes.

## Why this is needed

Pixelorama runs on the Godot engine. On Android, Godot mishandles the pen's side button in three ways, so a plain extension has to work around it. The details, with evidence, are in [docs/android-stylus-findings.md](docs/android-stylus-findings.md).

## For developers

- `extension/` is the TabletKit source. Zip the `src` folder inside it (or run `python tools/scripts/make_zip.py extension TabletKit.zip`).
  - `Main.gd` only wires the modules together.
  - `core/`: settings, the Preferences page, compatibility checks and shared helpers.
  - `fixes/`: always-on corrections to how Godot and Pixelorama behave with a pen (side button, stylus events, scroll deadzone, scrollable top bar).
  - `features/`: optional additions, each with its own setting (gestures, finger modes, long press, display quality, tool strip, layouts, save to file).
- `tools/PenRecorder/` is a small extension that records pen and touch input to `Download/PenRecorder/takeN.jsonl`. It was used to find the problems.
- `examples/recordings/` holds five recordings from the tablet, made without any fix, showing what Godot actually reports.
- `docs/changes.md` explains how TabletKit grew out of the first attempt and why each change was made.

## Licence

MIT. See [LICENSE](LICENSE).
