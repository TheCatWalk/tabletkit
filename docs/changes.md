# How TabletKit came about

TabletKit started as "PenButtonFix", a small extension meant to make the side button erase. This is what changed between that first attempt (v0.3) and TabletKit 1.0.0, and why.

## The first attempt was built on wrong assumptions

v0.3 assumed the side button arrived as the right mouse button (index 2, mask 2). Recordings from the tablet showed it never does: Godot reports it as button 0 with mask 0. v0.3 waited for mask 2, so it never erased.

## Changes, in order

1. **Read the pen properly.** Instead of waiting for mask 2, a touch with pressure above 0 and no button is treated as the side button. The corrected events are sent back through Godot's input, so Pixelorama handles them as a real right-click everywhere, including right-clicking a tool to put it on the side button.
2. **Fix positions on scaled screens.** Re-sent events must be in window pixels. Without converting them, lines started from the wrong place on tablets that scale the interface.
3. **Keep strokes alive when the button is released.** Godot ends the stroke on button release. A listener on Godot's Android view now swallows the stylus button press and release events before Godot sees them.
4. **Stop the side button from zooming.** Godot's stylus zoom feature is switched off through reflection.
5. **Settings page.** A Touch page in Preferences, in Pixelorama's own style, with a reset button for each setting.
6. **Finger and gesture features.** Fingers never draw; one finger moves the canvas; two- and three-finger taps undo and redo; holding two fingers repeats undo; two-finger twist rotates around the fingers; one-finger double-tap fits the canvas; pen long press picks a colour.
7. **Palm safety.** Fingers are ignored while the pen touches the screen and for a short moment after. Hold-to-repeat only starts if both fingers land at the same time, because a resting palm settles gradually.
8. **No crash on quit.** Detaching from Android while Pixelorama was shutting down crashed it. TabletKit now only detaches when it is disabled while Pixelorama keeps running.

## 1.1.0

### Canvas display quality

On a rotated canvas, pixel edges looked jagged at every zoom. Three causes, each fixed on screen only:

1. **Nearest-pixel sampling.** At angles other than 0°, 90°, 180° and 270°, every screen pixel picks one whole art pixel, which makes staircases. TabletKit patches Pixelorama's layer shader so the border between two art pixels is blended over one screen pixel (with the correct width for the angle, mixed in linear light). Zoomed-out views are filtered as well. When the canvas is straight and zoomed to whole steps, every screen pixel still shows exactly one art colour.
2. **Half-resolution canvas.** With the interface scaled 2×, Godot renders the canvas viewport at half the screen's resolution and stretches it. TabletKit adds a second viewport that shares the canvas's 2D world, renders it at full resolution and shows it on top. Pixelorama's viewport still receives all input, so pen positions are unchanged; it just stops rendering.
3. **Hard lines.** The canvas border, guides and the brush outline were drawn without smoothing. They are now smoothed too.

Clip Studio Paint ("Display quality: High quality") and Krita (display filtering) solve the same problem the same way, on screen only. The option is under Preferences → Touch → Canvas → Display quality.

Tried and dropped: MSAA on the canvas viewport (no effect with Godot's Compatibility renderer), and resizing the canvas viewport itself (Godot passes input to it in the smaller coordinates, so every pen position would have needed correcting).

### Tablet workflow

- **Pen taps on lists.** Tapping a layer with the pen often only highlighted it. Logging showed the pen sends a 1-2 px hover movement as it lifts; Godot's ScrollContainer (scroll deadzone 0 by default) treats any movement after a press as a touch scroll, and starting a scroll cancels the pressed button. TabletKit sets a 10 px deadzone on every ScrollContainer.
- **Top bar.** Pixelorama's top bar is wider than a portrait screen, which made the whole window wider than the screen and pinned every dock split. TabletKit wraps the bar in a horizontal scroll area, keeps Main Menu and its tool strip pinned on the left, and lets one-finger drags on buttons scroll it.
- **Tool strip.** Pixelorama's sliders open the on-screen keyboard on a tap. The strip mirrors the pen-tip and side-button tool's main sliders as touch steppers and follows tool, layer and brush changes.
- **Layouts.** "Tablet" and "Tablet Portrait" are created once after Pixelorama has opened. Pixelorama remembers the selected layout by its position in the list, so TabletKit re-saves that position after adding them.
- **Save to file.** Optional automatic saving every N seconds and when the app is left, using Pixelorama's normal save without the notification.

### Safety and structure

- **Compatibility checks.** At start, every feature's dependencies on Pixelorama internals are checked; a feature whose checks fail stays off and is listed in Preferences → Touch → Other → Compatibility, so a Pixelorama update can switch off one feature instead of breaking the app.
- **Clean disable.** Turning TabletKit off restores Pixelorama exactly (shaders, canvas rendering, top bar, scroll lists, save icon, guides). Verified on the tablet before release.
- **Code layout.** `core/` holds shared plumbing, `fixes/` the always-on corrections to Pixelorama/Godot behaviour, `features/` the optional additions.

## Ideas that were tried and dropped

- **Quick pinch to fit the canvas.** Detecting a "quick" pinch by speed could not tell a deliberate flick from a normal zoom-out reliably, and people pinch at different speeds. One-finger double-tap replaced it.
- **Four-finger tap for Zen Mode.** The tablet's system grabs the touch once a third finger lands, so four fingers never reach the app.
- **Blocking fingers while the pen hovers.** Unnecessary, since the tablet already ignores fingers while the pen hovers.
