extends PiggyPlayer
## Act II uses the fine-shaded cape/armed sheets; the opening has a matching plate.
# wake reuses the source sheet's smaller expression row: its standing head is
# 175 px wide against 195 px for cape_down_00, so its lying/sitting poses need 0.53 × 1.11.
const SHEET_SCALE := {"cape": 0.53, "armed": 0.53, "wake": 0.59}
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

func _update_visual(delta: float) -> void:
	_animation_clock += delta
	walk_phase = fposmod(walk_phase + _travelled / 110.0, 1.0)
	var row := 0
	if _facing == Vector2.LEFT: row = 1
	elif _facing == Vector2.UP: row = 2
	elif _facing == Vector2.RIGHT: row = 3
	var count := 3 if armed else 4
	var frame_index := int(walk_phase * count) % count if _travelled > 0.05 else 0
	_show_frame(row * count + frame_index)

func _show_frame(index: int) -> void:
	if not is_instance_valid(sprite) or atlas_data.is_empty(): return
	var key := "wake" if waking else ("armed" if armed else "cape")
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
	if _attacking or not combat_enabled: return
	# TODO: Missing asset — no authored attack sheet; move the supplied armed pose.
	super.attack()
	var sign_x := -1.0 if _facing == Vector2.LEFT else 1.0
	var swing := create_tween()
	swing.tween_property(visual_root,"rotation",-0.14*sign_x,0.12)
	swing.tween_property(visual_root,"rotation",0.25*sign_x,0.10)
	swing.tween_property(visual_root,"rotation",0.0,0.18)
