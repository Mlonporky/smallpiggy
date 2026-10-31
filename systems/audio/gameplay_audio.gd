extends Node
## Scene-owned PCM playback. Synthetic foley, no runtime waveform generation.
signal sound_played(kind: String)
const ROOT := "res://assets/audio/gameplay_v1/"
const KEYS := ["step_1","step_2","step_3","land","hit","swing","wood_pickup","paper","gift","equip","crack","bounce","chime","heal","purify","complete","alert","roll","puff","swoop","drop","clang","jump"]
const PROFILES := {
 "forest":[["forest_air",-20.0],["forest_leaves",-23.0]],
 "dark":[["forest_air",-22.0],["forest_leaves",-27.0]],
 "cave":[["cave_air",-20.0]],
 "platform":[["cave_air",-24.0]]}
var profile := ""
var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var ambience: Array[AudioStreamPlayer] = []
var cooldowns: Dictionary = {}
var audio_paused := false
var fade := 0.0
var exiting := false
var previous_position := Vector2.ZERO
var have_position := false
var step_distance := 0.0
var step_variant := 0
var voice_serial := 0

static func attach(parent: Node, environment := "") -> Node:
 var existing := parent.get_node_or_null("GameplayAudio")
 if existing != null: return existing
 var node = load("res://systems/audio/gameplay_audio.gd").new()
 node.name = "GameplayAudio"
 node.profile = environment
 parent.add_child(node)
 return node

static func play_at(parent: Node, kind: String) -> void:
 var current := parent
 while current != null:
  var existing := current.get_node_or_null("GameplayAudio")
  if existing != null:
   existing.cue(kind)
   return
  current = current.get_parent()
 attach(parent).cue(kind)

func _ready() -> void:
 for key in KEYS: sounds[key] = load(ROOT+key+".wav")
 for i in 8:
  var voice := AudioStreamPlayer.new()
  voice.bus = "Effects"
  voice.set_meta("priority",0)
  voice.set_meta("serial",0)
  voice.set_meta("gain",-18.0)
  add_child(voice)
  voices.append(voice)
 for entry in PROFILES.get(profile,[]):
  var voice := AudioStreamPlayer.new()
  voice.bus = "Ambience"
  var stream := load(ROOT+entry[0]+".wav").duplicate() as AudioStreamWAV
  stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
  stream.loop_begin = 0
  stream.loop_end = roundi(stream.get_length()*stream.mix_rate)
  voice.stream = stream
  voice.set_meta("gain",entry[1])
  voice.volume_db = -80
  add_child(voice)
  ambience.append(voice)
  voice.play()
 get_node("/root/SceneRouter").transition_started.connect(_transition_started)

func _transition_started(_path: String) -> void:
 exiting = true

func _process(delta: float) -> void:
 if audio_paused: return
 fade = move_toward(fade,0.0 if exiting else 1.0,delta/(0.18 if exiting else 0.65))
 for key in cooldowns: cooldowns[key] = maxf(0,cooldowns[key]-delta)
 _apply_gain()

func _apply_gain() -> void:
 var ambient_gain := linear_to_db(maxf(fade,0.0001))
 for voice in ambience: voice.volume_db = float(voice.get_meta("gain"))+ambient_gain
 # Only scene exit fades foley; a pickup immediately after entering stays audible.
 for voice in voices:
  voice.volume_db = float(voice.get_meta("gain"))+(ambient_gain if exiting else 0.0)

func set_audio_paused(value: bool) -> void:
 audio_paused = value
 for voice in voices: voice.stream_paused = value
 for voice in ambience: voice.stream_paused = value

func cue(kind: String, extra_db := 0.0) -> bool:
 if audio_paused or get_tree().paused or exiting or not sounds.has(kind): return false
 var category := "step" if kind.begins_with("step_") else kind
 if float(cooldowns.get(category,0.0))>0: return false
 var priority := 0 if category=="step" else (3 if kind in ["gift","wood_pickup","complete","equip","alert"] else 1)
 var voice: AudioStreamPlayer
 for candidate in voices:
  if not candidate.playing:
   voice=candidate
   break
 if voice==null:
  for candidate in voices:
   if int(candidate.get_meta("priority"))>=priority: continue
   if voice==null or int(candidate.get_meta("serial"))<int(voice.get_meta("serial")): voice=candidate
 if voice==null: return false
 voice.stop()
 voice.stream=sounds[kind]
 voice.pitch_scale=1.0
 voice.set_meta("priority",priority)
 voice_serial+=1
 voice.set_meta("serial",voice_serial)
 var gain := -22.0 if category=="step" else (-20.0 if kind in ["chime","roll","paper"] else -16.0)
 voice.set_meta("gain",gain+clampf(extra_db,-18,0))
 voice.volume_db=float(voice.get_meta("gain"))
 voice.stream_paused=false
 voice.play()
 cooldowns[category]=0.12 if category=="step" else (0.075 if kind=="chime" else 0.05)
 sound_played.emit(kind)
 return true

func footsteps(at: Vector2, grounded: bool, spacing := 55.0) -> void:
 if not have_position:
  previous_position=at
  have_position=true
  return
 var moved := previous_position.distance_to(at)
 previous_position=at
 if audio_paused or get_tree().paused or not grounded or moved>spacing*3:
  step_distance=0
  return
 if moved<0.01: return
 step_distance+=moved
 if step_distance>=spacing:
  step_distance=fmod(step_distance,spacing)
  step_variant=(step_variant+1)%3
  cue("step_"+str(step_variant+1))

func _exit_tree() -> void:
 for voice in voices+ambience:
  voice.stop()
  voice.stream=null
