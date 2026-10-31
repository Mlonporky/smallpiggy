extends Node
## One persistent score across chapter-one rooms; cinematic seeks use story time.
const OPENING := preload("res://assets/audio/music/opening_story.wav")
const OPENING_FAST := preload("res://assets/audio/music/opening_story_1_5x.wav")
const MORNING := preload("res://assets/audio/music/hollow_morning.wav")
signal mute_changed(value: bool)
var muted := false
var current_track := ""
var active: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var fades: Dictionary = {}
var last_scene := ""
var last_seek := 0.0
var opening_speed := 1.0
var opening_story_time := 0.0
const GAIN_DB := -6.0

func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 AppSettings.changed.connect(_settings_changed)
 _settings_changed()
 if AudioServer.get_bus_index("Music") < 0:
  AudioServer.add_bus()
  AudioServer.set_bus_name(AudioServer.bus_count-1,"Music")
 for i in 2:
  var player := AudioStreamPlayer.new()
  player.name = "Score%d" % i
  player.bus = "Music"
  add_child(player)
  voices.append(player)

func fade_voice(player: AudioStreamPlayer, gain: float, duration: float, stop_after := false) -> void:
 if fades.has(player) and fades[player].is_valid(): fades[player].kill()
 var tween := create_tween()
 fades[player] = tween
 tween.tween_property(player,"volume_db",gain,duration)
 if stop_after: tween.tween_callback(player.stop)

func play_track(track: String, at := 0.0) -> void:
 if track == current_track and is_instance_valid(active) and active.playing: return
 var incoming := voices[1] if active == voices[0] else voices[0]
 if is_instance_valid(active): fade_voice(active,-60,0.8,true)
 if fades.has(incoming) and fades[incoming].is_valid(): fades[incoming].kill()
 incoming.stop()
 incoming.stream_paused = false
 var source = (OPENING_FAST if opening_speed == 1.5 else OPENING) if track == "opening" else MORNING
 var stream := source.duplicate() as AudioStreamWAV
 if track == "morning":
  stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
  stream.loop_begin = 0
  stream.loop_end = int(round(stream.get_length()*stream.mix_rate))
 incoming.stream = stream
 incoming.volume_db = -60
 incoming.play(at)
 active = incoming
 current_track = track
 last_seek = at
 fade_voice(active,GAIN_DB,0.65)

func opening_at(seconds: float, force := false) -> void:
 opening_story_time = seconds
 var speed := AppSettings.story_speed
 var same := current_track == "opening"
 # Audio may finish a mixer block before the final visual frame. Do not restart
 # a nearly finished stream just because its playback position has reset to 0.
 if same and not force and seconds >= OPENING.get_length()-0.20: return
 var at := seconds / speed
 if same and opening_speed != speed:
  # Keep the same player so an open settings overlay can restore its pause state.
  var was_paused := active.stream_paused
  active.stop()
  active.stream = (OPENING_FAST if speed == 1.5 else OPENING).duplicate()
  active.play(at)
  active.stream_paused = was_paused
  last_seek = seconds
  opening_speed = speed
  return
 opening_speed = speed
 if not same:
  play_track("opening",at)
  last_seek = seconds
 elif force or absf(active.get_playback_position()-at)>0.25:
  if active.playing or active.stream_paused: active.seek(at)
  else: active.play(at)
  last_seek = seconds

func pause_opening(value: bool) -> void:
 if current_track == "opening" and is_instance_valid(active): active.stream_paused=value

func stop_music() -> void:
 if current_track.is_empty(): return
 for player in voices:
  player.stream_paused = false
  fade_voice(player,-60,0.6,true)
 current_track = ""

func set_muted(value: bool) -> void:
 AppSettings.set_muted(value)

func _settings_changed() -> void:
 muted = AppSettings.muted
 mute_changed.emit(muted)
 if current_track == "opening" and opening_speed != AppSettings.story_speed:
  opening_at(opening_story_time,true)

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
  if not current_track.is_empty():
   set_muted(not muted)
   get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
 var scene := get_tree().current_scene
 if not is_instance_valid(scene): return
 var path := scene.scene_file_path
 if path == last_scene: return
 last_scene = path
 if path.begins_with("res://scenes/chapter1/"):
  play_track("morning")
 elif path != "res://scenes/prologue/prologue.tscn":
  stop_music()

func _exit_tree() -> void:
 for tween in fades.values():
  if tween.is_valid(): tween.kill()
 fades.clear()
 for player in voices:
  player.stop()
  player.stream = null
