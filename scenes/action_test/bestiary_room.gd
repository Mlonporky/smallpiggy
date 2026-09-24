extends "res://scenes/action_test/combat_room.gd"
## 怪物试炼场 · one pen per monster on a flat floor, to try each behaviour on its own.
## 1 / 2 / 3 switch sword / dagger / hammer, R resets every monster and heals. Knock-outs just heal
## you on the spot. Standalone: no GameState or save file.
const Art = preload("res://scenes/action_test/level/level_art.gd")
const Sound = preload("res://scenes/action_test/components/sound_fx.gd")
const WEAPONS := [
	preload("res://scenes/action_test/weapons/sword.tres"),
	preload("res://scenes/action_test/weapons/dagger.tres"),
	preload("res://scenes/action_test/weapons/hammer.tres")]
const FLOOR_Y := 900.0
const PENS := [
	{"kind": "slime", "at": Vector2(700, 900), "sign": "苔团史莱姆 · 蓄力跳扑 · 可踩"},
	{"kind": "big_slime", "at": Vector2(1450, 900), "sign": "大苔团 · 打倒后分裂成两只"},
	{"kind": "burr_hog", "at": Vector2(2250, 900), "sign": "栗刺球 · 「!」后冲撞 · 晕了可踩", "patrol_width": 120.0},
	{"kind": "puffcap", "at": Vector2(3000, 900), "sign": "噗噗菇 · 孢子可打散 · 踩它弹高"},
	{"kind": "moth", "at": Vector2(3750, 690), "sign": "灰翅夜蛾 · 发光后俯冲 · 空中可踩"},
	{"kind": "acorn_spider", "at": Vector2(4480, 528), "sign": "橡果蛛 · 从头顶垂下拦路"},
	{"kind": "moss_snail", "at": Vector2(5250, 900), "sign": "苔壳蜗牛 · 正面挡刀 · 打背后或用锤", "patrol_width": 90.0}]
## Ledge the acorn spider hangs from.
const LEDGE := Rect2(4300, 500, 360, 28)
var audio_fx: Node
var knocked := 0.0


func room_bounds() -> Rect2:
	return Rect2(0, 0, 5800, 1400)


func room_platforms() -> Array:
	return [Rect2(0, FLOOR_Y, 5800, 500), LEDGE]


func build_platforms() -> void:
	for rect in platforms:
		solid(rect)
	solid(Rect2(-60, -400, 60, 2200))
	solid(Rect2(5800, -400, 60, 2200))


func build_terrain() -> void:
	super.build_terrain()
	for pen in PENS:
		var at: Vector2 = Vector2(pen.at.x - 230, FLOOR_Y)
		add_terrain_piece(func(canvas: CanvasItem): Art.sign(canvas, at, pen.sign))


func _ready() -> void:
	super._ready()
	audio_fx = Sound.new()
	add_child(audio_fx)
	player.dodge_enabled = true
	player.combat.swung.connect(func(): audio_fx.cue("swing"))
	player.health.died.connect(func(): knocked = 0.6)
	reset_monsters()
	player.reset_at(Vector2(160, FLOOR_Y))
	snap_view()


func reset_monsters() -> void:
	for enemy in enemies:
		enemy.queue_free()
	enemies.clear()
	for pen in PENS:
		var options: Dictionary = pen.duplicate()
		for key in ["kind", "at", "sign"]:
			options.erase(key)
		spawn_enemy(pen.kind, pen.at, options)


func hit_feedback(at: Vector2, duration: float) -> void:
	super.hit_feedback(at, duration)
	cue("hit")


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if knocked > 0:
		knocked -= delta
		if knocked <= 0:
			player.health.reset_health()
			player.control_enabled = true
	var weapon: Resource = player.combat.weapon
	hud.text = "怪物试炼场  ·  生命 %d / 100  ·  武器：%s\nA/D 移动  空格跳  J 攻击  Shift 翻滚  1/2/3 剑/匕首/锤  R 重置怪物  Esc 暂停  F3 调试" % [player.health.hp, weapon.display_name if weapon else "空手"]


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		match event.keycode:
			KEY_1, KEY_2, KEY_3:
				player.combat.reset_attack()
				player.combat.weapon = WEAPONS[event.keycode - KEY_1]
				return
			KEY_R:
				reset_monsters()
				player.health.reset_health()
				player.control_enabled = true
				return
	super._unhandled_key_input(event)
