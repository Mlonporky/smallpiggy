extends PiggyPlayer
## Act II uses the fine-shaded cape/armed sheets; the opening has a matching plate.
# wake reuses the source sheet's smaller expression row: its standing head is
# 175 px wide against 195 px for cape_down_00, so its lying/sitting poses need 0.53 × 1.11.
const SHEET_SCALE := {"cape": 0.53, "armed": 0.53, "wake": 0.59}
const FX = preload("res://scenes/chapter2/combat_fx.gd")
var jump_time := 0.0
var jump_cooldown := 0.0
var jump_height := 0.0
var joy_power := false
var story_protected := false
var swing_stick: Sprite2D
var shadow: Polygon2D
var attack_time := 0.0
var attack_direction := Vector2.DOWN
var hurt_time := 0.0
var aura_time := 0.0
var atlas_data: Dictionary
var armed := false
var waking := false
var wake_frame := 0

func _ready() -> void:
	atlas_data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/chapter2/pig_unified/atlas.json"))
	character_id = "little_pig"
	handpainted_room = true
	visible_height = 115.0
	sheet_override = preload("res://assets/chapter2/pig_unified/cape.png")
	super._ready()
	# Use the same sampling policy as the boy, cabbage, wizard and slime.
	sprite.texture_filter = CharacterSpriteStyle.FILTER
	sprite.modulate = Color.WHITE
	$HurtBox/CollisionShape2D.position = Vector2(0, -35)
	shadow = visual_root.get_node("Shadow")
	shadow.reparent(self)
	shadow.position = Vector2.ZERO
	swing_stick = Sprite2D.new()
	swing_stick.texture = preload("res://assets/chapter2/stick.png")
	swing_stick.texture_filter = CharacterSpriteStyle.FILTER
	swing_stick.centered = false
	swing_stick.offset = Vector2(-260,-1040)
	swing_stick.scale = Vector2.ONE * 0.06
	swing_stick.visible = false
	visual_root.add_child(swing_stick)

func _wants_interaction() -> bool:
	return Input.is_action_just_pressed("interact") and not Input.is_action_just_pressed("jump")

func _physics_process(delta: float) -> void:
	jump_cooldown = maxf(0, jump_cooldown - delta)
	if input_enabled and Input.is_action_just_pressed("jump"): jump()
	if jump_time > 0:
		jump_time = maxf(0, jump_time - delta)
		jump_height = sin((1.0 - jump_time / 0.65) * PI) * 65.0
		if jump_time == 0:
			jump_height = 0
			FX.spawn(get_parent(), position, "land", Vector2.RIGHT, Color("d4c3ae"), 35)
	hurt_time = maxf(0, hurt_time - delta)
	if joy_power:
		aura_time -= delta
		if aura_time <= 0:
			aura_time = 0.6
			FX.spawn(get_parent(), position + Vector2(0,-45-jump_height), "aura", Vector2.RIGHT, Color(1,0.78,0.4,0.6), 38)
	super._physics_process(delta)

func jump() -> void:
	if not input_enabled or waking or _attacking or jump_cooldown > 0: return
	jump_time = 0.65
	jump_cooldown = 0.95
	FX.sound(self, "swing")

