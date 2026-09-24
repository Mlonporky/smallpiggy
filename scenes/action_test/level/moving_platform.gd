extends AnimatableBody2D
## Floating stone slab that travels between two top-left positions with eased motion and a short
## hold at each end (easy to board and leave). Moved on physics ticks by the level (`tick`), so it
## pauses with hit-stop and the pause menu; CharacterBody2D riders inherit its velocity.
const ONE_WAY_LAYER := 16
var start := Vector2.ZERO
var finish := Vector2.ZERO
var size := Vector2(160, 24)
var travel_time := 2.4
var hold_time := 0.8
var one_way := false
var clock := 0.0
var glow := 0.0


func setup(from: Vector2, to: Vector2, slab: Vector2, travel: float, hold: float, pass_through: bool) -> void:
	start = from
	finish = to
	size = slab
	travel_time = travel
	hold_time = hold
	one_way = pass_through
	sync_to_physics = true
	collision_layer = ONE_WAY_LAYER if one_way else 1
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = size
	shape.shape = box
	shape.position = size * 0.5
	shape.one_way_collision = one_way
	add_child(shape)
	position = start
	queue_redraw()


func progress_at(time: float) -> float:
	var cycle := 2.0 * (travel_time + hold_time)
	var t := fposmod(time, cycle)
	if t < hold_time:
		return 0.0
	t -= hold_time
	if t < travel_time:
		return smoothstep(0.0, 1.0, t / travel_time)
	t -= travel_time
	if t < hold_time:
		return 1.0
	t -= hold_time
	return 1.0 - smoothstep(0.0, 1.0, t / travel_time)


func tick(delta: float) -> void:
	clock += delta
	glow += delta
	position = start.lerp(finish, progress_at(clock))
	queue_redraw()


func _draw() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("59675a")
	box.border_color = Color("222b24")
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.anti_aliasing = true
	draw_style_box(box, Rect2(Vector2.ZERO, size))
	draw_line(Vector2(8, 4), Vector2(size.x - 8, 4), Color("93a58a"), 2.5, true)
	# Moss lip and a softly pulsing rune so moving slabs read differently from fixed ledges.
	draw_line(Vector2(4, 1), Vector2(size.x - 4, 1), Color("88a85a"), 3.0, true)
	var pulse := 0.55 + 0.45 * sin(glow * 2.6)
	var center := Vector2(size.x * 0.5, size.y * 0.58)
	draw_circle(center, 9, Color(0.72, 0.95, 0.78, 0.12 * pulse), true, -1, true)
	draw_arc(center, 5.5, 0, TAU, 16, Color(0.78, 1.0, 0.82, 0.55 * pulse), 1.8, true)
	draw_line(center + Vector2(-3, 0), center + Vector2(3, 0), Color(0.78, 1.0, 0.82, 0.6 * pulse), 1.5, true)
	for side in [-1.0, 1.0]:
		var x: float = center.x + side * size.x * 0.32
		draw_circle(Vector2(x, center.y), 2.2, Color(0.78, 1.0, 0.82, 0.45 * pulse), true, -1, true)
	if one_way:
		for i in int(size.x / 22):
			var at := Vector2(12 + i * 22, size.y + 3)
			draw_line(at, at + Vector2(0, 7 + (i % 3) * 3), Color("41583a"), 2.0, true)
