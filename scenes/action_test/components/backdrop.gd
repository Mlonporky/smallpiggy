extends Node2D
## Far painted layer with true parallax: it moves on screen at `factor` of the playfield speed,
## in the same direction. Sized once so a single, unrepeated painting covers every camera position
## (no seams). Its position is set on physics ticks, so physics interpolation keeps it in step with
## the interpolated camera instead of jittering against it.
const SHADER := preload("res://scenes/action_test/components/backdrop_soften.gdshader")
var texture: Texture2D
var factor := Vector2(0.18, 0.08)
var size := Vector2.ZERO
var anchor := Vector2.ZERO


func setup(image: Texture2D, bounds: Rect2, view: Vector2) -> void:
	texture = _softened(image)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var shader := ShaderMaterial.new()
	shader.shader = SHADER
	material = shader
	z_index = -50
	var half := view * 0.5
	var travel := Vector2(maxf(0, bounds.size.x - view.x), maxf(0, bounds.size.y - view.y))
	anchor = bounds.position + half + travel * 0.5
	var needed := view + travel * factor + Vector2(24, 24)
	var fit := maxf(needed.x / image.get_width(), needed.y / image.get_height())
	size = Vector2(image.get_width(), image.get_height()) * fit
	queue_redraw()


func _softened(image: Texture2D) -> Texture2D:
	# The grotto painting was generated as chunky pixel art. Downsampling it once (Lanczos, 1/4)
	# collapses each block to ~2 texels; bilinear upscaling then reads as a soft, distant painting.
	# Done once on load: a per-pixel blur over the full Retina screen every frame was too costly.
	var source := image.get_image()
	if source == null:
		return image
	source = source.duplicate()
	if source.is_compressed():
		source.decompress()
	var width := maxi(1, source.get_width() / 4)
	var height := maxi(1, source.get_height() / 4)
	source.resize(width, height, Image.INTERPOLATE_LANCZOS)
	# One cheap blur pass at load (down to half, back up), so the shader only needs a single sample.
	source.resize(maxi(1, width / 2), maxi(1, height / 2), Image.INTERPOLATE_BILINEAR)
	source.resize(width, height, Image.INTERPOLATE_CUBIC)
	return ImageTexture.create_from_image(source)


func follow(camera_center: Vector2) -> void:
	position = camera_center - (camera_center - anchor) * factor


func _draw() -> void:
	if texture:
		draw_texture_rect(texture, Rect2(-size * 0.5, size), false)
