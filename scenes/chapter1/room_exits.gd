extends Node2D
## Wide approach zones activate on the floor before door/wall collisions.
var room: Node2D
var zones: Array
var latched := ""
var elapsed := 0.0

func _ready() -> void:
 name = "RoomExits"
 z_index = 25
 room = get_parent()
 zones = ChapterRoomLayout.DATA[room.room_id].exits
 for zone in zones:
  var hint := Label.new()
  hint.position = zone[2]-Vector2(85,25)
  hint.size = Vector2(170,40)
  hint.text = zone[3]
  hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  hint.add_theme_font_size_override("font_size",23)
  hint.add_theme_color_override("font_color",Color("e0ded4"))
  hint.add_theme_color_override("font_shadow_color",Color("242630"))
  hint.add_theme_constant_override("shadow_offset_y",2)
  add_child(hint)

func active_destination() -> String:
 for zone in zones:
  if zone[1].has_point(room.player.position): return zone[0]
 return ""

func _physics_process(_delta: float) -> void:
 if not latched.is_empty():
  for zone in zones:
   if zone[0] == latched and not zone[1].grow(24).has_point(room.player.position): latched = ""
 if not room.auto_exit_enabled or room.busy or room.routing or not room.player.input_enabled: return
 var target := active_destination()
 if not target.is_empty() and latched.is_empty():
  latched = target
  room.open_exit_menu(target)

func _unhandled_input(event: InputEvent) -> void:
 if room.player._nearest_interactable != null: return
 var target := active_destination()
 if room.auto_exit_enabled and not room.busy and not target.is_empty() and event.is_action_pressed("interact"):
  get_viewport().set_input_as_handled()
  latched = target
  room.open_exit_menu(target)

func _process(delta: float) -> void:
 elapsed += delta
 visible = not room.busy
 queue_redraw()

func _draw() -> void:
 for zone in zones:
  var rect: Rect2 = zone[1]
  var pulse := 0.9+0.1*sin(elapsed*1.4)
  draw_rect(rect,Color(0.83,0.87,0.88,0.07*pulse))
  draw_rect(rect,Color(0.83,0.87,0.88,0.22*pulse),false,2)
