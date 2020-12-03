import Flutter
import UIKit

import Foundation
import AVFoundation
import Photos
import MobileCoreServices
import OcFlutterLivePhotoPlugin

public class SwiftFlutterLivePhotoPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_live_photo", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterLivePhotoPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

            
    switch call.method {

            case "generateFromLocalFile":
                let args = call.arguments as! [String: Any]
                guard let fileUrl = args["fileUrl"] as? String else {
                    result(false)
                    return
                }

                guard let pngUrl = args["pngUrl"] as? String else {
                    result(false)
                    return
                }

                let livePhotoClient = LivePhotoClient(callback: {() in
                    result(true)
                })

                print(fileUrl)
                //livePhotoClient.convertMp4ToMov(mp4Path: URL(string: fileUrl)!)
    
                livePhotoClient.generateMovLivePhoto(movPath: URL(string: fileUrl)!, pngPath: URL(string: pngUrl)!)
                    
    
//                print("AVAssetExportSessionStatus completed")
//                livePhotoClient.generateThumbnail(movURL:  URL(string: fileUrl)!)
//                print("generateThumbnail completed")
//                livePhotoClient.generateLivePhoto()
                
                
            case "generateFromURL":
                let args = call.arguments as! [String: Any]
                guard let videoURL = args["videoURL"] as? String else {
                    result(false)
                    return
                }
                let livePhotoClient = LivePhotoClient(callback: {() in
                    result(true)
                })
                livePhotoClient.runLivePhotoConvertion(rawURL: videoURL)
            case "openSettings":
                if let url = URL(string: "App-prefs:root=Wallpaper"), UIApplication.shared.canOpenURL(url) {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                }
  
            default:
                result(FlutterMethodNotImplemented)
        }
      }
  
}


class LivePhotoClient {
    // LivePhoto変換の登場人物
    let SRC_KEY = "mp4"
    let STILL_KEY = "png"
    let MOV_KEY = "mov"
    
    let completedCallback: (() -> Void)
    
    init(callback: @escaping () -> Void) {
        completedCallback = callback
    }
    
    // LivePhoto変換エントリポイント
    public func runLivePhotoConvertion(rawURL: String) {
        if let videoURL = URL(string: rawURL) {
            let photos = PHPhotoLibrary.authorizationStatus()
            if photos == .notDetermined {
                PHPhotoLibrary.requestAuthorization({status in
                    if status == .authorized{
                        self.downloadAsync(
                            url: videoURL,
                            to: self.filePath(forKey: self.SRC_KEY),
                            completion: self.convertMp4ToMov
                        )
                    } else {
                        print("CameraRoll permission denied")
                    }
                })
            } else {
                self.downloadAsync(
                    url: videoURL,
                    to: self.filePath(forKey: self.SRC_KEY),
                    completion: self.convertMp4ToMov
                )
            }
        }
    }
    
    // MP4をMovに変換する
    public func convertMp4ToMov(mp4Path: URL) {
        // srcのビデオをmovに変換する
        let avAsset = AVURLAsset(url: mp4Path)
        let preset = AVAssetExportPresetPassthrough
        let outFileType = AVFileType.mov
        if let exportSession = AVAssetExportSession(asset: avAsset, presetName: preset), let outputURL = self.filePath(forKey: MOV_KEY) {
            
            AVAssetExportSession.determineCompatibility(ofExportPreset: preset, with: avAsset, outputFileType: outFileType, completionHandler: { (isCompatible) in
                if !isCompatible {
                    return
            }})
            
            exportSession.outputFileType = outFileType
            exportSession.outputURL = outputURL
            self.deleteFile(url: outputURL)
            
            exportSession.exportAsynchronously { () -> Void in
                switch exportSession.status {
                case AVAssetExportSessionStatus.completed:
                    print("AVAssetExportSessionStatus completed")
                    self.generateThumbnail(movURL: outputURL)
                    print("generateThumbnail completed")
                    self.generateLivePhoto()
                    break
                case AVAssetExportSessionStatus.failed:
                    print("AVAssetExportSessionStatus failed. \(String(describing: exportSession.error))")
                    break
                case AVAssetExportSessionStatus.cancelled:
                    print("AVAssetExportSessionStatus cancelled")
                    break
                default:
                    break
                }
            }
        }
    }
    
