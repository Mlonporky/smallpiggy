// Render the original note score with macOS's built-in General MIDI instruments.
import Foundation
import AVFoundation
struct Event: Decodable { let time: Double; let duration: Double; let instrument: Int; let pitch: Int; let velocity: Int }
struct Score: Decodable { let duration: Double; let events: [Event] }
struct Message { let frame: AVAudioFramePosition; let instrument: Int; let pitch: UInt8; let velocity: UInt8 }
guard CommandLine.arguments.count == 3 else { fatalError("render_score SCORE.json OUTPUT.caf") }
let score = try JSONDecoder().decode(Score.self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
let engine = AVAudioEngine()
let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
let reverb = AVAudioUnitReverb()
reverb.loadFactoryPreset(.mediumHall)
reverb.wetDryMix = 18
engine.attach(reverb)
let mix = AVAudioMixerNode()
engine.attach(mix)
engine.connect(mix,to:reverb,format:format)
engine.connect(reverb,to:engine.mainMixerNode,format:format)
var instruments: [Int:AVAudioUnitSampler] = [:]
let bank = URL(fileURLWithPath:"/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")
for program in Set(score.events.map { $0.instrument }).sorted() {
 let sampler = AVAudioUnitSampler()
 engine.attach(sampler)
 engine.connect(sampler,to:mix,format:format)
 try sampler.loadSoundBankInstrument(at:bank,program:UInt8(program),bankMSB:121,bankLSB:0)
 sampler.masterGain = -10
 sampler.sendController(10,withValue:UInt8([0:62,8:78,46:44,48:70,42:51,73:60][program] ?? 64),onChannel:0)
 instruments[program] = sampler
}
try engine.enableManualRenderingMode(.offline,format:format,maximumFrameCount:1024)
let file = try AVAudioFile(forWriting:URL(fileURLWithPath:CommandLine.arguments[2]),settings:format.settings)
let buffer = AVAudioPCMBuffer(pcmFormat:engine.manualRenderingFormat,frameCapacity:1024)!
var messages: [Message] = []
for event in score.events {
 messages.append(Message(frame:Int64(event.time*44100),instrument:event.instrument,pitch:UInt8(event.pitch),velocity:UInt8(event.velocity)))
 messages.append(Message(frame:Int64((event.time+event.duration)*44100),instrument:event.instrument,pitch:UInt8(event.pitch),velocity:0))
}
messages.sort { $0.frame == $1.frame ? $0.velocity < $1.velocity : $0.frame < $1.frame }
try engine.start()
var index = 0
let end = AVAudioFramePosition(score.duration*44100)
var retries = 0
while engine.manualRenderingSampleTime < end {
 let now = engine.manualRenderingSampleTime
 while index < messages.count && messages[index].frame <= now {
  let e = messages[index]
  if e.velocity == 0 { instruments[e.instrument]!.stopNote(e.pitch,onChannel:0) }
  else { instruments[e.instrument]!.startNote(e.pitch,withVelocity:e.velocity,onChannel:0) }
  index += 1
 }
 let next = index < messages.count ? min(end,messages[index].frame) : end
 let count = AVAudioFrameCount(min(1024,next-now))
 if count == 0 { continue }
 let status = try engine.renderOffline(count,to:buffer)
 switch status {
 case .success: try file.write(from:buffer); retries = 0
 case .cannotDoInCurrentContext, .insufficientDataFromInputNode:
  retries += 1
  if retries > 100 { fatalError("Offline renderer stalled") }
 default: fatalError("Offline rendering failed")
 }
}
engine.stop()
print("SCORE_RENDER_OK seconds=\(score.duration) notes=\(score.events.count)")
