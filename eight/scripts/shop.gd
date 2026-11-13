class_name Shop
extends Control
## The shop, opened from the pentagram: banked feathers buy permanent ranks of core stats that
## every hub-launched run starts with. Each row shows the upgrade, its rank as pips (shape, not
## only color), and the next price; a purchase saves at once and is refused if it cannot be
## kept. Vector UI from the shared theme.

const PIP_ON: String = "◆"
const PIP_OFF: String = "◇"

var progress: Progress
var rows: Dictionary = {}

@onready var list: VBoxContainer = $Panel/Box/List
@onready var balance: Label = $Panel/Box/Balance
@onready var notice: Label = $Panel/Box/Notice


func _ready() -> void:
	progress = Progress.load_saved()
	($Panel/Box/Back as Button).pressed.connect(close)
	for entry: Dictionary in Progress.UPGRADES:
		var row: HBoxContainer = HBoxContainer.new()
		row.name = String(entry["id"]).capitalize()
		row.add_theme_constant_override(&"separation", 16)
		var title: Label = Label.new()
		title.name = &"Title"
		title.custom_minimum_size = Vector2(150.0, 0.0)
		title.theme_type_variation = &"HeadingLabel"
		title.add_theme_font_size_override(&"font_size", 18)
		title.text = String(entry["name"]).to_upper()
		var detail: Label = Label.new()
		detail.name = &"Detail"
		detail.custom_minimum_size = Vector2(250.0, 0.0)
		detail.add_theme_font_size_override(&"font_size", 15)
		detail.text = entry["text"]
		var pips: Label = Label.new()
		pips.name = &"Pips"
		pips.custom_minimum_size = Vector2(130.0, 0.0)
		pips.add_theme_font_size_override(&"font_size", 24)
		var buy: Button = Button.new()
		buy.name = &"Buy"
		buy.focus_mode = Control.FOCUS_NONE
		buy.custom_minimum_size = Vector2(130.0, 34.0)
		buy.add_theme_font_size_override(&"font_size", 15)
		buy.pressed.connect(purchase.bind(entry["id"]))
		for child: Control in [title, detail, pips, buy]:
			child.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(child)
		list.add_child(row)
		rows[entry["id"]] = row
	_refresh()
	get_window().size_changed.connect(_on_size_changed)
	_on_size_changed()
	# Theatrical entrance: the rows deal in one after another.
	for index: int in range(list.get_child_count()):
		_pop_in(list.get_child(index) as Control, 0.05 + index * 0.05)


func _on_size_changed() -> void:
	var ui: float = Game.ui_scale_for(Vector2(get_window().size))
	if not is_equal_approx(get_window().content_scale_factor, ui):
		get_window().content_scale_factor = ui


func _refresh() -> void:
	balance.text = "FEATHERS  %d" % progress.feathers
	for entry: Dictionary in Progress.UPGRADES:
		var id: String = entry["id"]
		var row: Control = rows[id]
		var rank: int = progress.rank(id)
		var ranks: int = (entry["costs"] as Array).size()
		(row.get_node(^"Pips") as Label).text = PIP_ON.repeat(rank) + PIP_OFF.repeat(ranks - rank)
		var buy: Button = row.get_node(^"Buy") as Button
		var cost: int = progress.next_cost(id)
		buy.text = "MAX" if cost < 0 else "BUY  %d" % cost
		buy.disabled = cost < 0 or progress.feathers < cost


func purchase(id: String) -> void:
	var error: Error = progress.buy(id)
	if error == OK:
		notice.text = ""
		_flash(rows[id])
	elif error != ERR_UNAVAILABLE:
		notice.text = "THE PURCHASE COULD NOT BE SAVED (ERROR %d)" % error
	_refresh()


func close() -> void:
	get_tree().change_scene_to_file(Game.HUB_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _pop_in(control: Control, delay: float) -> void:
	control.modulate.a = 0.0
	var tween: Tween = control.create_tween().set_ignore_time_scale()
	tween.tween_property(control, ^"modulate:a", 1.0, 0.18).set_delay(delay)


## A bought row flashes bright, then settles.
func _flash(row: Control) -> void:
	row.modulate = Color(2.0, 2.0, 1.6, 1.0)
	var tween: Tween = row.create_tween().set_ignore_time_scale()
	tween.tween_property(row, ^"modulate", Color.WHITE, 0.35)
