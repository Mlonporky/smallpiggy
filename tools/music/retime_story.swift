// Pitch-preserving offline render of the opening score. macOS AVFoundation only.
// swift retime_story.swift INPUT.wav OUTPUT.wav RATE
import Foundation
import AVFoundation

guard CommandLine.arguments.count == 4,
      let rate = Float(CommandLine.arguments[3]), rate > 0 else {
    fatalError("retime_story INPUT.wav OUTPUT.wav RATE")
}
func render() throws {
let input = try AVAudioFile(forReading: URL(fileURLWithPath: CommandLine.arguments[1]))
let engine = AVAudioEngine()
let player = AVAudioPlayerNode()
let stretch = AVAudioUnitTimePitch()
stretch.rate = rate
stretch.pitch = 0
let format = input.processingFormat
engine.attach(player)
engine.attach(stretch)
engine.connect(player, to: stretch, format: format)
engine.connect(stretch, to: engine.mainMixerNode, format: format)
try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 1024)
let output = try AVAudioFile(forWriting: URL(fileURLWithPath: CommandLine.arguments[2]), settings: [
    AVFormatIDKey: kAudioFormatLinearPCM,
    AVSampleRateKey: format.sampleRate,
    AVNumberOfChannelsKey: format.channelCount,
    AVLinearPCMBitDepthKey: 16,
    AVLinearPCMIsFloatKey: false,
    AVLinearPCMIsBigEndianKey: false
])
let buffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: 1024)!
player.scheduleFile(input, at: nil)
try engine.start()
player.play()
let end = AVAudioFramePosition((Double(input.length) / Double(rate)).rounded())
var retries = 0
while engine.manualRenderingSampleTime < end {
    let count = AVAudioFrameCount(min(1024, end - engine.manualRenderingSampleTime))
    switch try engine.renderOffline(count, to: buffer) {
    case .success:
        try output.write(from: buffer)
        retries = 0
    case .cannotDoInCurrentContext, .insufficientDataFromInputNode:
        retries += 1
        if retries > 100 { fatalError("Offline renderer stalled") }
    default: fatalError("Offline rendering failed")
    }
}
engine.stop()
print("STORY_RETIME_OK frames=\(end) seconds=\(Double(end) / format.sampleRate) rate=\(rate) pitch=0")

}
try render()
