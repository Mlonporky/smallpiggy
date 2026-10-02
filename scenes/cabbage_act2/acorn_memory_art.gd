extends RefCounted
## Explicit alpha-content bounds inspected from generated originals, not a blind grid.
const PIG := preload("res://assets/cabbage_act2/acorn_memory/pig_actions_v1.png")
const CABBAGE := preload("res://assets/cabbage_act2/acorn_memory/cabbage_walk_v1.png")
const ACORN := preload("res://assets/cabbage_act2/acorn_memory/acorn_v1.png")
const PICKUP := preload("res://assets/cabbage_act2/acorn_memory/pig_pickup_empty_v1.png")
const PICKUP_REGION := Rect2(76,299,1087,750)
const PICKUP_FEET := Vector2(520,1048)
const PIG_REGIONS := [Rect2(23,49,396,359),Rect2(484,51,372,354),Rect2(906,48,395,360),Rect2(1368,51,373,353),Rect2(30,533,408,302),Rect2(522,464,319,374),Rect2(960,460,321,380),Rect2(1391,461,322,379)]
const CABBAGE_REGIONS := [Rect2(56,123,439,479),Rect2(593,122,437,481),Rect2(1116,130,445,474),Rect2(1682,133,436,471)]
const ACORN_REGION := Rect2(308,75,700,1064)
const PIG_FEET := [Vector2(244,407),Vector2(691,404),Vector2(1111,407),Vector2(1568,403),Vector2(190,834),Vector2(685,837),Vector2(1135,839),Vector2(1584,839)]
const CABBAGE_FEET := [Vector2(290,601),Vector2(828,602),Vector2(1344,603),Vector2(1909,603)]

static func atlas(texture: Texture2D, rect: Rect2) -> AtlasTexture:
 var result := AtlasTexture.new()
 result.atlas = texture
 result.region = rect
 result.filter_clip = true
 return result

static func acorn() -> AtlasTexture:
 return atlas(ACORN,ACORN_REGION)
