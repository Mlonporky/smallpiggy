extends Node
## Original procedural music-box sketch + quiet wind. No downloaded audio, no voices.
var muted := false
var players: Array[AudioStreamPlayer] = []
var mood := ""
var cache: Dictionary = {}
func _ready() -> void:
 for i in 2:
  var player:=AudioStreamPlayer.new()
  player.volume_db=-19 if i==0 else -30
  add_child(player)
  players.append(player)
 players[1].stream=_wind()
 players[1].play()
func set_mood(value: String) -> void:
 if value==mood: return
 mood=value
 if not cache.has(value): cache[value]=_music(value)
 players[0].stream=cache[value]
 players[0].play()
 players[0].volume_db=-60 if muted else (-30 if value=="memory" else -19)
func pause(value: bool) -> void:
 for player in players: player.stream_paused=value
func set_muted(value: bool) -> void:
 muted=value
 players[0].volume_db=-60 if muted else (-30 if mood=="memory" else -19)
 players[1].volume_db=-60 if muted else -30
func _wav(bytes: PackedByteArray, rate: int) -> AudioStreamWAV:
 var stream:=AudioStreamWAV.new()
 stream.format=AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate=rate
 stream.data=bytes
 stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
 stream.loop_end=bytes.size()/2
 return stream
func _music(value: String) -> AudioStreamWAV:
 var rate:=22050
 var length:=16.0
 var notes: Array=[60,64,67,71,69,67,64,62]
 if value=="curse": notes=[48,55,58,61,48,54,58,55]
 elif value=="joy": notes=[60,67,72,76,74,72,67,64]
 elif value=="home": notes=[60,64,67,72,71,67,64,60]
 var bytes:=PackedByteArray()
 bytes.resize(int(rate*length)*2)
 for i in int(rate*length):
  var t:=float(i)/rate
  var sample:=0.0
  for j in 8:
   var age:=t-j*2.0
   if age>=0 and age<4:
    var f:=440*pow(2,(float(notes[j])-69)/12)
    sample+=(sin(TAU*f*age)+0.22*sin(TAU*f*2*age))*exp(-age*1.8)*minf(age*35,1)*0.19
  sample*=smoothstep(0,0.05,t)*(1-smoothstep(15.4,16,t))
  bytes.encode_s16(i*2,int(clampf(sample,-1,1)*32767))
 return _wav(bytes,rate)
func _wind() -> AudioStreamWAV:
 var rate:=22050
 var bytes:=PackedByteArray()
 bytes.resize(rate*8*2)
 var rng:=RandomNumberGenerator.new()
 rng.seed=2129
 var low:=0.0
 for i in rate*8:
  low=lerpf(low,rng.randf_range(-1,1),0.015)
  var t:=float(i)/rate
  var value:=low*(0.5+0.3*sin(t*TAU/8))*sin(PI*t/8)
  bytes.encode_s16(i*2,int(value*32767))
 return _wav(bytes,rate)
