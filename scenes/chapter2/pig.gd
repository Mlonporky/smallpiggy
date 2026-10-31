extends PiggyPlayer
## Act II keeps one cape sheet across movement, attacks and evasions.
# wake reuses the source sheet's smaller expression row: its standing head is
# 175 px wide against 195 px for cape_down_00, so its lying/sitting poses need 0.53 × 1.11.
const SHEET_SCALE := {"cape": 0.53, "armed": 0.53, "wake": 0.59}
const CAPE_TEXTURE = preload("res://assets/chapter2/pig_unified/cape.png")
const WAKE_TEXTURE = preload("res://assets/chapter2/pig_unified/wake.png")
const FX = preload("res://scenes/chapter2/combat_fx.gd")
var roll_time := 0.0
var roll_cooldown := 0.0
var roll_direction := Vector2.DOWN
var parry_time := 0.0
var parry_cooldown := 0.0
var parry_direction := Vector2.DOWN
var parry_flash := 0.0
var jump_time := 0.0
var jump_cooldown := 0.0
var jump_height := 0.0
signal joy_released(at: Vector2)
const ATTACK_DURATION := 0.34
const ATTACK_CONTACT := 0.09
const ATTACK_RECOVERY := 0.21
const INPUT_BUFFER := 0.18
const DODGE_DURATION := 0.32
const JOY_DURATION := 4.0
const JOY_COOLDOWN := 8.0
const JOY_RADIUS := 210.0
var joy_power := false
var joy_time := 0.0
var joy_cooldown := 0.0
var attack_buffer := 0.0
var dodge_buffer := 0.0
var attack_connected := false
var attack_serial := 0
var visual_lean := 0.0
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
	swing_stick.offset = Vector2(-350,-990)
	swing_stick.scale = Vector2.ONE * 0.055
	swing_stick.visible = false
	visual_root.add_child(swing_stick)

func _wants_interaction() -> bool:
	return Input.is_action_just_pressed("interact") and not Input.is_action_just_pressed("jump")

func _movement_allowed() -> bool:
	return true

func _turning_allowed() -> bool:
	return not _attacking

func _movement_multiplier() -> float:
	return 0.72 if _attacking else 1.0

func _physics_process(delta: float) -> void:
	roll_cooldown = maxf(0, roll_cooldown - delta)
	parry_cooldown = maxf(0, parry_cooldown - delta)
	parry_flash = maxf(0, parry_flash - delta)
	jump_cooldown = maxf(0, jump_cooldown - delta)
	hurt_time = maxf(0, hurt_time - delta)
	joy_time = maxf(0, joy_time - delta)
	joy_cooldown = maxf(0, joy_cooldown - delta)
	joy_power = joy_time > 0
	attack_buffer = maxf(0, attack_buffer - delta)
	dodge_buffer = maxf(0, dodge_buffer - delta)
	if not input_enabled or health.current_health <= 0:
		attack_buffer = 0
		dodge_buffer = 0
	if input_enabled:
		if Input.is_action_just_pressed("joy_skill"): release_joy()
		if Input.is_action_just_pressed("roll"): dodge_buffer = INPUT_BUFFER
		if Input.is_action_just_pressed("attack"): attack_buffer = INPUT_BUFFER
		if Input.is_action_just_pressed("parry"): parry()
		if Input.is_action_just_pressed("jump"): jump()
	if _attacking:
		attack_time += delta
		if not combat_enabled or health.current_health <= 0:
			_cancel_attack()
		elif attack_time >= ATTACK_DURATION:
			_cancel_attack()
		elif attack_time >= ATTACK_RECOVERY:
			hit_box.monitoring = false
		elif attack_time >= ATTACK_CONTACT:
			if not attack_connected:
				attack_connected = true
				hit_box.damage = 2 if joy_power else 1
				hit_box.position = attack_direction * 65 + Vector2(0,-32)
				hit_box.monitoring = true
				FX.spawn(get_parent(), position + Vector2(0,-35), "slash", attack_direction, Color("ffd67c") if joy_power else Color("e5e1d7"), 90)
				FX.sound(self, "swing")
			# Includes enemies already overlapping when the active window began.
			for area in hit_box.get_overlapping_areas():
				if area is HurtBox2D: area.receive_hit(hit_box)
	if dodge_buffer > 0: roll()
	if attack_buffer > 0: _try_attack()
	if joy_power:
		aura_time -= delta
		if aura_time <= 0:
			aura_time = 0.35
			FX.spawn(get_parent(), position + Vector2(0,-45-jump_height), "aura", Vector2.RIGHT, Color(1,0.78,0.4,0.6), 38)
	if roll_time > 0:
		roll_time = maxf(0, roll_time - delta)
		var progress := 1.0 - roll_time / DODGE_DURATION
		velocity = roll_direction * (160.0 + 280.0 * sin(PI * progress))
		var before := global_position
		move_and_slide()
		_travelled = global_position.distance_to(before)
		_update_visual(delta)
		return
	if parry_time > 0:
		parry_time = maxf(0, parry_time - delta)
		velocity = Vector2.ZERO
		_travelled = 0
		_update_visual(delta)
		return
	if jump_time > 0:
		jump_time = maxf(0, jump_time - delta)
		jump_height = sin((1.0 - jump_time / 0.65) * PI) * 65.0
		if jump_time == 0:
			jump_height = 0
			FX.spawn(get_parent(), position, "land", Vector2.RIGHT, Color("d4c3ae"), 35)
			FX.sound(self, "land")
	super._physics_process(delta)

