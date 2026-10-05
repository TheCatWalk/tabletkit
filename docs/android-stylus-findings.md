# Android stylus findings

What Godot 4.7.2 does with a pen's side button on Android, why it breaks drawing in Pixelorama, and how TabletKit works around it.

Tested on an XPPen Magic Note Pad (Android 14, model MNP1095) with the X3 Pro Pencil 2, Pixelorama 1.2.3 (Godot 4.7.2).

## The hardware is fine

Reading the pen directly from Android's input device (`getevent`) shows clean, correct signals: `BTN_TOUCH` when the tip touches, `BTN_STYLUS` when the side button is pressed, and normal position, pressure and tilt. Every problem below happens after Android hands the events to Godot.

## Problem 1: the side button becomes "button 0"

**What happens:** Touching the screen with the side button held gives Godot a mouse press with `button_index = 0` (`MOUSE_BUTTON_NONE`) and motion events with `button_mask = 0`, even though the pen is touching. Godot also logs `Condition "button == MouseButton::NONE" is true` for each of these presses. Pixelorama ignores button 0, so nothing happens.

**Why:** Android reports the side button as `BUTTON_STYLUS_PRIMARY` in the event's button state. `GodotInputHandler.handleMouseEvent` only adds `BUTTON_PRIMARY` when the button state is 0, and the native side (`AndroidInputHandler::_android_button_mask_to_godot_button_mask`) has no mapping for the stylus buttons, so the mask ends up empty.

**Evidence:** `examples/recordings/2-side-button-held.jsonl` shows a button 0 press and release around a stroke whose motion events all have mask 0 but pressure above 0.

## Problem 2: the side button turns strokes into zoom gestures

**What happens:** About one in five strokes started with the side button held produces only `InputEventMagnifyGesture` events and no motion at all, so the stroke has no positions. The canvas zooms instead.

**Why:** `GodotInputHandler` calls `scaleGestureDetector.setStylusScaleEnabled(true)`. Android's `ScaleGestureDetector` then treats "stylus button held + drag" as a quick-scale gesture. Whether drawing or zooming wins depends on timing (`GodotGestureHandler.onScaleBegin` refuses to start while a drag is in progress, and `onScroll` stops sending motion while a scale is in progress).

**Evidence:** `examples/recordings/4-button-released-mid-stroke.jsonl` starts with a button 0 press followed by 1.4 seconds of magnify events and no motion.

## Problem 3: releasing the side button ends the stroke

**What happens:** Releasing the side button while the tip is still touching makes Godot report a mouse release. After that, no events at all arrive until the pen is lifted, so the rest of the stroke is lost.

**Why:** Android delivers `ACTION_BUTTON_RELEASE` through `onGenericMotionEvent` (it is not a touch event). `GodotGestureHandler.onActionUp` handles `ACTION_BUTTON_RELEASE` like `ACTION_UP` while a drag is in progress and sends an up event. The native side then marks the pointer as released and drops the following move events.

**Evidence:** `examples/recordings/3-button-pressed-then-released-mid-stroke.jsonl`: the raw pen shows the tip down for about 7 seconds, but Godot reports the release when the button goes up after about 3 seconds and nothing after it.

## Smaller findings

- Godot's `GodotGestureHandler.onScale` drops scale steps outside 0.8 to 1.2, so a fast pinch produces no magnify events at all.
- During two-finger gestures Godot sends pan and magnify summaries but no per-finger `InputEventScreenDrag`, so finger positions are not available to scripts.
- `enable_long_press_as_right_click` also applies to the pen, so holding the pen still at the start of a stroke can turn it into a right-click.
- In GDScript, calling a Java method whose name matches a Godot `Object` method (for example `Field.get`) runs the Godot method instead, because `JavaObject::callp` gives Godot methods precedence.
- Pixelorama turns on single tool mode by default on touchscreens, which keeps both mouse buttons on the same tool.

## How TabletKit works around it

TabletKit is a normal Pixelorama extension, so it cannot change Godot. It works at two levels:

1. **Inside Godot**, a node that sees input first rewrites the pen's events: a touch with pressure but no button becomes a right-button press, and pressing or releasing the button mid-stroke becomes a release of one button and a press of the other.
2. **On the Android side**, through Godot's Java bridge (`JavaClassWrapper` and the `AndroidRuntime` plugin):
   - a `View.OnGenericMotionListener` on Godot's view swallows the stylus `ACTION_BUTTON_PRESS` and `ACTION_BUTTON_RELEASE` events, so Godot never sees the release that ends the stroke;
   - reflection switches off `setStylusScaleEnabled` on Godot's `ScaleGestureDetector`, and `enableLongPress(false)` switches off long-press right-click.

A real fix belongs in Godot's Android input code; TabletKit only works around it.

## Tablet limits found along the way

- The tablet ignores all finger touches while the pen hovers within range. Other drawing apps behave the same on it.
- A system screenshot listener cancels touches as soon as a third finger lands, even with the three-finger screenshot setting off.
