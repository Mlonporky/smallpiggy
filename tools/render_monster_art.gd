extends SceneTree
## Rasterises the monster vector sources (tools/monster_art/svg, made by make_svgs.py) into
## assets/chapter2/monsters/*.png, one SVG pixel per texture pixel.
## Run from the project root:
##   Godot --headless --path . --script tools/render_monster_art.gd [-- --preview=/path/sheet.png]
## Optional --preview writes a contact sheet of every part on a dark backdrop.
const SOURCE := "res://tools/monster_art/svg"
const TARGET := "res://assets/chapter2/monsters"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TARGET))
	var names: Array[String] = []
	for file in DirAccess.get_files_at(SOURCE):
		if file.ends_with(".svg"):
			names.append(file.get_basename())
	names.sort()
	var images: Array[Image] = []
	for name in names:
		var image := Image.new()
		var error := image.load_svg_from_string(FileAccess.get_file_as_string(SOURCE + "/" + name + ".svg"), 1.0)
		if error != OK:
			push_error("SVG failed: %s (%d)" % [name, error])
			quit(1)
			return
		image.save_png(TARGET + "/" + name + ".png")
		images.append(image)
		print("  %s %s" % [name, image.get_size()])
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--preview="):
			_sheet(images).save_png(arg.trim_prefix("--preview="))
	print("MONSTER_ART_OK %d parts" % names.size())
	quit()


func _sheet(images: Array[Image]) -> Image:
	var sheet := Image.create(1100, 460, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("1c2a22"))
	var at := Vector2i(16, 16)
	var row := 0
	for image in images:
		if at.x + image.get_width() > sheet.get_width():
			at = Vector2i(16, at.y + row + 16)
			row = 0
		sheet.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), at)
		at.x += image.get_width() + 16
		row = maxi(row, image.get_height())
	return sheet
