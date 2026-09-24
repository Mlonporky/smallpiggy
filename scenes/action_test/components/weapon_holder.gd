extends Node2D
## Draws the equipped weapon in the animated hand. Angle and grip come from Visuals, so wind-up,
## sweep and recovery rotate continuously instead of jumping between three fixed poses.
const Art = preload("res://scenes/chapter2/underground/weapon_art.gd")
## Weapons are drawn smaller to suit the smaller pig; hit reach is unchanged (see weapon resources).
const SIZE := 0.72


func _ready() -> void:
	scale = Vector2.ONE * SIZE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var visuals = get_parent()
	var p = visuals.get_parent()
	if not p.combat or not p.combat.weapon or p.roll_time > 0:
		return
	var weapon = p.combat.weapon
	var mirror: float = visuals.turn
	var angle: float = (visuals.weapon_angle + visuals.lean) * signf(mirror if mirror != 0 else 1.0)
	var at: Vector2 = visuals.hand / SIZE
	if weapon.kind == "sword":
		Art.paint(self, 3, at, angle, mirror)
	elif weapon.kind == "dagger":
		draw_set_transform(at, angle, Vector2(mirror, 1))
		var blade := PackedVector2Array([Vector2(0, -5), Vector2(31, -5), Vector2(45, 0), Vector2(31, 5), Vector2(0, 5)])
		draw_colored_polygon(blade, Color("dedfba"))
		draw_polyline(PackedVector2Array([Vector2(0, -5), Vector2(31, -5), Vector2(45, 0), Vector2(31, 5), Vector2(0, 5)]), Color("6f735e"), 1.5, true)
		draw_line(Vector2(-12, 0), Vector2(0, 0), Color("a58161"), 7, true)
		draw_set_transform(Vector2.ZERO)
	else:
		draw_set_transform(at, angle, Vector2(mirror, 1))
		draw_line(Vector2(-12, 0), Vector2(63, 0), Color("947452"), 7, true)
		var head := StyleBoxFlat.new()
		head.bg_color = Color("92998b")
		head.border_color = Color("4d5249")
		head.set_border_width_all(2)
		head.set_corner_radius_all(5)
		head.anti_aliasing = true
		draw_style_box(head, Rect2(44, -19, 32, 38))
		draw_rect(Rect2(47, -16, 26, 5), Color("c0c6a9"))
		draw_set_transform(Vector2.ZERO)
