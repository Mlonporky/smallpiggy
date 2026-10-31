// Validate the silent 18-second art study and decode review frames from the MP4.
// Usage: swift tools/verify_phase4_movie.swift MOVIE.mp4 OUTPUT_DIRECTORY
import AVFoundation
import AppKit
guard CommandLine.arguments.count == 3 else { fatalError("Usage: verify_phase4_movie MOVIE.mp4 OUTPUT_DIRECTORY") }
let asset = AVURLAsset(url: URL(fileURLWithPath: CommandLine.arguments[1]))
let folder = URL(fileURLWithPath: CommandLine.arguments[2])
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
guard let track = asset.tracks(withMediaType: .video).first else { fatalError("Missing video") }
guard asset.tracks(withMediaType: .audio).isEmpty else { fatalError("This sample must be silent") }
let duration = CMTimeGetSeconds(asset.duration)
guard abs(duration - 18) < 0.002 else { fatalError("Unexpected duration: \(duration)") }
let reader = try AVAssetReader(asset: asset)
let output = AVAssetReaderTrackOutput(track: track, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
reader.add(output)
guard reader.startReading() else { fatalError("Cannot decode") }
var frames = 0
var error = 0.0
var previous = -1.0
while let buffer = output.copyNextSampleBuffer() {
 let time = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(buffer))
 guard CMSampleBufferGetImageBuffer(buffer) != nil, time > previous else { fatalError("Invalid video frame") }
 error = max(error, abs(time - Double(frames) / 30))
 previous = time
 frames += 1
}
guard reader.status == .completed, frames == 540, error < 0.0001 else { fatalError("Frame count or timestamps invalid: \(frames), \(error)") }
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero
for seconds in [1.0, 7.7, 13.2, 17.5] {
 var actual = CMTime.zero
 let frame = try generator.copyCGImage(at: CMTime(seconds: seconds, preferredTimescale: 600), actualTime: &actual)
 let rep = NSBitmapImageRep(cgImage: frame)
 try rep.representation(using: .png, properties: [:])!.write(to: folder.appendingPathComponent("decoded_\(seconds).png"))
}
let report: [String: Any] = ["duration": duration, "decoded_frames": frames, "fps": track.nominalFrameRate, "width": track.naturalSize.width, "height": track.naturalSize.height, "maximum_timing_error": error, "audio_tracks": 0, "note": "Offline export; does not establish runtime display smoothness."]
let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
try data.write(to: folder.appendingPathComponent("movie_validation.json"))
print("PHASE4_MOVIE_VERIFIED \(String(data: data, encoding: .utf8)!)")
