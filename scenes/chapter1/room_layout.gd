class_name ChapterRoomLayout
extends RefCounted
## All geometry uses the supplied 1448 × 1086 background coordinates.
const SIZE := Vector2(1448, 1086)
static var pending_entry: Dictionary = {}
static var DATA := {
 "bedroom": {
  "title":"卧室", "spawn":Vector2(610,570), "door":Vector2(1135,610),
  "blocks":[Rect2(0,0,1448,350),Rect2(0,350,220,736),Rect2(1180,350,268,736),Rect2(220,350,245,370),Rect2(465,350,110,65),Rect2(680,350,435,90),Rect2(490,825,425,261),Rect2(220,930,960,156)],
  "hotspots":[["painting","床头的画",Vector2(590,465)]],
  "occluders":[[720,PackedVector2Array([Vector2(235,630),Vector2(470,630),Vector2(470,728),Vector2(235,728)])]],
  "exits":[["kitchen",Rect2(1080,470,110,280),Vector2(1095,580),"厨房 →"]]
 },
 "kitchen": {
  "title":"厨房", "spawn":Vector2(285,560), "door":Vector2(1290,600),
  "blocks":[Rect2(0,0,1448,480),Rect2(0,480,150,606),Rect2(1300,480,148,606),Rect2(535,590,380,320),Rect2(410,620,125,250),Rect2(915,620,125,250),Rect2(0,980,1448,106)],
  "hotspots":[["coffee","咖啡机",Vector2(1120,525)],["cup","猪猪杯",Vector2(1010,525)],["tableware","双人餐具",Vector2(725,940)],["trash","垃圾桶",Vector2(1200,550)]],
  "occluders":[[900,PackedVector2Array([Vector2(532,760),Vector2(915,760),Vector2(915,916),Vector2(532,916)])]],
  "exits":[["bedroom",Rect2(150,520,85,230),Vector2(185,570),"← 卧室"],["living",Rect2(1215,520,85,230),Vector2(1220,570),"客厅 →"]]
 },
 "living": {
  "title":"客厅", "spawn":Vector2(350,620), "door":Vector2(710,945),
  "blocks":[Rect2(0,0,1448,350),Rect2(0,350,205,736),Rect2(1280,350,168,736),Rect2(205,350,135,175),Rect2(465,350,480,220),Rect2(535,630,330,190),Rect2(950,500,250,280),Rect2(920,800,170,135),Rect2(205,710,175,220),Rect2(0,980,1448,106)],
  "hotspots":[["pillow","猪猪抱枕",Vector2(410,570)],["blanket","粉色毯子",Vector2(980,415)],["basket","收纳篮",Vector2(1225,875)],["window","窗边",Vector2(1000,385)]],
  "occluders":[[815,PackedVector2Array([Vector2(535,710),Vector2(865,710),Vector2(865,825),Vector2(535,825)])]],
  "exits":[["kitchen",Rect2(205,535,75,160),Vector2(260,580),"← 厨房"],["outside",Rect2(400,915,510,65),Vector2(705,950),"↓ 出门"]]
 }
}

static func build(room: Node2D, id: String) -> void:
	var data: Dictionary = DATA[id]
	var texture := load("res://assets/chapter1/%s_v2.png" % id) as Texture2D
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