    public func generateMovLivePhoto(movPath: URL,pngPath: URL) {
        let pngPath = self.filePath(forKey: STILL_KEY)!
        let movPath = self.filePath(forKey: MOV_KEY)!
        if #available(iOS 9.1, *) {
            print("Start to generate LivePhoto")
            LivePhoto.generate(from: pngPath, videoURL: movPath, progress: { percent in }, completion: { livePhoto, resources in
                print("Generation done")
                if let resources = resources {
                    print("Success to generate Live Photo")
                    LivePhoto.saveToLibrary(resources, completion: {(success) in
                        if success {
                            print("Successed to save Photos")
                            self.completedCallback()
                        } else {
                            print("Failed to save Photos")
                            self.completedCallback()
                        }
                    })
                }
            })
        }
    }
    
    // LivePhotoの生成
    public func generateLivePhoto() {
        let pngPath = self.filePath(forKey: STILL_KEY)!
        let movPath = self.filePath(forKey: MOV_KEY)!
        if #available(iOS 9.1, *) {
            print("Start to generate LivePhoto")
            LivePhoto.generate(from: pngPath, videoURL: movPath, progress: { percent in }, completion: { livePhoto, resources in
                print("Generation done")
                if let resources = resources {
                    print("Success to generate Live Photo")
                    LivePhoto.saveToLibrary(resources, completion: {(success) in
                        if success {
                            print("Successed to save Photos")
                            self.completedCallback()
                        } else {
                            print("Failed to save Photos")
                            self.completedCallback()
                        }
                    })
                }
            })
        }
    }
    
    // ビデオからサムネイルpngを生成する
    public func generateThumbnail(movURL: URL?) {
        guard let movURL = movURL else { return }
        let asset = AVURLAsset(url: movURL, options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        let filePath = self.filePath(forKey: STILL_KEY)
        if let cgImage = try? imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil) {
            let pngImage = UIImage(cgImage: cgImage)
            if let pngRep = pngImage.pngData() {
                if let filePath = filePath {
                    do {
                        self.deleteFile(url: filePath)
                        try pngRep.write(to: filePath, options: .atomic)
                    } catch let err {
                        print("Failed to generate png: \(err)")
                    }
                } else {
                    print("filePath nil")
                }
            } else {
                print("pngRep nil")
            }
        }
    }
    
    // 非同期ダウンロード
    private func downloadAsync(url: URL, to localUrl: URL?, completion: @escaping (_: URL) -> ()) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let request = URLRequest(url: url)
        let task = session.downloadTask(with: request) {(tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, let localUrl = localUrl, error == nil {
                do {
                    self.deleteFile(url: localUrl)
                    try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
                    completion(localUrl)
                } catch let err {
                    print(err)
                }
            } else {
                print("Downloading Locally error")
            }
        }
        task.resume()
    }
    
    private func filePath(forKey key: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentURL = fileManager.urls(for: .documentDirectory,
                                                in: FileManager.SearchPathDomainMask.userDomainMask).first else { return nil }
        return documentURL.appendingPathComponent(key + "." + key)
    }
    
    private func deleteFile(url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            print("Delete existing file")
            do {
                try FileManager.default.removeItem(atPath: url.path)
            } catch {
                print("Failed to delete file")
            }
        }
    }
}

//
//  LivePhoto.swift
//  Live Photos
//  https://github.com/LimitPoint/LivePhoto
//
//  Created by Alexander Pagliaro on 7/25/18.
//  Copyright © 2018 Limit Point LLC. All rights reserved.
//

