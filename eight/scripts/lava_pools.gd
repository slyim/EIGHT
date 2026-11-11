class_name LavaPools
extends Node2D
## PLACEHOLDER lava pools: molten circles drawn on the floor under everything that moves.
## Only the grounded angel burns: exposure builds while standing in a pool and ticks on
## its own rhythm without ever starting or extending the hurt invulnerability, so burn
## ticks cannot be swallowed by their own window and lava cannot shield from enemies
## (an in-progress hurt-blink delays a tick instead). Flying over lava and dashing
## through it are safe and reset exposure. Enemies, bosses, projectiles, and movement
## ignore lava entirely.

@export_group("Burn")
## PLACEHOLDER balance: health lost per tick while standing in lava.
@export_range(1, 40, 1) var burn_damage: int = 8
## Seconds between burn ticks once the grace has elapsed.
@export_range(0.1, 3.0, 0.05) var burn_interval: float = 0.5
## Seconds of standing in lava before the first tick, so brushes across the edge burn nothing.
@export_range(0.0, 2.0, 0.05) var burn_grace: float = 0.4
## Shrink of the burn zone against the drawn rim, in px.
@export_range(0.0, 60.0, 1.0) var burn_inset: float = 12.0

@export_group("Look")
## Seconds between shimmer repaints; a cheap fixed rate, never per frame.
@export_range(0.05, 1.0, 0.01) var shimmer_period: float = 0.12

## Dark solidified rim. PLACEHOLDER colors: the molten channels exceed 1.0, so the pools
## glow once the HDR 2D + glow settings land (plain orange until then).
const CRUST_COLOR: Color = Color(0.11, 0.045, 0.025)
const MOLTEN_COLOR: Color = Color(1.02, 0.46, 0.09)
const BUBBLE_COLOR: Color = Color(1.9, 0.85, 0.25)
const CRUST_WIDTH: float = 10.0
const BUBBLES_PER_POOL: int = 3
const BUBBLE_DISTANCES: Array[float] = [0.35, 0.7, 0.5]
## Orange wash on the angel after each burn tick; RGB only, so the hurt-blink alpha and
## the death tint stay untouched.
const BURN_FLASH_COLOR: Color = Color(1.7, 0.75, 0.4)
const BURN_FLASH_TIME: float = 0.45

## Per pool: center, extent (blob reach from center), blobs [[Vector2, radius], ...],
## and fixed bubble anchors inside the main blob.
var pools: Array[Dictionary] = []
## Set by Run; the only creature that burns.
var player: MountedPlayer
## True while the angel is exposed to lava (the HUD burn indicator follows it).
var burning: bool = false
var burn_left: float = 0.0
var burn_flash_left: float = 0.0
var shimmer_left: float = 0.0
var shimmer_time: float = 0.0


## Replaces the stage's pools. Each entry is one pool's blobs with absolute centers
## (the node sits at the run's origin); extent and bubbles are derived here.
func set_pools(pool_blobs: Array) -> void:
	pools = []
	for blobs: Array in pool_blobs:
		var center: Vector2 = blobs[0][0]
		var extent: float = 0.0
		for blob: Array in blobs:
			extent = maxf(extent, center.distance_to(blob[0]) + (blob[1] as float))
		var bubbles: Array[Vector2] = []
		var reach: float = maxf(0.0, (blobs[0][1] as float) - CRUST_WIDTH - 8.0)
		var phase: float = fposmod(center.x * 0.013 + center.y * 0.029, TAU)
		for bubble: int in range(BUBBLES_PER_POOL):
			var angle: float = phase + TAU * float(bubble) / float(BUBBLES_PER_POOL)
			bubbles.append(center + Vector2.from_angle(angle) * reach * BUBBLE_DISTANCES[bubble % BUBBLE_DISTANCES.size()])
		pools.append({"center": center, "extent": extent, "blobs": blobs, "bubbles": bubbles})
	burn_left = 0.0
	burning = false
	queue_redraw()


## True when the point sits inside molten lava. A positive inset shrinks the zone (the
## forgiving burn edge); a negative one grows it, e.g. -(RADIUS + pad) keeps a portal of
## that radius clear of every pool.
func point_in_lava(point: Vector2, inset: float = 0.0) -> bool:
	for pool: Dictionary in pools:
		var pool_reach: float = (pool["extent"] as float) - inset
		if pool_reach <= 0.0 or point.distance_squared_to(pool["center"]) > pool_reach * pool_reach:
			continue
		for blob: Array in pool["blobs"]:
			var molten: float = (blob[1] as float) - inset
			if molten <= 0.0:
				continue
			if point.distance_squared_to(blob[0]) <= molten * molten:
				return true
	return false


func _physics_process(delta: float) -> void:
	# Shimmer: advance and repaint at a low fixed rate, never per frame.
	shimmer_left -= delta
	if shimmer_left <= 0.0:
		shimmer_left = shimmer_period
		shimmer_time += shimmer_period
		if not pools.is_empty():
			queue_redraw()
	_decay_flash(delta)
	var exposed: bool = _player_exposed()
	burning = exposed
	if not exposed:
		# Leaving the lava (or flying / dashing over it) restarts exposure from zero.
		burn_left = 0.0
		return
	if burn_left <= 0.0:
		burn_left = burn_grace
	if burn_left > 0.0:
		burn_left = maxf(0.0, burn_left - delta)
		if burn_left > 0.0:
			return
	burn_left = burn_interval
	if player.apply_burn(burn_damage):
		burn_flash_left = BURN_FLASH_TIME


## Grounded, not dashing, alive, and with its ground point inside molten lava.
func _player_exposed() -> bool:
	return (
		player != null and is_instance_valid(player) and not player.is_dead
		and not player.is_airborne() and player.dash_time_left <= 0.0
		and point_in_lava(player.position, burn_inset)
	)


## Fades the burn flash back to white after each tick.
func _decay_flash(delta: float) -> void:
	if burn_flash_left <= 0.0:
		return
	if player == null or not is_instance_valid(player) or player.is_dead:
		burn_flash_left = 0.0
		return
	burn_flash_left = maxf(0.0, burn_flash_left - delta)
	var tint: Color = Color.WHITE.lerp(BURN_FLASH_COLOR, burn_flash_left / BURN_FLASH_TIME)
	player.modulate = Color(tint.r, tint.g, tint.b, player.modulate.a)


func _draw() -> void:
	# PLACEHOLDER lava art: dark crust rims, molten fill, and slow bubbles. Each pool
	# draws all crusts before its molten so overlapping blobs merge without seams.
	for index: int in pools.size():
		var pool: Dictionary = pools[index]
		for blob: Array in pool["blobs"]:
			draw_circle(blob[0], blob[1], CRUST_COLOR)
		var heat: float = 0.92 + 0.08 * sin(shimmer_time * 2.1 + 1.7 * float(index))
		var molten: Color = Color(MOLTEN_COLOR.r * heat, MOLTEN_COLOR.g * heat, MOLTEN_COLOR.b * heat)
		for blob: Array in pool["blobs"]:
			draw_circle(blob[0], maxf(0.0, (blob[1] as float) - CRUST_WIDTH), molten)
		for bubble: Vector2 in pool["bubbles"]:
			var rise: float = 0.5 + 0.5 * sin(shimmer_time * 3.1 + bubble.x * 0.37 + bubble.y * 0.11)
			if rise < 0.2:
				continue
			draw_circle(bubble, 2.0 + 4.0 * rise, BUBBLE_COLOR)