func roll() -> void:
	if not input_enabled or not combat_enabled or waking or jump_time > 0 or parry_time > 0 or roll_cooldown > 0: return
	if _attacking and attack_time < ATTACK_RECOVERY: return
	_cancel_attack()
	attack_buffer = 0
	dodge_buffer = 0
	roll_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if roll_direction == Vector2.ZERO: roll_direction = _facing
	face(roll_direction)
	roll_time = DODGE_DURATION
	roll_cooldown = 0.65
	FX.sound(self, "roll")
	FX.spawn(get_parent(), position, "land", roll_direction, Color("d4c3ae"), 40)

func parry() -> void:
	if not input_enabled or not combat_enabled or not armed or waking or jump_time > 0 or roll_time > 0 or parry_cooldown > 0: return
	if _attacking and attack_time < ATTACK_RECOVERY: return
	_cancel_attack()
	attack_buffer = 0
	parry_direction = _facing
	parry_time = 0.5
	parry_cooldown = 0.95

func jump() -> void:
	if not input_enabled or waking or jump_cooldown > 0 or roll_time > 0 or parry_time > 0: return
	if _attacking and attack_time < ATTACK_RECOVERY: return
	_cancel_attack()
	jump_time = 0.65
	jump_cooldown = 0.95
	FX.sound(self, "jump")

func release_joy() -> bool:
	if not input_enabled or not armed or waking or health.current_health <= 0 or joy_cooldown > 0: return false
	joy_time = JOY_DURATION
	joy_cooldown = JOY_COOLDOWN
	joy_power = true
	aura_time = 0
	FX.spawn(get_parent(), position + Vector2(0,-35), "joy", Vector2.RIGHT, Color("ffdc87"), JOY_RADIUS)
	FX.sound(self, "joy")
	joy_released.emit(global_position)
	return true