class LivePhoto {
    // MARK: PUBLIC
    typealias LivePhotoResources = (pairedImage: URL, pairedVideo: URL)
    /// Returns the paired image and video for the given PHLivePhoto
    @available(iOS 9.1, *)
    public class func extractResources(from livePhoto: PHLivePhoto, completion: @escaping (LivePhotoResources?) -> Void) {
        queue.async {
            shared.extractResources(from: livePhoto, completion: completion)
        }
    }
    /// Generates a PHLivePhoto from an image and video.  Also returns the paired image and video.
    @available(iOS 9.1, *)
    public class func generate(from imageURL: URL?, videoURL: URL, progress: @escaping (CGFloat) -> Void, completion: @escaping (PHLivePhoto?, LivePhotoResources?) -> Void) {
        queue.async {
            shared.generate(from: imageURL, videoURL: videoURL, progress: progress, completion: completion)
        }
    }
    /// Save a Live Photo to the Photo Library by passing the paired image and video.
    public class func saveToLibrary(_ resources: LivePhotoResources, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            if #available(iOS 9.1, *) {
                let creationRequest = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                creationRequest.addResource(with: PHAssetResourceType.pairedVideo, fileURL: resources.pairedVideo, options: options)
                creationRequest.addResource(with: PHAssetResourceType.photo, fileURL: resources.pairedImage, options: options)
            } else {
                // Fallback on earlier versions
            }
        }, completionHandler: { (success, error) in
            if error != nil {
                print(error as Any)
            }
            completion(success)
        })
    }
    
    // MARK: PRIVATE
    private static let shared = LivePhoto()
    private static let queue = DispatchQueue(label: "com.limit-point.LivePhotoQueue", attributes: .concurrent)
    lazy private var cacheDirectory: URL? = {
        if let cacheDirectoryURL = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            let fullDirectory = cacheDirectoryURL.appendingPathComponent("com.limit-point.LivePhoto", isDirectory: true)
            if !FileManager.default.fileExists(atPath: fullDirectory.absoluteString) {
                try? FileManager.default.createDirectory(at: fullDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            return fullDirectory
        }
        return nil
    }()
    
    deinit {
        clearCache()
    }
    
    private func generateKeyPhoto(from videoURL: URL) -> URL? {
        var percent:Float = 0.5
        let videoAsset = AVURLAsset(url: videoURL)
        if let stillImageTime = videoAsset.stillImageTime() {
            percent = Float(stillImageTime.value) / Float(videoAsset.duration.value)
        }
        guard let imageFrame = videoAsset.getAssetFrame(percent: percent) else { return nil }
        guard let jpegData = imageFrame.jpegData(compressionQuality: 1.0) else { return nil }
        guard let url = cacheDirectory?.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg") else { return nil }
        do {
            try? jpegData.write(to: url)
            return url
        }
    }
    private func clearCache() {
        if let cacheDirectory = cacheDirectory {
            try? FileManager.default.removeItem(at: cacheDirectory)
        }
    }
    
    @available(iOS 9.1, *)
    private func generate(from imageURL: URL?, videoURL: URL, progress: @escaping (CGFloat) -> Void, completion: @escaping (PHLivePhoto?, LivePhotoResources?) -> Void) {
        guard let cacheDirectory = cacheDirectory else {
            DispatchQueue.main.async {
                completion(nil, nil)
            }
            return
        }
        let assetIdentifier = UUID().uuidString
        let _keyPhotoURL = imageURL ?? generateKeyPhoto(from: videoURL)
        guard let keyPhotoURL = _keyPhotoURL, let pairedImageURL = addAssetID(assetIdentifier, toImage: keyPhotoURL, saveTo: cacheDirectory.appendingPathComponent(assetIdentifier).appendingPathExtension("jpg")) else {
            DispatchQueue.main.async {
                completion(nil, nil)
            }
            return
        }
        addAssetID(assetIdentifier, toVideo: videoURL, saveTo: cacheDirectory.appendingPathComponent(assetIdentifier).appendingPathExtension("mov"), progress: progress) { (_videoURL) in
            if let pairedVideoURL = _videoURL {
                _ = PHLivePhoto.request(withResourceFileURLs: [pairedVideoURL, pairedImageURL], placeholderImage: nil, targetSize: CGSize.zero, contentMode: PHImageContentMode.aspectFit, resultHandler: { (livePhoto: PHLivePhoto?, info: [AnyHashable : Any]) -> Void in
                    if let isDegraded = info[PHLivePhotoInfoIsDegradedKey] as? Bool, isDegraded {
                        return
                    }
                    DispatchQueue.main.async {
                        completion(livePhoto, (pairedImageURL, pairedVideoURL))
                    }
                })
            } else {
                DispatchQueue.main.async {
                    completion(nil, nil)
                }
            }
        }
    }
    
    @available(iOS 9.1, *)
    private func extractResources(from livePhoto: PHLivePhoto, to directoryURL: URL, completion: @escaping (LivePhotoResources?) -> Void) {
        let assetResources = PHAssetResource.assetResources(for: livePhoto)
        let group = DispatchGroup()
        var keyPhotoURL: URL?
        var videoURL: URL?
        for resource in assetResources {
            let buffer = NSMutableData()
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            group.enter()
            PHAssetResourceManager.default().requestData(for: resource, options: options, dataReceivedHandler: { (data) in
                buffer.append(data)
            }) { (error) in
                if error == nil {
                    if resource.type == .pairedVideo {
                        videoURL = self.saveAssetResource(resource, to: directoryURL, resourceData: buffer as Data)
                    } else {
                        keyPhotoURL = self.saveAssetResource(resource, to: directoryURL, resourceData: buffer as Data)
                    }
                } else {
                    print(error as Any)
                }
                group.leave()
            }
        }
        group.notify(queue: DispatchQueue.main) {
            guard let pairedPhotoURL = keyPhotoURL, let pairedVideoURL = videoURL else {
                completion(nil)
                return
            }
            completion((pairedPhotoURL, pairedVideoURL))
        }
    }
    
    @available(iOS 9.1, *)
    private func extractResources(from livePhoto: PHLivePhoto, completion: @escaping (LivePhotoResources?) -> Void) {
        if let cacheDirectory = cacheDirectory {
            extractResources(from: livePhoto, to: cacheDirectory, completion: completion)
        }
    }
    
    @available(iOS 9, *)
    private func saveAssetResource(_ resource: PHAssetResource, to directory: URL, resourceData: Data) -> URL? {
        let fileExtension = UTTypeCopyPreferredTagWithClass(resource.uniformTypeIdentifier as CFString,kUTTagClassFilenameExtension)?.takeRetainedValue()
        
        guard let ext = fileExtension else {
            return nil
        }
        
        var fileUrl = directory.appendingPathComponent(NSUUID().uuidString)
        fileUrl = fileUrl.appendingPathExtension(ext as String)
        
        do {
            try resourceData.write(to: fileUrl, options: [Data.WritingOptions.atomic])
        } catch {
            print("Could not save resource \(resource) to filepath \(String(describing: fileUrl))")
            return nil
        }
        
        return fileUrl
    }
    
    func addAssetID(_ assetIdentifier: String, toImage imageURL: URL, saveTo destinationURL: URL) -> URL? {
        guard let imageDestination = CGImageDestinationCreateWithURL(destinationURL as CFURL, kUTTypeJPEG, 1, nil),
            let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
            var imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [AnyHashable : Any] else { return nil }
        let assetIdentifierKey = "17"
        let assetIdentifierInfo = [assetIdentifierKey : assetIdentifier]
        imageProperties[kCGImagePropertyMakerAppleDictionary] = assetIdentifierInfo
        CGImageDestinationAddImageFromSource(imageDestination, imageSource, 0, imageProperties as CFDictionary)
        CGImageDestinationFinalize(imageDestination)
        return destinationURL
    }
    
    var audioReader: AVAssetReader?
    var videoReader: AVAssetReader?
    var assetWriter: AVAssetWriter?
    
    func addAssetID(_ assetIdentifier: String, toVideo videoURL: URL, saveTo destinationURL: URL, progress: @escaping (CGFloat) -> Void, completion: @escaping (URL?) -> Void) {
        
        var audioWriterInput: AVAssetWriterInput?
        var audioReaderOutput: AVAssetReaderOutput?
        let videoAsset = AVURLAsset(url: videoURL)
        let frameCount = videoAsset.countFrames(exact: false)
        guard let videoTrack = videoAsset.tracks(withMediaType: .video).first else {
            completion(nil)
            return
        }
        do {
            // Create the Asset Writer
            assetWriter = try AVAssetWriter(outputURL: destinationURL, fileType: .mov)
            // Create Video Reader Output
            videoReader = try AVAssetReader(asset: videoAsset)
            let videoReaderSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)]
            let videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)
            videoReader?.add(videoReaderOutput)
            // Create Video Writer Input
            let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: [AVVideoCodecKey : AVVideoCodecH264, AVVideoWidthKey : videoTrack.naturalSize.width, AVVideoHeightKey : videoTrack.naturalSize.height])
            videoWriterInput.transform = videoTrack.preferredTransform
            videoWriterInput.expectsMediaDataInRealTime = true
            assetWriter?.add(videoWriterInput)
            // Create Audio Reader Output & Writer Input
            if let audioTrack = videoAsset.tracks(withMediaType: .audio).first {
                do {
                    let _audioReader = try AVAssetReader(asset: videoAsset)
                    let _audioReaderOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
                    _audioReader.add(_audioReaderOutput)
                    audioReader = _audioReader
                    audioReaderOutput = _audioReaderOutput
                    let _audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
                    _audioWriterInput.expectsMediaDataInRealTime = false
                    assetWriter?.add(_audioWriterInput)
                    audioWriterInput = _audioWriterInput
                } catch {
                    print(error)
                }
            }
            // Create necessary identifier metadata and still image time metadata
            let assetIdentifierMetadata = metadataForAssetID(assetIdentifier)
            let stillImageTimeMetadataAdapter = createMetadataAdaptorForStillImageTime()
            assetWriter?.metadata = [assetIdentifierMetadata]
            assetWriter?.add(stillImageTimeMetadataAdapter.assetWriterInput)
            // Start the Asset Writer
            assetWriter?.startWriting()
            assetWriter?.startSession(atSourceTime: CMTime.zero)
            // Add still image metadata
            let _stillImagePercent: Float = 0.5
            stillImageTimeMetadataAdapter.append(AVTimedMetadataGroup(items: [metadataItemForStillImageTime()],timeRange: videoAsset.makeStillImageTimeRange(percent: _stillImagePercent, inFrameCount: frameCount)))
            // For end of writing / progress
            var writingVideoFinished = false
            var writingAudioFinished = false
            var currentFrameCount = 0
            func didCompleteWriting() {
                guard writingAudioFinished && writingVideoFinished else { return }
                assetWriter?.finishWriting {
                    if self.assetWriter?.status == .completed {
                        completion(destinationURL)
                    } else {
                        completion(nil)
                    }
                }
            }
            // Start writing video
            if videoReader?.startReading() ?? false {
                videoWriterInput.requestMediaDataWhenReady(on: DispatchQueue(label: "videoWriterInputQueue")) {
                    while videoWriterInput.isReadyForMoreMediaData {
                        if let sampleBuffer = videoReaderOutput.copyNextSampleBuffer()  {
                            currentFrameCount += 1
                            let percent:CGFloat = CGFloat(currentFrameCount)/CGFloat(frameCount)
                            progress(percent)
                            if !videoWriterInput.append(sampleBuffer) {
                                print("Cannot write: \(String(describing: self.assetWriter?.error?.localizedDescription))")
                                self.videoReader?.cancelReading()
                            }
                        } else {
                            videoWriterInput.markAsFinished()
                            writingVideoFinished = true
                            didCompleteWriting()
                        }
                    }
                }
            } else {
                writingVideoFinished = true
                didCompleteWriting()
            }
            // Start writing audio
            if audioReader?.startReading() ?? false {
                audioWriterInput?.requestMediaDataWhenReady(on: DispatchQueue(label: "audioWriterInputQueue")) {
                    while audioWriterInput?.isReadyForMoreMediaData ?? false {
                        guard let sampleBuffer = audioReaderOutput?.copyNextSampleBuffer() else {
                            audioWriterInput?.markAsFinished()
                            writingAudioFinished = true
                            didCompleteWriting()
                            return
                        }
                        audioWriterInput?.append(sampleBuffer)
                    }
                }
            } else {
                writingAudioFinished = true
                didCompleteWriting()
            }
        } catch {
            print(error)
            completion(nil)
        }
    }
    
    private func metadataForAssetID(_ assetIdentifier: String) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        let keyContentIdentifier =  "com.apple.quicktime.content.identifier"
        let keySpaceQuickTimeMetadata = "mdta"
        item.key = keyContentIdentifier as (NSCopying & NSObjectProtocol)?
        item.keySpace = AVMetadataKeySpace(rawValue: keySpaceQuickTimeMetadata)
        item.value = assetIdentifier as (NSCopying & NSObjectProtocol)?
        item.dataType = "com.apple.metadata.datatype.UTF-8"
        return item
    }
    
    private func createMetadataAdaptorForStillImageTime() -> AVAssetWriterInputMetadataAdaptor {
        let keyStillImageTime = "com.apple.quicktime.still-image-time"
        let keySpaceQuickTimeMetadata = "mdta"
        let spec : NSDictionary = [
            kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as NSString:
            "\(keySpaceQuickTimeMetadata)/\(keyStillImageTime)",
            kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType as NSString:
            "com.apple.metadata.datatype.int8"            ]
        var desc : CMFormatDescription? = nil
        CMMetadataFormatDescriptionCreateWithMetadataSpecifications(allocator: kCFAllocatorDefault, metadataType: kCMMetadataFormatType_Boxed, metadataSpecifications: [spec] as CFArray, formatDescriptionOut: &desc)
        let input = AVAssetWriterInput(mediaType: .metadata,
                                       outputSettings: nil, sourceFormatHint: desc)
        return AVAssetWriterInputMetadataAdaptor(assetWriterInput: input)
    }
    
    private func metadataItemForStillImageTime() -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        let keyStillImageTime = "com.apple.quicktime.still-image-time"
        let keySpaceQuickTimeMetadata = "mdta"
        item.key = keyStillImageTime as (NSCopying & NSObjectProtocol)?
        item.keySpace = AVMetadataKeySpace(rawValue: keySpaceQuickTimeMetadata)
        item.value = 0 as (NSCopying & NSObjectProtocol)?
        item.dataType = "com.apple.metadata.datatype.int8"
        return item
    }
    
}

