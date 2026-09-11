extends SceneTree
func _initialize(): call_deferred("run")
func label_at(text, pos, size=18):
	var l=Label.new(); l.text=text; l.position=pos; l.add_theme_font_size_override("font_size",size); root.add_child(l)
func run():
	await process_frame
	root.size=Vector2i(1152,650)
	var bg=ColorRect.new(); bg.size=Vector2(1152,650); bg.color=Color("343943"); root.add_child(bg)
	var names=["披风小猪","持棍小猪","白菜 · 男孩","白菜形态","巫师","史莱姆"]
	var paths=["res://assets/chapter2/pig_pixel/cape.png","res://assets/chapter2/pig_pixel/armed.png","res://assets/chapter1/boy.png","res://assets/sprites/characters/cabbage_creature.png","res://assets/chapter2/wizard.png","res://assets/chapter2/slime.png"]
	label_at("上：修改前    下：小猪细化 + 全角色统一采样    ｜ 同尺寸对照",Vector2(20,15),19)
	for i in 6:
		label_at(names[i],Vector2(25+i*190,62))
		var tex=load(paths[i])
		var im: Image=tex.get_image()
		var region: Rect2i
		if i<2: region=Rect2i(0,0,320,320)
		elif i==2: region=Rect2i(0,0,im.get_width()/3,368)
		else: region=Rect2i(0,0,im.get_width()/3,im.get_height()/4)
		var crop=im.get_region(region)
		crop=crop.get_region(SpriteAtlas._visible_bounds(crop,0.1))
		for row in 2:
			var spr=Sprite2D.new(); spr.centered=false
			var c=crop.duplicate()
			if row==1 and i<2:
				var refined=load(paths[i].replace("pig_pixel/","pig_unified/")).get_image().get_region(region)
				c=refined.get_region(SpriteAtlas._visible_bounds(refined,0.1))
			if row==1 or i>=4: c.generate_mipmaps()
			spr.texture=ImageTexture.create_from_image(c)
			spr.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS if row==1 or i>=4 else (CanvasItem.TEXTURE_FILTER_NEAREST if i<2 else CanvasItem.TEXTURE_FILTER_LINEAR)
			spr.scale=Vector2.ONE*160.0/c.get_height()
			spr.position=Vector2(95+i*190-c.get_width()*spr.scale.x/2,110+row*270)
			root.add_child(spr)
	label_at("修改前：小猪粗像素 + Nearest",Vector2(20,290),16)
	label_at("修改后：细轮廓小猪 + 所有角色 Linear with mipmaps",Vector2(20,570),16)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/art_direction/character_style_review/comparison.png")
	quit()
