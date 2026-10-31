// Combine a rendered movie with its matching Godot Movie Maker WAV.
import Foundation
import AVFoundation
guard CommandLine.arguments.count == 4 else { fatalError("mux_video_audio SILENT.mp4 ENGINE.wav OUTPUT.mp4") }
let video = AVURLAsset(url: URL(fileURLWithPath: CommandLine.arguments[1]))
let audio = AVURLAsset(url: URL(fileURLWithPath: CommandLine.arguments[2]))
let composition = AVMutableComposition()
let v = video.tracks(withMediaType: .video).first!
let a = audio.tracks(withMediaType: .audio).first!
guard abs(CMTimeGetSeconds(video.duration) - CMTimeGetSeconds(audio.duration)) < 0.002 else {
 fatalError("Video and audio durations differ; refusing to trim either track")
}
let duration = video.duration
try composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: v, at: .zero)
try composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: a, at: .zero)
let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
export.outputURL = URL(fileURLWithPath: CommandLine.arguments[3])
export.outputFileType = .mp4
let done = DispatchSemaphore(value: 0)
export.exportAsynchronously { done.signal() }
done.wait()
guard export.status == .completed else { fatalError("Mux failed: \(String(describing: export.error))") }
print("VIDEO_AUDIO_OK seconds=\(CMTimeGetSeconds(duration))")
