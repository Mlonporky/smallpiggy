extends Node
## Short procedural cues; placeholders until recorded sound design is available.
var voices: Array[AudioStreamPlayer] = []
func _ready() -> void:
 for i in 4:
  var voice := AudioStreamPlayer.new()
  voice.volume_db = -19
  add_child(voice)
  voices.append(voice)
func cue(kind: String) -> void:
 var voice: AudioStreamPlayer = null
 for candidate in voices:
  if not candidate.playing:
   voice = candidate
   break
 if voice==null: return
 # [samples, start Hz, end Hz] per cue; anything unknown uses the low swing/hit sweep.
 var shape: Array = {"heal":[4410,650.0,1300.0],"chime":[3300,1250.0,1900.0],"bounce":[3900,210.0,560.0],"crack":[1500,150.0,70.0],"purify":[5200,880.0,1760.0],"alert":[1300,1320.0,1500.0],"roll":[3000,130.0,90.0],"puff":[2600,320.0,150.0],"swoop":[3300,560.0,240.0],"drop":[1700,760.0,320.0],"clang":[2400,2300.0,1800.0]}.get(kind,[1764,180.0,100.0])
 var count: int = shape[0]
 var data := PackedByteArray()
 data.resize(count*2)
 var phase := 0.0
 for i in count:
  var progress := float(i)/count
  var hz: float = lerpf(shape[1],shape[2],progress)
  phase += TAU*hz/22050
  var value := sin(phase)*(1-progress)*minf(progress*25,1)*0.45
  data.encode_s16(i*2,int(value*32767))
 var stream := AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = 22050
 stream.data = data
 voice.stream = stream
 voice.play()
