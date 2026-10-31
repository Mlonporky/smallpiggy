extends Node
## Original offline score and synthesized foley. No voices or field recordings.
signal sound_played(key: String)
const TRACKS := {
 "path":preload("res://assets/audio/finale/path_v2.wav"),
 "reunion":preload("res://assets/audio/finale/reunion_v2.wav"),
 "memory":preload("res://assets/audio/finale/memory_v2.wav"),
 "curse":preload("res://assets/audio/finale/curse_v2.wav"),
 "joy":preload("res://assets/audio/finale/joy_v2.wav"),
 "home":preload("res://assets/audio/finale/afterglow_v2.wav"),
 "restored":preload("res://assets/audio/finale/manor_home_v1.wav")}
const SOUNDS := {
 "step_1":preload("res://assets/audio/finale/step_earth_1.wav"),
 "step_2":preload("res://assets/audio/finale/step_earth_2.wav"),
 "step_3":preload("res://assets/audio/finale/step_earth_3.wav"),
 "cast":preload("res://assets/audio/finale/curse_cast_v1.wav"),
 "wave":preload("res://assets/audio/finale/joy_wave_v1.wav"),
 "dissolve":preload("res://assets/audio/finale/dissolve_v1.wav")}
const MUSIC_GAIN_DB := {"path": -15.0, "reunion": -13.0, "memory": -21.0, "curse": -14.0, "joy": -11.0, "home": -13.0, "restored": -10.0}
var muted := false
var mood := ""
var paused := false
var players: Array[AudioStreamPlayer]=[]
var music: Array[AudioStreamPlayer]=[]
var ambience: Array[AudioStreamPlayer]=[]
var effects: Array[AudioStreamPlayer]=[]
var loops: Dictionary={}
var active_music := 0
var music_gains := [0.0,0.0]
var fade_from := [0.0,0.0]
var fade_to := [0.0,0.0]
var fade_time := 1.0
var music_duck := 1.0
var music_duck_target := 1.0
var environment := [0.025,0.09,0.0]
var foot_phase: Dictionary={}
var fired: Dictionary={}
var effect_cursor := 0
var step_variant := 0
var scene_id := ""

func _ready() -> void:
 muted=AppSettings.muted
 AppSettings.changed.connect(_settings_changed)
 for key in TRACKS: loops[key]=_loop(TRACKS[key])
 for i in 2: music.append(_player("Music"))
 for stream in [preload("res://assets/audio/finale/wind.wav"),preload("res://assets/audio/finale/leaves_v1.wav"),preload("res://assets/audio/finale/birds_v1.wav")]:
  var player:=_player("Ambience")
  player.stream=_loop(stream)
  player.play()
  ambience.append(player)
 for i in 6: effects.append(_player())
 _apply_mix()

func _player(bus := "Effects") -> AudioStreamPlayer:
 var player:=AudioStreamPlayer.new()
 player.bus=bus
 player.volume_db=-80
 add_child(player)
 players.append(player)
 return player

func set_mood(value: String) -> void:
 if value==mood: return
 mood=value
 active_music=1-active_music
 var player: AudioStreamPlayer=music[active_music]
 player.stop()
 player.stream=loops[value]
 player.play()
 player.stream_paused=paused
 fade_from=music_gains.duplicate()
 fade_to=[0.0,0.0]
 fade_to[active_music]=db_to_linear(MUSIC_GAIN_DB[value])
 fade_time=0.0
 _apply_mix()

func _process(delta: float) -> void:
 if paused: return
 music_duck=move_toward(music_duck,music_duck_target,delta/0.3)
 fade_time=minf(1.0,fade_time+delta/.85)
 for i in 2:
  music_gains[i]=lerpf(fade_from[i],fade_to[i],smoothstep(0,1,fade_time))
  if fade_time>=1.0 and i!=active_music and music[i].playing: music[i].stop()
 _apply_mix()

func begin_scene(id: String) -> void:
 scene_id=id
 fired.clear()
 foot_phase.clear()
 for player in effects: player.stop()