func _update_visual(delta: float) -> void:
	_animation_clock += delta
	walk_phase = fposmod(walk_phase + _travelled / 110.0, 1.0)
	var row := 0
	if _facing == Vector2.LEFT: row = 1
	elif _facing == Vector2.UP: row = 2
	elif _facing == Vector2.RIGHT: row = 3
	var frame_index := int(walk_phase * 4) % 4 if _travelled > 0.05 else 0
	_show_frame(row * 4 + frame_index)
	# Same cape sheet in idle, travel, attack and evade: no shape/size swap.
	# This is a procedural weapon prototype, not a newly drawn arm animation.
	visual_root.position = Vector2(0, -jump_height)
	visual_root.scale = Vector2.ONE
	var lean := 0.0
	if _attacking:
		lean = sin(PI * attack_time / ATTACK_DURATION) * 0.07 * (-1 if attack_direction.x < 0 else 1)
	elif roll_time > 0:
		lean = sin(PI * (1.0 - roll_time / DODGE_DURATION)) * 0.12 * (-1 if roll_direction.x < 0 else 1)
	elif parry_time > 0:
		lean = -0.08 if parry_direction.x < 0 else 0.08
	visual_lean = lerpf(visual_lean, lean, 1.0-exp(-25.0*delta))
	visual_root.rotation = visual_lean
	if is_instance_valid(swing_stick):
		swing_stick.visible = armed and not waking
		# Image-space visible hand anchors; these do not assign anatomical sides.
		var hands := [
			[Vector2(218,250),Vector2(217,248),Vector2(210,247),Vector2(208,245)],
			[Vector2(90,247),Vector2(90,250),Vector2(89,251),Vector2(90,249)],
			[Vector2(218,251),Vector2(217,249),Vector2(217,250),Vector2(215,248)],
			[Vector2(220,260),Vector2(219,262),Vector2(220,260),Vector2(220,262)]
		]
		swing_stick.position = (hands[row][frame_index] - Vector2(160,300)) * SHEET_SCALE.cape
		var facing := attack_direction if _attacking else _facing
		var rest_angle: float = [0.0,-1.45,-0.15,0.05][row]
		var desired_angle := rest_angle
		if _attacking:
			var t := attack_time
			var sweep := 0.0
			if t < ATTACK_CONTACT:
				sweep = lerpf(0,-0.6,smoothstep(0,ATTACK_CONTACT,t))
			elif t < ATTACK_RECOVERY:
				sweep = lerpf(-0.6,1.35,smoothstep(ATTACK_CONTACT,ATTACK_RECOVERY,t))
			else:
				sweep = lerpf(1.35,0,smoothstep(ATTACK_RECOVERY,ATTACK_DURATION,t))
			desired_angle += sweep * (-1.0 if facing == Vector2.LEFT or facing == Vector2.UP else 1.0)
		elif parry_time > 0: desired_angle = parry_direction.angle() + 0.3
		swing_stick.rotation = lerp_angle(swing_stick.rotation,desired_angle,1.0-exp(-40.0*delta))
		swing_stick.z_index = -1 if facing == Vector2.UP else 1
		swing_stick.modulate = Color("ffe3a1") if parry_flash > 0 or joy_power else Color.WHITE
	if is_instance_valid(shadow):
		shadow.scale = Vector2.ONE * (1.0 - jump_height / 150.0)
		shadow.color.a = 0.27 - jump_height / 500.0

func _show_frame(index: int) -> void:
	if not is_instance_valid(sprite) or atlas_data.is_empty(): return
	var key := "wake" if waking else "cape"
	var r: Array = atlas_data[key][wake_frame if waking else index]
	sprite.texture = WAKE_TEXTURE if waking else CAPE_TEXTURE
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
		await get_tree().create_timer(0.48, false).timeout
	# The authored standing pose (wake 5) has a narrower cape and arms than the
	# walking sheet and still reads smaller; stand up on cape_down_00 instead.
	waking = false
	face(Vector2.DOWN)
	await get_tree().create_timer(0.48, false).timeout

func attack() -> void:
	if not input_enabled or not combat_enabled or not armed or waking or health.current_health <= 0: return
	attack_buffer = INPUT_BUFFER
	_try_attack()

func _try_attack() -> void:
	if not input_enabled or not combat_enabled or not armed or waking or health.current_health <= 0: return
	if _attacking or jump_time > 0 or roll_time > 0 or parry_time > 0: return
	attack_buffer = 0
	_attacking = true
	attack_time = 0
	attack_connected = false
	attack_serial += 1
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO: face(direction)
	attack_direction = _facing
	attack_started.emit()

func _cancel_attack() -> void:
	_attacking = false
	hit_box.set_deferred("monitoring",false)

func _on_damaged(source: HitBox2D) -> void:
	if _invulnerable or story_protected or jump_height > 20 or (roll_time > 0.08 and roll_time < 0.28) or health.current_health <= 0: return
	var incoming := source.damage
	var toward_source := global_position.direction_to(source.global_position)
	if parry_time >= 0.20 and parry_direction.dot(toward_source) >= 0.35:
		incoming = maxi(1, ceili(incoming * 0.25))
		parry_flash = 0.25
		FX.spawn(get_parent(), position + Vector2(0,-50), "impact", parry_direction, Color("ffe3a1"), 85)
	_invulnerable = true
	hurt_box.invulnerable = true
	hurt_time = 0.45
	FX.spawn(get_parent(), position + Vector2(0,-40), "impact", Vector2.RIGHT, Color("ffa4ac"), 60)
	FX.sound(self, "impact")
	sprite.modulate = Color("ffb2bb")
	# Collision-aware recoil, never teleport through cave walls.
	move_and_collide((global_position - source.global_position).normalized() * 18)
	health.damage(incoming)
	await get_tree().create_timer(0.18, false).timeout
	sprite.modulate = Color.WHITE
	await get_tree().create_timer(0.72, false).timeout
	_invulnerable = false
	hurt_box.invulnerable = false
