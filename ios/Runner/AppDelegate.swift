import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
  private let channelName = "opencv_channel"
  private let progressChannelName = "opencv_progress_channel"
  private var progressEventSink: FlutterEventSink?
  private var isProgressListenerActive = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let opencvChannel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
    
    // Set up progress event channel
    let progressChannel = FlutterEventChannel(name: progressChannelName, binaryMessenger: controller.binaryMessenger)
    progressChannel.setStreamHandler(self)
    
    // Listen for progress notifications from OpenCVWrapper
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleVideoProcessingProgress(_:)),
      name: NSNotification.Name("VideoProcessingProgress"),
      object: nil
    )

    opencvChannel.setMethodCallHandler { [weak self] (call, result) in
      guard self != nil else { return }
      
      // Handle frame extraction for new algorithm
      if call.method == "extractVideoFrames" {
        guard let args = call.arguments as? [String: Any],
              let inputPath = args["inputPath"] as? String,
              let outputDirectory = args["outputDirectory"] as? String,
              let targetFPS = args["targetFPS"] as? Double else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required arguments for frame extraction", details: nil))
          return
        }
        
        // Run frame extraction on background thread
        DispatchQueue.global(qos: .userInitiated).async {
          let extractionResult = OpenCVWrapper.extractFrames(fromVideo: inputPath, outputDirectory: outputDirectory, targetFPS: Float(targetFPS))
          DispatchQueue.main.async {
            result(extractionResult)
          }
        }
        return
      }
      
      // Handle filter application to existing frames
      if call.method == "applyFilterToFrames" {
        guard let args = call.arguments as? [String: Any],
              let framePaths = args["framePaths"] as? [String],
              let outputPath = args["outputPath"] as? String,
              let filterType = args["filterType"] as? String,
              let frameCount = args["frameCount"] as? Int,
              let duration = args["duration"] as? Double,
              let targetFPS = args["targetFPS"] as? Double else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required arguments for frame filtering", details: nil))
          return
        }
        
        // Run frame filtering on background thread
        DispatchQueue.global(qos: .userInitiated).async {
          let success = OpenCVWrapper.applyFilter(toFrames: framePaths, outputPath: outputPath, filterType: filterType, frameCount: Int32(frameCount), duration: duration, targetFPS: Float(targetFPS))
          DispatchQueue.main.async {
            result(success)
          }
        }
        return
      }
      
      // Handle audio merging with video
      if call.method == "mergeAudioWithVideo" {
        guard let args = call.arguments as? [String: Any],
              let videoPath = args["videoPath"] as? String,
              let audioSourcePath = args["audioSourcePath"] as? String,
              let outputPath = args["outputPath"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required arguments for audio merging", details: nil))
          return
        }
        
        // Run audio merging on background thread
        DispatchQueue.global(qos: .userInitiated).async {
          let success = OpenCVWrapper.mergeAudio(withVideoPath: videoPath, audioSourcePath: audioSourcePath, outputPath: outputPath)
          DispatchQueue.main.async {
            result(success)
          }
        }
        return
      }
      
      // Handle video processing (legacy method for fallback)
      if call.method == "processVideoWithFilter" {
        guard let args = call.arguments as? [String: Any],
              let inputPath = args["inputPath"] as? String,
              let outputPath = args["outputPath"] as? String,
              let filterType = args["filterType"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required arguments", details: nil))
          return
        }
        
        // Run video processing on background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
          let success = OpenCVWrapper.processVideo(withFilter: inputPath, outputPath: outputPath, filterType: filterType)
          DispatchQueue.main.async {
            result(success)
          }
        }
        return
      }
      
      // Handle image processing (requires image bytes)
      if let args = call.arguments as? FlutterStandardTypedData,
         let image = UIImage(data: args.data) {
          
        switch call.method {
case "convertToGrayScale":
  if let grayImage = OpenCVWrapper.convert(toGrayScale: image),
     let grayData = grayImage.pngData() {
    result(FlutterStandardTypedData(bytes: grayData))
  } else {
    result(FlutterError(code: "PROCESSING_FAILED", message: "Failed to convert image", details: nil))
  }
  
case "convertToSketch":
  if let sketchImage = OpenCVWrapper.convert(toSketch: image),
     let sketchData = sketchImage.pngData() {
    result(FlutterStandardTypedData(bytes: sketchData))
  } else {
    result(FlutterError(code: "PROCESSING_FAILED", message: "Failed to convert image to sketch", details: nil))
  }
  
case "convertToCartoon":
  if let cartoonImage = OpenCVWrapper.convert(toCartoon: image),
     let cartoonData = cartoonImage.pngData() {
    result(FlutterStandardTypedData(bytes: cartoonData))
  } else {
    result(FlutterError(code: "PROCESSING_FAILED", message: "Failed to convert image to cartoon", details: nil))
  }

        case "convertToCharcoalSketch":
          if let charcoalImage = OpenCVWrapper.convert(toCharcoalSketch: image),
             let charcoalData = charcoalImage.pngData() {
            result(FlutterStandardTypedData(bytes: charcoalData))
          } else {
            result(FlutterError(code: "PROCESSING_FAILED", message: "Failed to convert image to charcoal sketch", details: nil))
          }

        case "convertToInkPen":
          if let inkImage = OpenCVWrapper.convert(toInkPen: image),
             let inkData = inkImage.pngData() {
            result(FlutterStandardTypedData(bytes: inkData))
          } else {
            result(FlutterError(code: "PROCESSING_FAILED", message: "Failed to convert image to ink pen", details: nil))
          }

        case "convertToColorSketch":
          if let colorImage = OpenCVWrapper.convert(toColorSketch: image),
             let colorData = colorImage.pngData() {
            result(FlutterStandardTypedData(bytes: colorData))
          } else {
            result(FlutterError(code: "PROCESSING_FAILED", message: "Failed to convert image to color sketch", details: nil))
          }

                    case "convertToTechPen":
          if let techImage = OpenCVWrapper.convert(toTechPen: image),
             let techData = techImage.pngData() {
            result(FlutterStandardTypedData(bytes: techData))
          } else {
            result(FlutterError(code: "PROCESSING_FAILED", message: "Failed to convert image to tech pen", details: nil))
          }

        case "convertToSoftPen":
          if let softImage = OpenCVWrapper.convert(toSoftPen: image),
             let softData = softImage.pngData() {
            result(FlutterStandardTypedData(bytes: softData))
          } else {
            result(FlutterError(code: "PROCESSING_FAILED", message: "Failed to convert image to soft pen", details: nil))
          }

        case "convertToNoirSketch":
          if let noirImage = OpenCVWrapper.convert(toNoirSketch: image),
             let noirData = noirImage.pngData() {
            result(FlutterStandardTypedData(bytes: noirData))
          } else {
            result(FlutterError(code: "PROCESSING_FAILED", message: "Failed to convert image to noir sketch", details: nil))
          }

        case "convertToCartoon2":
          if let cartoon2Image = OpenCVWrapper.convert(toCartoon2: image),
             let cartoon2Data = cartoon2Image.pngData() {
            result(FlutterStandardTypedData(bytes: cartoon2Data))
          } else {
            result(FlutterError(code: "PROCESSING_FAILED", message: "Failed to convert image to cartoon2", details: nil))
          }

        case "convertToStoryboard":
          if let storyboardImage = OpenCVWrapper.convert(toStoryboard: image),
             let storyboardData = storyboardImage.pngData() {
            result(FlutterStandardTypedData(bytes: storyboardData))
          } else {
            result(FlutterError(code: "PROCESSING_FAILED", message: "Failed to convert image to storyboard", details: nil))
          }

        case "convertToChalk":
          if let chalkImage = OpenCVWrapper.convert(toChalk: image),
             let chalkData = chalkImage.pngData() {
            result(FlutterStandardTypedData(bytes: chalkData))
          } else {
            result(FlutterError(code: "PROCESSING_FAILED", message: "Failed to convert image to chalk", details: nil))
          }

        case "convertToFeltPen":
          if let feltImage = OpenCVWrapper.convert(toFeltPen: image),
             let feltData = feltImage.pngData() {
            result(FlutterStandardTypedData(bytes: feltData))
          } else {
            result(FlutterError(code: "PROCESSING_FAILED", message: "Failed to convert image to felt pen", details: nil))
          }

        case "convertToMonochromeSketch":
          if let monoImage = OpenCVWrapper.convert(toMonochromeSketch: image),
             let monoData = monoImage.pngData() {
            result(FlutterStandardTypedData(bytes: monoData))
          } else {
            result(FlutterError(code: "PROCESSING_FAILED", message: "Failed to convert image to monochrome sketch", details: nil))
          }

        case "convertToSplashSketch":
          if let splashImage = OpenCVWrapper.convert(toSplashSketch: image),
             let splashData = splashImage.pngData() {
            result(FlutterStandardTypedData(bytes: splashData))
          } else {
            result(FlutterError(code: "PROCESSING_FAILED", message: "Failed to convert image to splash sketch", details: nil))
          }

        case "convertToColoringBook":
          if let coloringImage = OpenCVWrapper.convert(toColoringBook: image),
             let coloringData = coloringImage.pngData() {
            result(FlutterStandardTypedData(bytes: coloringData))
          } else {
            result(FlutterError(code: "PROCESSING_FAILED", message: "Failed to convert image to coloring book", details: nil))
          }

        case "convertToWaxSketch":
          if let waxImage = OpenCVWrapper.convert(toWaxSketch: image),
             let waxData = waxImage.pngData() {
            result(FlutterStandardTypedData(bytes: waxData))
          } else {
            result(FlutterError(code: "PROCESSING_FAILED", message: "Failed to convert image to wax sketch", details: nil))
          }

        case "convertToPaperSketch":
          if let paperImage = OpenCVWrapper.convert(toPaperSketch: image),
             let paperData = paperImage.pngData() {
            result(FlutterStandardTypedData(bytes: paperData))
          } else {
            result(FlutterError(code: "PROCESSING_FAILED", message: "Failed to convert image to paper sketch", details: nil))
          }

        case "convertToNeonSketch":
          if let neonImage = OpenCVWrapper.convert(toNeonSketch: image),
             let neonData = neonImage.pngData() {
            result(FlutterStandardTypedData(bytes: neonData))
          } else {
            result(FlutterError(code: "PROCESSING_FAILED", message: "Failed to convert image to neon sketch", details: nil))
          }

        case "convertToAnime":
          if let animeImage = OpenCVWrapper.convert(toAnime: image),
             let animeData = animeImage.pngData() {
            result(FlutterStandardTypedData(bytes: animeData))
          } else {
            result(FlutterError(code: "PROCESSING_FAILED", message: "Failed to convert image to anime", details: nil))
          }

        case "convertToComicBook":
          if let comicImage = OpenCVWrapper.convert(toComicBook: image),
             let comicData = comicImage.pngData() {
            result(FlutterStandardTypedData(bytes: comicData))
          } else {
            result(FlutterError(code: "PROCESSING_FAILED", message: "Failed to convert image to comic book", details: nil))
          }

  
default:
  result(FlutterMethodNotImplemented)
}

      } else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected image bytes", details: nil))
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // MARK: - FlutterStreamHandler
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    progressEventSink = events
    isProgressListenerActive = true
    return nil
  }
  
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    progressEventSink = nil
    isProgressListenerActive = false
    return nil
  }
  
  // Helper method to send progress updates with disposal checking
  @objc func sendProgressUpdate(progress: Double, status: String) {
    // Only send updates if listener is active and event sink is available
    guard isProgressListenerActive, let eventSink = progressEventSink else {
      NSLog("🚫 Progress update skipped - listener not active or event sink nil")
      return
    }
    
    DispatchQueue.main.async {
      eventSink(["progress": progress, "status": status])
    }
  }
  
  // Handle progress notifications from OpenCVWrapper with disposal checking
  @objc func handleVideoProcessingProgress(_ notification: Notification) {
    // Check if listener is still active before processing
    guard isProgressListenerActive, let eventSink = progressEventSink else {
      NSLog("🚫 Progress notification ignored - listener disposed")
      return
    }
    
    NSLog("🔔 AppDelegate received notification: %@", notification.userInfo ?? [:])
    guard let userInfo = notification.userInfo,
          let progress = userInfo["progress"] as? Double,
          let status = userInfo["status"] as? String else {
      NSLog("❌ Failed to parse progress notification")
      return
    }
    
    NSLog("📲 AppDelegate forwarding progress: %.2f%% - %@", progress * 100, status)
    sendProgressUpdate(progress: progress, status: status)
  }
}
