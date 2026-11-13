class_name Game
extends Control
## Pixel-perfect host for one sin's map. The world renders into a fixed 640x360 SubViewport
## (one art pixel = 2 world units = 1 buffer pixel) shown at a whole-number scale, centered,
## with bars in the leftover space. The run's HUD is moved to this native-resolution root so
## the UI stays crisp, and the root's content scale grows the UI with the world (half the
## world scale: 1x at 1280x720, 1.5x at 1920x1080, 2x at 2560x1440). A won map is saved and
## returns to the hub after the ascension.

const WORLD_SIZE: Vector2i = Vector2i(640, 360)
## World units per buffer pixel: the art is drawn at 2x in world space.
const WORLD_ZOOM: float = 0.5
const GAME_SCENE: String = "res://scenes/game.tscn"
const HUB_SCENE: String = "res://scenes/hub.tscn"
## Seconds the saved realm stays on screen before returning to the hub.
const WIN_LINGER: float = 1.6

## The map the next Game loads (a BOSSES index; 7 is Satan). Kept across a restart (R).
static var map_index: int = 0

@onready var view: SubViewportContainer = $WorldView
@onready var run: Run = $WorldView/World/Run


## The editable map scene for a sin (see tools/bake_sin_maps.gd).
static func map_path(index: int) -> String:
	return "res://scenes/sins/%s.tscn" % String(Run.BOSSES[index]["name"]).to_lower()


## Opens a sin's map from anywhere (the hub).
static func start_map(tree: SceneTree, index: int) -> void:
	map_index = index
	tree.paused = false
	tree.change_scene_to_file(GAME_SCENE)


static func go_to_hub(tree: SceneTree) -> void:
	tree.paused = false
	tree.change_scene_to_file(HUB_SCENE)


func _notification(what: int) -> void:
	# Build the chosen map as soon as this scene is instantiated, so callers (and tests) can
	# configure the run before it enters the tree.
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		var map: Run = (load(map_path(map_index)) as PackedScene).instantiate() as Run
		map.name = &"Run"
		get_node(^"WorldView/World").add_child(map)


func _ready() -> void:
	run.get_node(^"HUD").reparent(self)
	run.hud.world_view = view
	run.hud.hub_requested.connect(go_to_hub.bind(get_tree()))
	run.finished.connect(_on_finished)
	(run.hud.get_node(^"SaveFailed/Retry") as Button).pressed.connect(_save_win)
	(run.hud.get_node(^"SaveFailed/Leave") as Button).pressed.connect(go_to_hub.bind(get_tree()))
	run.player.camera.zoom = Vector2(WORLD_ZOOM, WORLD_ZOOM)
	get_window().size_changed.connect(_on_size_changed)
	_on_size_changed()


func _on_finished(victory: bool) -> void:
	if victory:
		_save_win()
	# A defeat's end card offers Retry and Return to the pentagram.


## A win is saved before anything else; only then does the hub show the new relic. If the
## save fails, the player is told and chooses: try again, or return knowingly unsaved.
func _save_win() -> void:
	var progress: Progress = Progress.load_saved()
	progress.record_win(run.sin_index)
	var error: Error = progress.save()
	if error != OK:
		push_error("Could not save progress (error %d)." % error)
		run.hud.show_save_failed(error)
		return
	run.hud.save_failed.hide()
	Hub.just_sealed = run.sin_index
	# A static callable, so nothing resumes on this Game if the scene is gone by then.
	get_tree().create_timer(WIN_LINGER).timeout.connect(go_to_hub.bind(get_tree()))


func _on_size_changed() -> void:
	layout(Vector2(get_window().size))


## Whole-number scale that fits the window (physical pixels); never below 1.
static func scale_for(window: Vector2) -> int:
	return maxi(1, floori(minf(window.x / WORLD_SIZE.x, window.y / WORLD_SIZE.y)))


## UI scale for a window: half the world scale, so the UI keeps its size relative to the world.
static func ui_scale_for(window: Vector2) -> float:
	return scale_for(window) * 0.5


## Lays out for a window size in physical pixels. Layout positions are in UI units
## (physical / ui scale); the world frame lands on whole physical pixels.
func layout(window: Vector2) -> void:
	var factor: int = scale_for(window)
	var ui: float = ui_scale_for(window)
	if not is_equal_approx(get_window().content_scale_factor, ui):
		get_window().content_scale_factor = ui
	var frame: Vector2 = Vector2(WORLD_SIZE * factor)
	# Two UI units per buffer pixel at every scale, so the shrink stays 2.
	view.stretch_shrink = 2
	view.size = frame / ui
	view.position = ((window - frame) * 0.5).floor() / ui
