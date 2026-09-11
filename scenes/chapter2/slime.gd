extends ForestSlime
var art: Sprite2D
var frames: Array
var phase := 0.0
func _ready() -> void:
	super._ready()
	frames = JSON.parse_string(FileAccess.get_file_as_string("res://assets/chapter2/atlas.json"))["slime"]
	art = Sprite2D.new()
	art.texture = preload("res://assets/chapter2/slime.png")
	art.region_enabled = true
	art.centered = false
	art.scale = Vector2.ONE * 0.47
	add_child(art)
	$HurtBox/CollisionShape2D.position.y = -45
func _process(delta: float) -> void:
	phase += delta
	var r: Array = frames[int(phase * 5.0) % 3]
	art.region_rect = Rect2(r[0], r[1], r[2], r[3])
	art.position = Vector2(-float(r[2])*0.235, -float(r[3])*0.47)
func _draw() -> void:
	pass
