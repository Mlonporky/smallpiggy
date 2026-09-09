class_name ChapterRoomLayout
extends RefCounted
## All geometry uses the supplied 1448 × 1086 background coordinates.
const SIZE := Vector2(1448, 1086)
static var DATA := {
 "bedroom": {
  "title": "卧室", "spawn": Vector2(710, 865), "door": Vector2(715, 960),
  "blocks": [Rect2(0,0,1448,350), Rect2(0,350,170,520), Rect2(1240,350,208,520), Rect2(170,350,300,355), Rect2(460,350,115,80), Rect2(745,350,500,110), Rect2(1030,500,235,330), Rect2(170,705,255,140)],
  "hotspots": [["painting","床头的画",Vector2(575,480)], ["door","房门",Vector2(715,960)]],
  "occluders": [[710, PackedVector2Array([Vector2(174,638),Vector2(468,638),Vector2(468,724),Vector2(174,724)])]]
 },
 "kitchen": {
  "title": "厨房", "spawn": Vector2(710,880), "door": Vector2(710,985),
  "blocks": [Rect2(0,0,1448,415),Rect2(0,415,215,510),Rect2(1220,415,228,510),Rect2(430,550,115,230),Rect2(540,515,345,280),Rect2(885,550,95,230)],
  "hotspots": [["coffee","咖啡机",Vector2(1110,445)],["cup","猪猪杯",Vector2(985,445)],["tableware","双人餐具",Vector2(710,825)],["door","房门",Vector2(710,985)]],
  "occluders": [[795,PackedVector2Array([Vector2(548,523),Vector2(875,523),Vector2(880,730),Vector2(863,809),Vector2(576,810),Vector2(543,731)])]]
 },
 "living": {
  "title":"客厅", "spawn":Vector2(655,865), "door":Vector2(655,980),
  "blocks":[Rect2(0,0,1448,300),Rect2(0,300,240,610),Rect2(1230,300,218,610),Rect2(420,300,520,230),Rect2(515,570,305,185),Rect2(900,485,210,235),Rect2(842,720,125,110),Rect2(240,600,105,160)],
  "hotspots":[["pillow","猪猪抱枕",Vector2(395,535)],["blanket","粉色毯子",Vector2(970,380)],["basket","收纳篮",Vector2(1200,805)],["window","窗边",Vector2(980,330)],["door","房门",Vector2(655,980)]],
  "occluders":[[755,PackedVector2Array([Vector2(527,572),Vector2(811,572),Vector2(816,700),Vector2(802,756),Vector2(530,756),Vector2(516,700)])]]
 }
}

static func build(room: Node2D, id: String) -> void:
	var data: Dictionary = DATA[id]
	var texture := load("res://assets/chapter1/%s_bg.png" % id) as Texture2D
	var background := Sprite2D.new()
	background.name = "Background"
	background.texture = texture
	background.centered = false
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	background.z_index = -10
	room.add_child(background)
	var world := Node2D.new()
	world.name = "Depth"
	world.y_sort_enabled = true
	room.add_child(world)
	for box in data.blocks:
		block(room, box)
	# Solid perimeter with an inset doorway; navigation is an explicit interaction.
	var door: Vector2 = data.door
	var sill := 840.0 if id == "bedroom" else 900.0
	block(room, Rect2(0, sill, door.x-95, 1086-sill))
	block(room, Rect2(door.x+95, sill, SIZE.x-door.x-95, 1086-sill))
	block(room, Rect2(0, 1050, SIZE.x, 36))
	for item in data.occluders:
		# Exact background pixels avoid misregistered supplied FG duplicates.
		var patch := Polygon2D.new()
		patch.name = "FurnitureOcclusion"
		patch.position.y = item[0]
		var local_points := PackedVector2Array()
		for point in item[1]:
			local_points.append(point - patch.position)
		patch.polygon = local_points
		patch.uv = item[1]
		patch.texture = texture
		patch.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		world.add_child(patch)

static func block(room: Node2D, rectangle: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rectangle.get_center()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rectangle.size
	collision.shape = shape
	body.add_child(collision)
	room.add_child(body)
