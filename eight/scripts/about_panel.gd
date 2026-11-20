class_name AboutPanel
extends Control
## Team and license credits from the repository's CREDITS.md files and bundled licenses.

signal closed


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiMotion.watch(self)
	_refresh_text()
	($Panel/Box/Close as Button).pressed.connect(close)
	($Panel/Box/Close as Button).grab_focus()
	UiMotion.pop_in($Panel, 0.0, 0.2)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh_text()


func _refresh_text() -> void:
	($Panel/Box/Heading as Label).text = tr("ABOUT")
	($Panel/Box/Version as Label).text = tr("ALPHA  v%s") % ProjectSettings.get_setting(&"application/config/version", "0.1")
	($Panel/Box/Scroll/Credits/TeamHeading as Label).text = tr("TEAM")
	($Panel/Box/Scroll/Credits/CreditsHeading as Label).text = tr("CREDITS")
	($Panel/Box/Scroll/Credits/Art as Label).text = tr("Artwork, audio and game: Mustafa Yıldız, Lila Aydın, Ahmet Altuğ Aktaş. Vector illustrations: Ahmet Altuğ Aktaş.")
	($Panel/Box/Scroll/Credits/Logo as Label).text = tr("EIGHT logo & license: © 2026 Mustafa Yıldız, Lila Aydın, Ahmet Altuğ Aktaş. All Rights Reserved.")
	($Panel/Box/Scroll/Credits/Fonts as Label).text = tr("Fonts: Cinzel Bold and Alegreya Sans (SIL Open Font License 1.1).")
	($Panel/Box/Scroll/Credits/Icons as Label).text = tr("Icons: Phosphor Icons (MIT).")
	($Panel/Box/Scroll/Credits/Engine as Label).text = tr("Engine: Godot Engine (MIT). Importer: Aseprite Wizard by Vinicius Gerevini (MIT).")
	($Panel/Box/Close as Button).text = tr("CLOSE  [Esc]")


func close() -> void:
	closed.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
