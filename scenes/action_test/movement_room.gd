extends Node2D
## Movement test room and shared base for the action test rooms.
## The world renders at native resolution (no low-res canvas), so characters and terrain stay crisp
## at any window size. UI lives on its own CanvasLayer; the camera zoom only fits 1536×864 world units.
const Player = preload("res://scenes/action_test/player.tscn")
const Follow = preload("res://scenes/action_test/components/follow_camera.gd")
const Terrain = preload("res://scenes/action_test/components/terrain_painter.gd")
const Backdrop = preload("res://scenes/action_test/components/backdrop.gd")
const Midground = preload("res://scenes/action_test/components/midground.gd")
const BG = preload("res://assets/chapter2/underground/root_grotto_v1.png")
const VIEW := Vector2(1536, 864)
const PLATFORMS := [Rect2(0,900,1000,500),Rect2(1130,900,950,500),Rect2(2230,900,2570,500),Rect2(660,840,140,60),Rect2(900,750,160,24),Rect2(1170,660,160,24),Rect2(1450,570,210,24)]
var world: Node2D
var player: CharacterBody2D
var camera: Camera2D
var backdrop: Node2D
var midground: Node2D
var ui: CanvasLayer
var stage: Control
var hud: Label
var debug_label: Label
var paused := false
var terrain_layer: Node2D
var fx_layer: Node2D
var pause_notice: Label
var particles: Array[Dictionary] = []
var platforms: Array = []
var bounds := Rect2(0, 0, 4800, 1400)


func _ready() -> void:
	bounds = room_bounds()
	build_stage()
	platforms = room_platforms()
	build_platforms()
	terrain_layer = Node2D.new()
	terrain_layer.name = "Terrain"
	world.add_child(terrain_layer)
	build_terrain()
	spawn_player(Vector2(160, 900))
	hud.text = "移动试验室  ·  A/D 移动  空格短/长跳  Esc暂停  R重来  F3调试"


func room_platforms() -> Array:
	return PLATFORMS.duplicate()


func room_bounds() -> Rect2:
	return Rect2(0, 0, 4800, 1400)


func build_terrain() -> void:
	for rect in platforms:
		add_terrain_piece(func(canvas: CanvasItem): Terrain.paint(canvas, rect))


## One canvas item per piece, so Godot skips pieces outside the camera instead of re-submitting
## every antialiased shape of the whole level each frame.
func add_terrain_piece(painter: Callable) -> Node2D:
	var piece := Node2D.new()
	terrain_layer.add_child(piece)
	piece.draw.connect(func(): painter.call(piece))
	return piece


func build_stage() -> void:
	backdrop = Backdrop.new()
	backdrop.name = "Backdrop"
	add_child(backdrop)
	backdrop.setup(BG, bounds, VIEW)
	midground = Midground.new()
	midground.name = "Midground"
	add_child(midground)
	midground.setup(bounds, VIEW)
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	world.draw.connect(draw_world)
	camera = Follow.new()
	camera.bounds = bounds
	world.add_child(camera)
	camera.make_current()
	fx_layer = Node2D.new()
	fx_layer.name = "Effects"
	fx_layer.z_index = 20
	world.add_child(fx_layer)
	fx_layer.draw.connect(draw_fx)
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	stage = Control.new()
	stage.size = VIEW
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(stage)
	stage.add_child(_vignette())
	var backing := Panel.new()
	backing.position = Vector2(25, 22)
	backing.size = Vector2(1486, 85)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.08, 0.06, 0.72)
	style.set_corner_radius_all(14)
	style.anti_aliasing = true
	backing.add_theme_stylebox_override("panel", style)
	stage.add_child(backing)
	hud = label("", Vector2(44, 35), 23)
	debug_label = label("", Vector2(44, 125), 21)
	debug_label.visible = false
	pause_notice = label("已暂停 · Esc继续", Vector2(620, 380), 30)
	pause_notice.visible = false
	layout()


