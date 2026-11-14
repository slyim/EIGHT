class_name Settings
extends RefCounted
## Player settings, saved apart from progress in user://settings.cfg: a graphics quality step
## that layers the look-development effects (each step adds to the one below), display options
## that trade smoothness for cost, and gameplay-feel options (damage numbers, screen shake,
## and hit-stop). Invalid or missing values fall back to defaults. Applied to hub-launched runs
## and the window; F6 runs and tests keep the scene defaults (which match HIGH, all feel on).

## Tests point this at their own file so they never touch the player's settings.
static var path: String = "user://settings.cfg"

enum Quality { LOW, MEDIUM, HIGH, ULTRA }

const QUALITY_NAMES: Array[String] = ["LOW", "MEDIUM", "HIGH", "ULTRA"]
## What each step adds, for the settings panel.
const QUALITY_NOTES: Array[String] = [
	"No glow, no lamp shadows, no extra effects. Cheapest.",
	"Glow, hard lamp shadows, lava shimmer, and pulsing sin eyes.",
	"Adds soft shadows, world haze, and a wider bloom.",
	"Adds two-tone light pools.",
]
## Frame-rate caps; 0 is unlimited.
const FPS_CAPS: Array[int] = [30, 60, 120, 0]
## Screen-shake scales; 1.0 is full strength.
const SHAKE_SCALES: Array[float] = [0.0, 0.5, 1.0]
## PLACEHOLDER-tunable strengths the quality steps switch between (on values match the
## approved look; off is 0).
const HAZE_ON: float = 0.18
const SHIMMER_ON: float = 0.14
const PULSE_ON: float = 0.3
const BLOOM_WIDE: float = 0.3
const CORE_WHITEN_ON: float = 0.8
const SHADOW_SMOOTH: float = 4.0

var quality: Quality = Quality.HIGH
var vsync: bool = true
## Index into FPS_CAPS.
var fps_cap: int = 3
var fullscreen: bool = false
var damage_numbers: bool = true
## Index into SHAKE_SCALES.
var shake: int = 2
var hit_stop: bool = true


static func load_saved() -> Settings:
	var settings: Settings = Settings.new()
	var file: ConfigFile = ConfigFile.new()
	if file.load(path) != OK:
		return settings
	var stored: Variant = file.get_value("graphics", "quality", Quality.HIGH)
	if stored is int and stored >= 0 and stored < QUALITY_NAMES.size():
		settings.quality = stored
	stored = file.get_value("display", "vsync", true)
	settings.vsync = stored if stored is bool else true
	stored = file.get_value("display", "fps_cap", 3)
	if stored is int and stored >= 0 and stored < FPS_CAPS.size():
		settings.fps_cap = stored
	stored = file.get_value("display", "fullscreen", false)
	settings.fullscreen = stored if stored is bool else false
	stored = file.get_value("gameplay", "damage_numbers", true)
	settings.damage_numbers = stored if stored is bool else true
	stored = file.get_value("gameplay", "shake", 2)
	if stored is int and stored >= 0 and stored < SHAKE_SCALES.size():
		settings.shake = stored
	stored = file.get_value("gameplay", "hit_stop", true)
	settings.hit_stop = stored if stored is bool else true
	return settings


func save() -> Error:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("graphics", "quality", quality)
	file.set_value("display", "vsync", vsync)
	file.set_value("display", "fps_cap", fps_cap)
	file.set_value("display", "fullscreen", fullscreen)
	file.set_value("gameplay", "damage_numbers", damage_numbers)
	file.set_value("gameplay", "shake", shake)
	file.set_value("gameplay", "hit_stop", hit_stop)
	return file.save(path)


## The window: vsync, frame cap, and fullscreen (window mode is left alone when headless).
func apply_display(window: Window) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = FPS_CAPS[fps_cap]
	if DisplayServer.get_name() != "headless":
		window.mode = Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED


## The run's effects for this quality step and gameplay-feel options. Safe to call again mid-run.
func apply_run(run: Run) -> void:
	var medium: bool = quality >= Quality.MEDIUM
	var high: bool = quality >= Quality.HIGH
	var environment: Environment = (run.get_node(^"WorldEnvironment") as WorldEnvironment).environment
	environment.glow_enabled = medium
	environment.set_glow_level(2, BLOOM_WIDE if high else 0.0)
	var lamp: PointLight2D = run.player.get_node(^"Lamp") as PointLight2D
	lamp.shadow_enabled = medium
	lamp.shadow_filter = PointLight2D.SHADOW_FILTER_PCF13 if high else PointLight2D.SHADOW_FILTER_NONE
	lamp.shadow_filter_smooth = SHADOW_SMOOTH
	run.veil.set_shader_parameter(&"haze_strength", HAZE_ON if high else 0.0)
	(run.lava.material as ShaderMaterial).set_shader_parameter(&"shimmer", SHIMMER_ON if medium else 0.0)
	# The sin eyes share one material across every enemy.
	Enemy.EYE_MATERIAL.set_shader_parameter(&"pulse", PULSE_ON if medium else 0.0)
	(run.get_node(^"Lighting/Lights").material as ShaderMaterial).set_shader_parameter(&"core_whiten", CORE_WHITEN_ON if quality >= Quality.ULTRA else 0.0)
	run.hud.damage_numbers_enabled = damage_numbers
	run.player.shake_scale = SHAKE_SCALES[shake]
	run.player.hit_stop_enabled = hit_stop
