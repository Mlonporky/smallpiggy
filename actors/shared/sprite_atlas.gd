class_name SpriteAtlas
extends RefCounted
## Bounds are computed once per sheet, never in the animation loop.
static var cache: Dictionary = {}

static func bounds(texture: Texture2D, columns: int, rows: int, row_edges: PackedInt32Array = [], alpha_threshold := 0.0) -> Array[Rect2]:
	var key := "%s:%s:%s:%s:%s" % [texture.resource_path, columns, rows, row_edges, alpha_threshold]
	if cache.has(key):
		return cache[key]
	var image := texture.get_image()
	var cell := Vector2i(image.get_width() / columns, image.get_height() / rows)
	assert(row_edges.is_empty() or row_edges.size() == rows + 1, "Atlas needs one boundary per row plus its bottom edge")
	var result: Array[Rect2] = []
	for y in rows:
		var top := y * cell.y if row_edges.is_empty() else row_edges[y]
		var bottom := (y+1) * cell.y if row_edges.is_empty() else row_edges[y+1]
		assert(top >= 0 and bottom > top and bottom <= image.get_height(), "Atlas row boundaries must be ordered within the source image")
		for x in columns:
			var origin := Vector2i(x * cell.x, top)
			var size := Vector2i(cell.x, bottom-top)
			var region := image.get_region(Rect2i(origin, size))
			var used := region.get_used_rect() if alpha_threshold <= 0 else _visible_bounds(region, alpha_threshold)
			if used.size == Vector2i.ZERO:
				used = Rect2i(Vector2i.ZERO, size)
			result.append(Rect2(origin + used.position, used.size))
	cache[key] = result
	return result

static func _visible_bounds(image: Image, threshold: float) -> Rect2i:
	# Ignore near-invisible export speckles when aligning feet and visible height.
	var low := image.get_size()
	var high := Vector2i(-1,-1)
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x,y).a > threshold:
				low = low.min(Vector2i(x,y))
				high = high.max(Vector2i(x,y))
	if high.x < 0:
		return Rect2i()
	# Preserve two pixels of antialiasing around the meaningful silhouette.
	return Rect2i(low, high-low+Vector2i.ONE).grow(2).intersection(Rect2i(Vector2i.ZERO,image.get_size()))

static func frame(texture: Texture2D, rect: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = rect
	return atlas
