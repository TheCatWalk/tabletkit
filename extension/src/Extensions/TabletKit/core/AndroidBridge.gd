extends RefCounted

var failure := ""


func render_view():
	if OS.get_name() != "Android":
		failure = "not Android"
		return null
	if not Engine.has_singleton("AndroidRuntime"):
		failure = "no Android runtime"
		return null
	var activity = Engine.get_singleton("AndroidRuntime").getActivity()
	var godot = activity.getGodot() if activity else null
	var view = godot.getRenderView() if godot else null
	if view == null:
		failure = "no render view"
	return view


func private_field(owner, field_name: String):
	var field = owner.getClass().getDeclaredField(field_name)
	field.setAccessible(true)
	var object_class = JavaClassWrapper.wrap("java.lang.Class").forName("java.lang.Object")
	var getter = field.getClass().getMethod("get", [object_class])
	return getter.invoke(field, [owner])
