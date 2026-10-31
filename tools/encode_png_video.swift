// Encode a Godot Movie Maker PNG sequence as a silent 30 fps H.264 movie.
// Usage: swift tools/encode_png_video.swift FRAME_DIRECTORY NEW_OUTPUT.mp4
import Foundation
import AVFoundation
import CoreGraphics
import ImageIO
guard CommandLine.arguments.count == 3 else { fatalError("Usage: encode_png_video FRAME_DIRECTORY NEW_OUTPUT.mp4") }
let directory = URL(fileURLWithPath: CommandLine.arguments[1])
let destination = URL(fileURLWithPath: CommandLine.arguments[2])
let frames = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil).filter { $0.pathExtension == "png" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
guard !frames.isEmpty else { fatalError("No rendered frames") }
func read(_ url: URL) -> CGImage {
 let source = CGImageSourceCreateWithURL(url as CFURL, nil)!
 return CGImageSourceCreateImageAtIndex(source, 0, nil)!
}
let first = read(frames[0])
let writer = try AVAssetWriter(outputURL: destination, fileType: .mp4)
let settings: [String: Any] = [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: first.width, AVVideoHeightKey: first.height, AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 3000000]]
let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
input.expectsMediaDataInRealTime = false
let attrs: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB, kCVPixelBufferWidthKey as String: first.width, kCVPixelBufferHeightKey as String: first.height, kCVPixelBufferCGImageCompatibilityKey as String: true, kCVPixelBufferCGBitmapContextCompatibilityKey as String: true]
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: attrs)
writer.add(input)
guard writer.startWriting() else { print("Encoder start failed: \(String(describing: writer.error))"); exit(1) }
writer.startSession(atSourceTime: .zero)
for (index, url) in frames.enumerated() {
 while !input.isReadyForMoreMediaData { Thread.sleep(forTimeInterval: 0.002) }
 try autoreleasepool {
  var buffer: CVPixelBuffer?
  guard CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &buffer) == kCVReturnSuccess else { fatalError("Pixel buffer allocation failed") }
  let pixels = buffer!
  CVPixelBufferLockBaseAddress(pixels, [])
  let context = CGContext(data: CVPixelBufferGetBaseAddress(pixels), width: first.width, height: first.height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixels), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
  context.draw(read(url), in: CGRect(x: 0, y: 0, width: first.width, height: first.height))
  CVPixelBufferUnlockBaseAddress(pixels, [])
  guard adaptor.append(pixels, withPresentationTime: CMTime(value: Int64(index), timescale: 30)) else { throw writer.error! }
 }
}
input.markAsFinished()
let done = DispatchSemaphore(value: 0)
writer.finishWriting { done.signal() }
done.wait()
guard writer.status == .completed else { fatalError("Encoding failed: \(String(describing: writer.error))") }
print("PNG_VIDEO_OK frames=\(frames.count) size=\(first.width)x\(first.height)")