func timeline(id: String, seconds: float, delta: float) -> void:
 var restored := id in ["return_home","home_here","home_walk","home_find","home_promise","home_seek","walk_away","final_secret","final_question","final_reply","leave_frame","final_shot","fade_out","black_pause","ending_title","the_end","credits"]
 var forest_return := id in ["curse_broken","light_travels"]
 var daylight := smoothstep(7.4,9.4,seconds) if id=="manor_restore" else (1.0 if restored or forest_return else 0.0)
 environment=[lerpf(.025,.010,daylight),lerpf(.09,.07,daylight),daylight*.25]
 music_duck_target=1.0
 if id=="someone":
  music_duck_target=lerpf(.12,.7,smoothstep(.8,3.5,seconds))
 if id in ["reunion_silence","first_reunion","first_question","secret_name","secret_question","secret_pause","secret_phrase","remember_name","remember","remember_house","remember_cups","remember_gift","remember_pause"]:
  music_duck_target=.65
 if id.begins_with("memory_") and id!="memory_objects":
  music_duck_target=.35
  if id=="memory_house": music_duck_target*=smoothstep(.7,1.5,seconds)
  environment[0]*=.35
  environment[1]*=.35
 if id=="red_cape": environment[0]+=sin(clampf(seconds/2.0,0,1)*PI)*.06
 if id=="fade_out":
  for i in 3: environment[i]*=1.0-smoothstep(0,2.5,seconds)
 if id in ["black_pause","ending_title","the_end","credits"]: environment=[0.0,0.0,0.0]
 if restored or (id=="manor_restore" and seconds>=9.4): set_mood("restored")
 if delta>0:
  # Audible before the boy enters; each cue fires once, never on direct late entry.
  if id=="someone" and seconds<.8:
   if seconds>=.12: _cue("step_1",-23)
   if seconds>=.58: _cue("step_2",-23)
  if id=="final_curse" and seconds>=.35: _cue("cast",-12)
  if id=="joy_burst": _cue("wave",-9)
  if id=="wizard_dissolve": _cue("dissolve",-15)
 _apply_mix()

func footsteps(actor: Node2D, key: String) -> void:
 # Derive contact cadence from the same phase as the rendered gait. Resetting
 # a shot establishes a baseline; it never catches up with a burst of footsteps.
 var phase: int
 if actor.rig!=null:
  var stride: float=actor.rig.STRIDE if actor.kind=="pig" else 44.0
  var offset:=-.15 if actor.kind=="pig" else 0.0
  # Accent one planted foot per stride; the opposite contact stays soft so two
  # short-legged walkers do not turn the quiet homecoming into constant tapping.
  phase=int(floor(actor.rig.travel/stride+offset))
 else: phase=int(floor(actor.distance/39.0))
 if foot_phase.has(key) and phase!=foot_phase[key] and actor.visible and actor.walking:
  step_variant=(step_variant+1)%3
  play_sound("step_"+str(step_variant+1),-13 if key=="pig" else -18)
 foot_phase[key]=phase

func _cue(key: String, gain: float) -> void:
 if fired.has(key): return
 fired[key]=true
 play_sound(key,gain)

func play_sound(key: String, gain: float) -> void:
 if paused: return
 var player: AudioStreamPlayer=effects[effect_cursor]
 effect_cursor=(effect_cursor+1)%effects.size()
 player.stream=SOUNDS[key]
 player.set_meta("gain",gain)
 player.volume_db=-80 if muted else gain
 player.play()
 sound_played.emit(key)

func _apply_mix() -> void:
 for i in music.size(): _volume(music[i],-80 if muted else linear_to_db(maxf(.0001,music_gains[i]*music_duck)))
 for i in ambience.size(): _volume(ambience[i],-80 if muted else linear_to_db(maxf(.0001,environment[i])))
 for player in effects: _volume(player,-80 if muted else float(player.get_meta("gain",-80)))

func _volume(player: AudioStreamPlayer, gain: float) -> void:
 if absf(player.volume_db-gain)>.01: player.volume_db=gain

func pause(value: bool) -> void:
 paused=value
 for player in players: player.stream_paused=value

func set_muted(value: bool) -> void:
 AppSettings.set_muted(value)

func _settings_changed() -> void:
 muted=AppSettings.muted
 _apply_mix()

func _loop(source: AudioStreamWAV) -> AudioStreamWAV:
 var stream:=source.duplicate() as AudioStreamWAV
 stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
 stream.loop_end=int(round(stream.get_length()*stream.mix_rate))
 return stream

func _exit_tree() -> void:
 for player in players:
  player.stop()
  player.stream=null