func _vignette() -> TextureRect:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0, 0, 0, 0))
	gradient.set_color(1, Color(0.01, 0.03, 0.02, 0.55))
	gradient.add_point(0.62, Color(0, 0, 0, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.08, 1.0)
	texture.width = 256
	texture.height = 144
	var rect := TextureRect.new()
	rect.texture = texture
	rect.size = VIEW
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func label(value: String, at: Vector2, font_size: int) -> Label:
	var node := Label.new()
	node.position = at
	node.text = value
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", Color("f2e4bf"))
	node.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	node.add_theme_constant_override("shadow_offset_x", 2)
	node.add_theme_constant_override("shadow_offset_y", 2)
	stage.add_child(node)
	return node


func build_platforms() -> void:
	for rect in platforms:
		solid(rect)
	solid(Rect2(bounds.position.x - 60, bounds.position.y - 400, 60, bounds.size.y + 800))
	solid(Rect2(bounds.end.x, bounds.position.y - 400, 60, bounds.size.y + 800))
	# Safe catch floor beneath gaps; steps make the fall recoverable.
	for rect in [Rect2(930,1120,1380,280),Rect2(1050,1030,110,24),Rect2(2070,1030,130,24)]:
		platforms.append(rect)
		solid(rect)


func solid(rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	world.add_child(body)
	return body


func spawn_player(at: Vector2) -> void:
	player = Player.instantiate()
	player.position = at
	world.add_child(player)
	player.movement_fx.connect(burst)
	camera.target = player
	snap_view()


func snap_view() -> void:
	camera.snap_to_target()
	backdrop.follow(camera.position)
	midground.follow(camera.position)
	backdrop.reset_physics_interpolation()
	midground.reset_physics_interpolation()


func burst(kind: String, at: Vector2, amount: float) -> void:
	var count := 3 if kind == "run" else 9
	var color := Color("c9c79a")
	var spread := Vector2(70, 55)
	match kind:
		"hit":
			color = Color("f4ecc8")
			spread = Vector2(150, 120)
		"heal":
			color = Color("f1b39a")
		"stomp", "bounce":
			color = Color("e8d9a8")
			count = 12
		"land":
			count = int(4 + 6 * amount)
	for i in count:
		var vel := Vector2(randf_range(-spread.x, spread.x), randf_range(-spread.y, -12)) * maxf(0.4, amount)
		particles.append({"pos": at + Vector2(randf_range(-6, 6), -2), "vel": vel, "life": 0.42, "max": 0.42, "color": color, "size": randf_range(2.5, 4.5)})


func step_fx(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var dust: Dictionary = particles[i]
		dust.life -= delta
		dust.vel = dust.vel * (1.0 - 3.0 * delta) + Vector2(0, 120 * delta)
		dust.pos += dust.vel * delta
		if dust.life <= 0:
			particles.remove_at(i)


func _physics_process(delta: float) -> void:
	layout()
	if paused:
		return
	step_fx(delta)
	follow_view(delta)
	handle_fall()
	debug_label.text = "State %s\nVelocity %s\nGrounded %s\nCoyote %.2f  Buffer %.2f" % ["GROUND" if player.is_on_floor() else "AIR", player.velocity, player.is_on_floor(), player.grace, player.buffer]
	world.queue_redraw()
	fx_layer.queue_redraw()


func handle_fall() -> void:
	if player.position.y > bounds.end.y - 50:
		player.reset_at(Vector2(160, 900))
		snap_view()


func follow_view(delta: float) -> void:
	camera.follow(delta)
	backdrop.follow(camera.position)
	midground.follow(camera.position)


func layout() -> void:
	var size := get_viewport_rect().size
	var fit := minf(size.x / VIEW.x, size.y / VIEW.y)
	stage.scale = Vector2.ONE * fit
	stage.position = (size - VIEW * fit) * 0.5
	camera.zoom = Vector2.ONE * fit
	camera.view = size / fit


## Converts a world point to stage (UI) coordinates, for labels that follow the world.
func world_to_stage(at: Vector2) -> Vector2:
	var screen := world.get_viewport().get_canvas_transform() * at
	return (screen - stage.position) / stage.scale.x


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	if event.keycode == KEY_ESCAPE:
		paused = not paused
		player.paused = paused
		pause_notice.visible = paused
	elif event.keycode == KEY_R:
		get_tree().reload_current_scene()
	elif event.keycode == KEY_F3:
		debug_label.visible = not debug_label.visible


func draw_world() -> void:
	pass


func draw_fx() -> void:
	for dust in particles:
		var alpha := clampf(dust.life / dust.max, 0, 1)
		fx_layer.draw_circle(dust.pos, dust.size * (0.6 + 0.4 * alpha), Color(dust.color, alpha * 0.85), true, -1, true)
