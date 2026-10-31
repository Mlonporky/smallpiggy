extends "res://scenes/finale/final_chapter.gd"
func _ready() -> void:
 preview=true
 auto_advance=true
 super._ready()
 enter_beat(Story.index_of("manor_restore"))
func _process(delta: float) -> void:
 if finished:
  _layout()
  return
 _layout()
 if paused: return
 delta *= playback_speed()
 elapsed+=delta
 beat_time=minf(18.0,beat_time+delta)
 _animate(delta)
 fx.queue_redraw()
 if beat_time>=18.0:
  finished=true
  audio.pause(true)
  hint.text="空格 / E · 重看山庄恢复    Esc · 菜单    M · 静音"
  return
func _unhandled_key_input(event: InputEvent) -> void:
 if finished and not paused and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE,KEY_E,KEY_ENTER]:
  finished=false
  audio.pause(false)
  enter_beat(Story.index_of("manor_restore"))
  get_viewport().set_input_as_handled()
  return
 super._unhandled_key_input(event)