fileprivate extension AVAsset {
    func countFrames(exact:Bool) -> Int {
        
        var frameCount = 0
        
        if let videoReader = try? AVAssetReader(asset: self)  {
            
            if let videoTrack = self.tracks(withMediaType: .video).first {
                
                frameCount = Int(CMTimeGetSeconds(self.duration) * Float64(videoTrack.nominalFrameRate))
                
                
                if exact {
                    
                    frameCount = 0
                    
                    let videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: nil)
                    videoReader.add(videoReaderOutput)
                    
                    videoReader.startReading()
                    
                    // count frames
                    while true {
                        let sampleBuffer = videoReaderOutput.copyNextSampleBuffer()
                        if sampleBuffer == nil {
                            break
                        }
                        frameCount += 1
                    }
                    
                    videoReader.cancelReading()
                }
                
                
            }
        }
        
        return frameCount
    }
    
    func stillImageTime() -> CMTime?  {
        
        var stillTime:CMTime? = nil
        
        if let videoReader = try? AVAssetReader(asset: self)  {
            
            if let metadataTrack = self.tracks(withMediaType: .metadata).first {
                
                let videoReaderOutput = AVAssetReaderTrackOutput(track: metadataTrack, outputSettings: nil)
                
                videoReader.add(videoReaderOutput)
                
                videoReader.startReading()
                
                let keyStillImageTime = "com.apple.quicktime.still-image-time"
                let keySpaceQuickTimeMetadata = "mdta"
                
                var found = false
                
                while found == false {
                    if let sampleBuffer = videoReaderOutput.copyNextSampleBuffer() {
                        if CMSampleBufferGetNumSamples(sampleBuffer) != 0 {
                            let group = AVTimedMetadataGroup(sampleBuffer: sampleBuffer)
                            for item in group?.items ?? [] {
                                if item.key as? String == keyStillImageTime && item.keySpace!.rawValue == keySpaceQuickTimeMetadata {
                                    stillTime = group?.timeRange.start
                                    //print("stillImageTime = \(CMTimeGetSeconds(stillTime!))")
                                    found = true
                                    break
                                }
                            }
                        }
                    }
                    else {
                        break;
                    }
                }
                
                videoReader.cancelReading()
                
            }
        }
        
        return stillTime
    }
    
    func makeStillImageTimeRange(percent:Float, inFrameCount:Int = 0) -> CMTimeRange {
        
        var time = self.duration
        
        var frameCount = inFrameCount
        
        if frameCount == 0 {
            frameCount = self.countFrames(exact: true)
        }
        
        let frameDuration = Int64(Float(time.value) / Float(frameCount))
        
        time.value = Int64(Float(time.value) * percent)
        
        //print("stillImageTime = \(CMTimeGetSeconds(time))")
        
        return CMTimeRangeMake(start: time, duration: CMTimeMake(value: frameDuration, timescale: time.timescale))
    }
    
    func getAssetFrame(percent:Float) -> UIImage?
    {
        
        let imageGenerator = AVAssetImageGenerator(asset: self)
        imageGenerator.appliesPreferredTrackTransform = true
        
        imageGenerator.requestedTimeToleranceAfter = CMTimeMake(value: 1,timescale: 100)
        imageGenerator.requestedTimeToleranceBefore = CMTimeMake(value: 1,timescale: 100)
        
        var time = self.duration
        
        time.value = Int64(Float(time.value) * percent)
        
        do {
            var actualTime = CMTime.zero
            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime:&actualTime)
            
            let img = UIImage(cgImage: imageRef)
            
            return img
        }
        catch let error as NSError
        {
            print("Image generation failed with error \(error)")
            return nil
        }
    }
}
