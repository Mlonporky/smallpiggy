// Decode the entire movie, check video timestamps and audio length, and save
// exact-time review frames. Usage: MOVIE.mp4 OUTPUT_DIRECTORY EXPECTED_FRAMES
import AVFoundation
import AppKit

guard CommandLine.arguments.count == 4, let expected = Int(CommandLine.arguments[3]), expected > 0 else {
 fatalError("Usage: verify_finale_movie MOVIE.mp4 OUTPUT_DIRECTORY EXPECTED_FRAMES")
}
let asset = AVURLAsset(url: URL(fileURLWithPath: CommandLine.arguments[1]))
let folder = URL(fileURLWithPath: CommandLine.arguments[2])
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
guard let video = asset.tracks(withMediaType: .video).first,
      let audio = asset.tracks(withMediaType: .audio).first else { fatalError("Missing video or audio") }
let duration = CMTimeGetSeconds(asset.duration)
let expectedDuration = Double(expected) / 30.0
guard abs(duration - expectedDuration) < 0.002 else { fatalError("Unexpected movie duration: \(duration)") }
let videoReader = try AVAssetReader(asset: asset)
let videoOutput = AVAssetReaderTrackOutput(track: video, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
videoReader.add(videoOutput)
guard videoReader.startReading() else { fatalError("Cannot decode video") }
var frames = 0
var previous = -1.0
var maximumGap = 0.0
var maximumTimingError = 0.0
while let buffer = videoOutput.copyNextSampleBuffer() {
 let timestamp = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(buffer))
 guard CMSampleBufferGetImageBuffer(buffer) != nil, timestamp > previous else { fatalError("Invalid decoded video frame") }
 if frames > 0 { maximumGap = max(maximumGap, timestamp - previous) }
 maximumTimingError = max(maximumTimingError, abs(timestamp - Double(frames) / 30.0))
 previous = timestamp
 frames += 1
}
guard videoReader.status == .completed, frames == expected, maximumTimingError < 0.0001 else {
 fatalError("Frame/timestamp mismatch: frames=\(frames), timing_error=\(maximumTimingError)")
}
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero
var captured: [[String: Any]] = []
let reviewTimes = duration > 20 ? [1.0, 1.667, 3.4, 6.9, 10.9, 13.5, 17.9, 19.0, 19.6, 21.9, 24.0, 26.5] : duration < 10 ? [0.0, 1.0/3.0, 2.0/3.0, 1.0, 1.4, 2.5, 4.0, 6.2] : [0.5, 6.2, 7.8, 10.0, 14.0, 17.5]
for seconds in reviewTimes where seconds < duration {
 var actual = CMTime.zero
 let frame = try generator.copyCGImage(at: CMTime(seconds: seconds, preferredTimescale: 600), actualTime: &actual)
 let rep = NSBitmapImageRep(cgImage: frame)
 try rep.representation(using: .png, properties: [:])!.write(to: folder.appendingPathComponent("frame-\(seconds).png"))
 captured.append(["requested": seconds, "actual": CMTimeGetSeconds(actual)])
}
let audioReader = try AVAssetReader(asset: asset)
let audioOutput = AVAssetReaderTrackOutput(track: audio, outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM, AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false, AVLinearPCMIsBigEndianKey: false, AVLinearPCMIsNonInterleaved: false])
audioReader.add(audioOutput)
guard audioReader.startReading() else { fatalError("Cannot decode audio") }
var samples = 0
var audioStart = -1.0
var audioEnd = 0.0
var audioGap = 0.0
var peak = 0.0
var squareSum = 0.0
var values = 0
while let buffer = audioOutput.copyNextSampleBuffer() {
 let start = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(buffer))
 if audioStart < 0 { audioStart = start } else { audioGap = max(audioGap, abs(start - audioEnd)) }
 audioEnd = start + CMTimeGetSeconds(CMSampleBufferGetDuration(buffer))
 samples += CMSampleBufferGetNumSamples(buffer)
 if let block = CMSampleBufferGetDataBuffer(buffer) {
  let length = CMBlockBufferGetDataLength(block)
  var pcm = [Int16](repeating: 0, count: length / 2)
  let status = pcm.withUnsafeMutableBytes { CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: length, destination: $0.baseAddress!) }
  guard status == kCMBlockBufferNoErr else { fatalError("Cannot read decoded PCM") }
  for value in pcm {
   let normalized = Double(value) / 32768.0
   peak = max(peak, abs(normalized)); squareSum += normalized * normalized; values += 1
  }
 }
}
guard audioReader.status == .completed, samples > 0, abs(audioStart) < 0.002,
      abs(audioEnd - expectedDuration) < 0.002, audioGap < 0.002, peak > 0, peak < 1 else {
 fatalError("Invalid audio: start=\(audioStart) end=\(audioEnd) gap=\(audioGap) peak=\(peak)")
}
let report: [String: Any] = ["duration": duration, "decoded_frames": frames, "fps": video.nominalFrameRate,
 "width": video.naturalSize.width, "height": video.naturalSize.height,
 "maximum_video_gap": maximumGap, "maximum_video_timing_error": maximumTimingError,
 "last_video_timestamp": previous, "audio_samples": samples, "audio_start": audioStart,
 "audio_end": audioEnd, "maximum_audio_gap": audioGap,
 "audio_peak_dbfs": 20 * log10(peak), "audio_rms_dbfs": 20 * log10(sqrt(squareSum / Double(values))), "review_frames": captured]
let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
try data.write(to: folder.appendingPathComponent("movie_validation.json"))
print("FINALE_MOVIE_VERIFIED \(String(data: data, encoding: .utf8)!)")
