extends SceneTree
func _initialize(): call_deferred("run")
func run():
	await process_frame
	for path in ["chapter1/boy", "sprites/characters/cabbage_creature", "sprites/characters/white_cabbage", "chapter2/wizard", "chapter2/slime", "chapter2/pig_unified/cape", "chapter2/pig_unified/armed", "chapter2/pig_unified/wake"]:
		var texture: Texture2D = load("res://assets/%s.png" % path)
		assert(texture.get_image().has_mipmaps(), "Missing mipmap on " + path)
	root.get_node("GameState").reset()
	root.get_node("GameState").set_flag("s2_pig_wakeup_complete")
	var entrance=load("res://scenes/chapter_02_dark_forest/forest_clearing.tscn").instantiate()
	entrance.allow_save=false
	root.add_child(entrance)
	await process_frame
	assert(entrance.player.sprite.texture_filter == CharacterSpriteStyle.FILTER)
	assert(entrance.wizard.texture_filter == CharacterSpriteStyle.FILTER)
	entrance.queue_free()
	await process_frame
	var room=load("res://scenes/chapter1/living.tscn").instantiate()
	root.add_child(room)
	await process_frame
	assert(room.player.sprite.texture_filter == CharacterSpriteStyle.FILTER)
	room.queue_free()
	await process_frame
	var cave=load("res://scenes/chapter2/cave.tscn").instantiate()
	cave.allow_save=false
	root.add_child(cave)
	await process_frame
	assert(cave.slime.art.texture_filter == CharacterSpriteStyle.FILTER)
	cave.queue_free()
	await process_frame
	print("CHARACTER_STYLE_OK: boy, cabbage, pig, wizard, slime mipmaps and shared filtering")
	quit()
