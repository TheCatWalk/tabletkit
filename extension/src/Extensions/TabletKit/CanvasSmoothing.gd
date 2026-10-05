extends RefCounted

const SmoothIndicators := preload("res://src/Extensions/TabletKit/SmoothIndicators.gd")
const FRAGMENT := "void fragment() {"
const LAYER_HELPERS := """
vec4 tablet_kit_fetch(ivec2 cell, ivec2 last, int layer) {
	vec4 texel = texelFetch(layers, ivec3(clamp(cell, ivec2(0), last), layer), 0);
	return vec4(pow(texel.rgb, vec3(2.2)) * texel.a, texel.a);
}

vec4 tablet_kit_bilinear(vec2 texel_pos, ivec2 last, int layer) {
	vec2 corner = texel_pos - 0.5;
	ivec2 base = ivec2(floor(corner));
	vec2 weight = corner - floor(corner);
	vec4 top = mix(
		tablet_kit_fetch(base, last, layer), tablet_kit_fetch(base + ivec2(1, 0), last, layer), weight.x
	);
	vec4 bottom = mix(
		tablet_kit_fetch(base + ivec2(0, 1), last, layer),
		tablet_kit_fetch(base + ivec2(1, 1), last, layer),
		weight.x
	);
	return mix(top, bottom, weight.y);
}

vec4 tablet_kit_sample(vec3 coords) {
	vec2 size = vec2(textureSize(layers, 0).xy);
	vec2 texel_pos = coords.xy * size;
	vec2 dx = dFdx(texel_pos);
	vec2 dy = dFdy(texel_pos);
	vec2 footprint = sqrt(dx * dx + dy * dy);
	ivec2 last = ivec2(size) - 1;
	int layer = int(coords.z + 0.5);
	vec4 color;
	if (max(footprint.x, footprint.y) <= 1.001) {
		vec2 seam = floor(texel_pos + 0.5);
		vec2 extent = max(abs(dx) + abs(dy), vec2(1e-5));
		vec2 offset = clamp((texel_pos - seam) / extent, -0.5, 0.5);
		color = tablet_kit_bilinear(seam + offset, last, layer);
	} else {
		color = 0.25 * (
			tablet_kit_bilinear(texel_pos + 0.25 * (dx + dy), last, layer)
			+ tablet_kit_bilinear(texel_pos + 0.25 * (dx - dy), last, layer)
			+ tablet_kit_bilinear(texel_pos - 0.25 * (dx - dy), last, layer)
			+ tablet_kit_bilinear(texel_pos - 0.25 * (dx + dy), last, layer)
		);
	}
	return color.a > 0.0 ? vec4(pow(color.rgb / color.a, vec3(1.0 / 2.2)), color.a) : vec4(0.0);
}

"""
const EDGE_HELPER := """
float tablet_kit_edge(vec2 uv) {
	vec2 dx = dFdx(uv);
	vec2 dy = dFdy(uv);
	vec2 extent = max(abs(dx) + abs(dy), vec2(1e-6));
	vec2 inside = min(uv, 1.0 - uv) / extent;
	return clamp(min(inside.x, inside.y) + 0.5, 0.0, 1.0);
}

"""
const LAYER_PATCH := {
	"texture(layers, vec3(": "tablet_kit_sample(vec3(",
	"COLOR = result_color;": "COLOR = result_color;\n\tCOLOR.a *= tablet_kit_edge(UV);",
	FRAGMENT: LAYER_HELPERS + EDGE_HELPER + FRAGMENT,
}
const CHECKER_PATCH := {
	"COLOR.a = alpha;": "COLOR.a = alpha * tablet_kit_edge(UV);",
	FRAGMENT: EDGE_HELPER + FRAGMENT,
}

var _originals := {}
var _indicator_script: Script


func install() -> bool:
	var layers_patched := _patch(Global.canvas.material, LAYER_PATCH)
	_patch(Global.transparent_checker.material, CHECKER_PATCH)
	_indicator_script = Global.canvas.indicators.get_script()
	Global.canvas.indicators.set_script(SmoothIndicators)
	Global.canvas.queue_redraw()
	return layers_patched


func uninstall() -> void:
	for material: ShaderMaterial in _originals:
		if is_instance_valid(material):
			_swap_shader(material, _originals[material])
	_originals.clear()
	if _indicator_script:
		Global.canvas.indicators.set_script(_indicator_script)
		_indicator_script = null
	Global.canvas.queue_redraw()


func _patch(material: Material, replacements: Dictionary) -> bool:
	if not material is ShaderMaterial or material.shader == null:
		return false
	var code: String = material.shader.code
	for target in replacements:
		if not code.contains(target):
			return false
	for target in replacements:
		code = code.replace(target, replacements[target])
	var patched := Shader.new()
	patched.code = code
	_originals[material] = material.shader
	_swap_shader(material, patched)
	return true


func _swap_shader(material: ShaderMaterial, shader: Shader) -> void:
	var values := {}
	for uniform in material.shader.get_shader_uniform_list():
		values[uniform.name] = material.get_shader_parameter(uniform.name)
	material.shader = shader
	for parameter in values:
		material.set_shader_parameter(parameter, values[parameter])
