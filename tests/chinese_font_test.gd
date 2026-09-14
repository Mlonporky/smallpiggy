extends SceneTree
## Checks bundled glyph coverage and actual scene font inheritance; optionally renders previews.
const FONT = preload("res://assets/fonts/game_font.tres")
var checked := {}
var labels := 0

func _initialize() -> void:
	call_deferred("run")

func check_text(text: String) -> void:
	for character in text:
		var code := character.unicode_at(0)
		if code >= 0x3000 and code <= 0x9fff:
			assert(FONT.base_font.has_char(code), "Bundled font missing: " + character)
			checked[code] = true

func scan(path: String) -> void:
	for file in DirAccess.get_files_at(path):
		if file.get_extension() in ["gd", "tscn", "json"]:
			check_text(FileAccess.get_file_as_string(path.path_join(file)))
	for directory in DirAccess.get_directories_at(path):
		scan(path.path_join(directory))

func check_labels(node: Node) -> void:
	if node is Label or node is Button:
		assert(node.get_theme_font("font") == FONT, "UI did not inherit bundled font: " + str(node.get_path()))
		check_text(node.text)
		labels += 1
	for child in node.get_children(): check_labels(child)

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/piggy-font-" + name + ".png")

func run() -> void:
	await process_frame
	root.size = Vector2i(1152,648)
	# Prove coverage without relying on the host's CJK fonts.
	var font_file: FontFile = FONT.base_font
	font_file.allow_system_fallback = false
	for path in ["res://scenes", "res://systems", "res://ui", "res://data"]:
		if DirAccess.dir_exists_absolute(path): scan(path)
	var menu = load("res://scenes/bootstrap/main.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	check_labels(menu)
	await capture("menu")
	menu.queue_free()
	await process_frame
	root.get_node("GameState").reset()
	var cave = load("res://scenes/chapter2/cave.tscn").instantiate()
	cave.allow_save = false
	root.add_child(cave)
	cave.lock(true) # Preview input must not pause the scripted capture.
	await process_frame
	check_labels(cave)
	await capture("cave")
	cave.dialogue.say("小呆猪", "白菜……我还要把礼物带回你身边。")
	await create_timer(1.6).timeout
	check_labels(cave.dialogue)
	await capture("dialogue")
	cave.dialogue._advance_requested = true
	await process_frame
	assert(checked.size() > 100 and labels > 10)
	print("CHINESE_FONT_OK: ", checked.size(), " characters, ", labels, " UI font checks; no system fallback")
	quit()
