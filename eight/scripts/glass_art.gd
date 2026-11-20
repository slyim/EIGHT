class_name GlassArt
extends RefCounted
## The team's smooth vector illustrations, shown as slowly lit stained glass in menu portraits.

const SHADER: Shader = preload("res://shaders/stained_glass.gdshader")
const BOSS_ART: Array[String] = [
	"", "", "res://assets/art/vector/lilith.png", "res://assets/art/vector/loki.png", "",
	"res://assets/art/vector/kerberos.png", "res://assets/art/vector/edward.png", "res://assets/art/vector/satan.png",
]
const BOSS_NAMES: Array[String] = ["ODIN", "MIDAS", "LILITH", "LOKI", "WENDIGO", "KERBEROS", "EDWARD", "SATAN"]


static func has_boss_art(map: int) -> bool:
	return map >= 0 and map < BOSS_ART.size() and not BOSS_ART[map].is_empty()


static func material() -> ShaderMaterial:
	var glass: ShaderMaterial = ShaderMaterial.new()
	glass.shader = SHADER
	glass.set_shader_parameter(&"sweep_strength", 0.25)
	return glass


static func dress(portrait: TextureRect) -> void:
	# Smooth vector art is deliberately not sampled like the world's pixel sprites.
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.material = material()
