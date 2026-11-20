class_name BossIntro
extends CanvasLayer
## A non-modal arrival card. Run holds only the arriving boss, never the player or the horde;
## this strip ignores input and the boss resumes when the card leaves.

signal finished

const HOLD_TIME: float = 1.8

var map: int = 0


func _ready() -> void:
	layer = 4
	process_mode = Node.PROCESS_MODE_ALWAYS
	var portrait: TextureRect = $Slider/Portrait
	portrait.visible = GlassArt.has_boss_art(map)
	if portrait.visible:
		portrait.texture = load(GlassArt.BOSS_ART[map]) as Texture2D
		GlassArt.dress(portrait)
	else:
		($Slider/TextBlock as Control).offset_left = 80.0
		($Slider/TextBlock as Control).offset_right = -80.0
	_refresh_text()
	var slider: Control = $Slider
	var travel: float = get_viewport().get_visible_rect().size.x + 40.0
	slider.position.x = -travel
	var tween: Tween = create_tween().set_ignore_time_scale()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(slider, ^"position:x", 0.0, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(HOLD_TIME)
	tween.tween_property(slider, ^"position:x", travel, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(_finish)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh_text()


func _refresh_text() -> void:
	($Slider/TextBlock/BossName as Label).text = tr(GlassArt.BOSS_NAMES[map])
	# Satan rules no sin: his card names his circle instead of repeating his name.
	($Slider/TextBlock/Realm as Label).text = tr("THE EIGHTH CIRCLE") if map == Run.SATAN else tr(Run.BOSSES[map]["name"])


func _finish() -> void:
	finished.emit()
	queue_free()