func _update_visual(delta: float) -> void:
	_animation_clock += delta
	walk_phase = fposmod(walk_phase + _travelled / 110.0, 1.0)
	var row := 0
	if _facing == Vector2.LEFT: row = 1
	elif _facing == Vector2.UP: row = 2
	elif _facing == Vector2.RIGHT: row = 3
	var count := 3 if armed and not _attacking else 4
	var frame_index := int(walk_phase * count) % count if _travelled > 0.05 else 0
	if _attacking:
		attack_time += delta
		frame_index = 1 if attack_time < 0.14 else 2
	_show_frame(row * count + frame_index)
	visual_root.position = Vector2(0, -jump_height)
	if _attacking:
		var progress := clampf(attack_time / 0.48, 0, 1)
		var swing := sin(progress * PI)
		visual_root.position += attack_direction * swing * 10
		visual_root.rotation = (-0.15 if attack_time < 0.14 else 0.20 * (1-progress)) * (-1 if attack_direction.x < 0 else 1)
		visual_root.scale = Vector2(1 + swing * 0.04, 1 - swing * 0.035)
	else:
		visual_root.rotation = sin(hurt_time * 40) * hurt_time * 0.15
		visual_root.scale = Vector2.ONE
	if is_instance_valid(swing_stick):
		swing_stick.visible = _attacking
		if _attacking:
			swing_stick.position = Vector2(-38 if attack_direction.x < 0 or attack_direction == Vector2.UP else 38,-52)
			var swing_phase := clampf((attack_time - 0.10) / 0.20,0,1)
			swing_stick.rotation = attack_direction.angle() + 0.90 + lerpf(-1.1,1.0,swing_phase)
			swing_stick.z_index = -1 if attack_direction == Vector2.UP else 1
	if is_instance_valid(shadow):
		shadow.scale = Vector2.ONE * (1.0 - jump_height / 150.0)
		shadow.color.a = 0.27 - jump_height / 500.0

func _show_frame(index: int) -> void:
	if not is_instance_valid(sprite) or atlas_data.is_empty(): return
	var key := "wake" if waking else ("armed" if armed and not _attacking else "cape")
	var r: Array = atlas_data[key][wake_frame if waking else index]
	sprite.texture = load("res://assets/chapter2/pig_unified/%s.png" % key)
	sprite.region_rect = Rect2(r[0], r[1], r[2], r[3])
	# Constant scale per sheet preserves volume through poses, with feet aligned.
	var factor: float = SHEET_SCALE[key]
	sprite.scale = Vector2.ONE * factor
	var pivot: Array = atlas_data["pivot"]
	sprite.position = -Vector2(float(pivot[0]), float(pivot[1])) * factor

func wake_up() -> void:
	waking = true
	for i in 5:
		wake_frame = i
		await get_tree().create_timer(0.48).timeout
	# The authored standing pose (wake 5) has a narrower cape and arms than the
	# walking sheet and still reads smaller; stand up on cape_down_00 instead.
	waking = false
	face(Vector2.DOWN)
	await get_tree().create_timer(0.48).timeout

func attack() -> void:
	if _attacking or not combat_enabled or jump_time > 0: return
	_attacking = true
	attack_time = 0
	attack_direction = _facing
	attack_started.emit()
	velocity = Vector2.ZERO
	await get_tree().create_timer(0.14, false).timeout
	if health.current_health <= 0:
		_attacking = false
		return
	hit_box.damage = 2 if joy_power else 1
	hit_box.position = attack_direction * 65 + Vector2(0,-32)
	FX.spawn(get_parent(), position + Vector2(0,-35), "slash", attack_direction, Color("ffd67c") if joy_power else Color("e5e1d7"), 100 if joy_power else 85)
	FX.sound(self, "swing")
	hit_box.activate(0.14)
	await get_tree().create_timer(0.34, false).timeout
	_attacking = false

func _on_damaged(source: HitBox2D) -> void:
	if _invulnerable or story_protected or jump_height > 20 or health.current_health <= 0: return
	_invulnerable = true
	hurt_box.invulnerable = true
	hurt_time = 0.45
	FX.spawn(get_parent(), position + Vector2(0,-40), "impact", Vector2.RIGHT, Color("ffa4ac"), 60)
	FX.sound(self, "impact")
	sprite.modulate = Color("ffb2bb")
	# Collision-aware recoil, never teleport through cave walls.
	move_and_collide((global_position - source.global_position).normalized() * 18)
	health.damage(source.damage)
	await get_tree().create_timer(0.18, false).timeout
	sprite.modulate = Color.WHITE
	await get_tree().create_timer(0.72, false).timeout
	_invulnerable = false
	hurt_box.invulnerable = false
