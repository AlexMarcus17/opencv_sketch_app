package com.alphasoftlabs.sketch

import android.os.Bundle
import android.util.Log
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import org.opencv.android.OpenCVLoader
import org.opencv.core.*
import org.opencv.imgcodecs.Imgcodecs
import org.opencv.imgproc.Imgproc
import kotlin.math.max
import kotlin.math.min
import kotlin.random.Random
import android.media.MediaMetadataRetriever
import android.media.MediaMuxer
import android.media.MediaExtractor
import android.media.MediaFormat
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import kotlinx.coroutines.*
import kotlinx.coroutines.sync.Semaphore
import java.io.File
import java.io.FileOutputStream
import java.io.ByteArrayOutputStream
import java.util.concurrent.TimeUnit
import android.content.res.AssetManager
import java.io.InputStream
import android.media.MediaCodec
import android.media.MediaCodecInfo

class MainActivity : FlutterActivity() {

    private val CHANNEL = "opencv_channel"
    private val PROGRESS_CHANNEL = "opencv_progress_channel"
    private var progressEventSink: EventChannel.EventSink? = null
    private var isProgressListenerActive = false

    // Helper method to send progress updates with disposal checking
    private fun sendProgressUpdate(progress: Double, status: String) {
        // Only send updates if listener is active and event sink is available
        if (!isProgressListenerActive || progressEventSink == null) {
            Log.d("ProgressUpdate", "🚫 Progress update skipped - listener not active or event sink null")
            return
        }
        
        runOnUiThread {
            try {
                progressEventSink?.success(mapOf(
                    "progress" to progress,
                    "status" to status
                ))
            } catch (e: Exception) {
                Log.w("ProgressUpdate", "Failed to send progress update: ${e.message}")
                // Mark as inactive if sending fails (likely disposed)
                isProgressListenerActive = false
                progressEventSink = null
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (!OpenCVLoader.initDebug()) {
            Log.e("OpenCV", "OpenCV initialization failed!")
        } else {
            Log.d("OpenCV", "OpenCV initialization successful!")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up progress event channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, PROGRESS_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    progressEventSink = events
                    isProgressListenerActive = true
                    Log.d("ProgressChannel", "✅ Progress listener activated")
                }

                override fun onCancel(arguments: Any?) {
                    progressEventSink = null
                    isProgressListenerActive = false
                    Log.d("ProgressChannel", "❌ Progress listener cancelled")
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "convertToSketch" -> {
                    val args = call.arguments as? ByteArray
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Argument is null or invalid", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val sketchBytes = convertToSketch(args)
                        result.success(sketchBytes)
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to process image: ${e.message}", null)
                    }
                }
                "convertToCharcoalSketch" -> {
                    val args = call.arguments as? ByteArray
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Argument is null or invalid", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val charcoalBytes = convertToCharcoalSketch(args)
                        result.success(charcoalBytes)
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to process image: ${e.message}", null)
                    }
                }
                "convertToInkPen" -> {
                    val args = call.arguments as? ByteArray
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Argument is null or invalid", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val inkBytes = convertToInkPen(args)
                        result.success(inkBytes)
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to process image: ${e.message}", null)
                    }
                }
                "convertToColorSketch" -> {
                    val args = call.arguments as? ByteArray
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Argument is null or invalid", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val colorBytes = convertToColorSketch(args)
                        result.success(colorBytes)
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to process image: ${e.message}", null)
                    }
                }
                "convertToCartoon" -> {
                    val args = call.arguments as? ByteArray
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Argument is null or invalid", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val cartoonBytes = convertToCartoon(args)
                        result.success(cartoonBytes)
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to process image: ${e.message}", null)
                    }
                }
                "convertToTechPen" -> {
                    val args = call.arguments as? ByteArray
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Argument is null or invalid", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val techBytes = convertToTechPen(args)
                        result.success(techBytes)
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to process image: ${e.message}", null)
                    }
                }
                "convertToSoftPen" -> {
                    val args = call.arguments as? ByteArray
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Argument is null or invalid", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val softBytes = convertToSoftPen(args)
                        result.success(softBytes)
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to process image: ${e.message}", null)
                    }
                }
                "convertToNoirSketch" -> {
                    val args = call.arguments as? ByteArray
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Argument is null or invalid", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val noirBytes = convertToNoirSketch(args)
                        result.success(noirBytes)
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to process image: ${e.message}", null)
                    }
                }
                "convertToCartoon2" -> {
                    val args = call.arguments as? ByteArray
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Argument is null or invalid", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val cartoon2Bytes = convertToCartoon2(args)
                        result.success(cartoon2Bytes)
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to process image: ${e.message}", null)
                    }
                }
                "convertToStoryboard" -> {
                    val args = call.arguments as? ByteArray
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Argument is null or invalid", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val storyboardBytes = convertToStoryboard(args)
                        result.success(storyboardBytes)
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to process image: ${e.message}", null)
                    }
                }
                "convertToChalk" -> {
                    val args = call.arguments as? ByteArray
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Argument is null or invalid", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val chalkBytes = convertToChalk(args)
                        result.success(chalkBytes)
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to process image: ${e.message}", null)
                    }
                }
                "convertToFeltPen" -> {
                    val args = call.arguments as? ByteArray
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Argument is null or invalid", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val feltBytes = convertToFeltPen(args)
                        result.success(feltBytes)
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to process image: ${e.message}", null)
                    }
                }
                "convertToMonochromeSketch" -> {
                    val args = call.arguments as? ByteArray
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Argument is null or invalid", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val monoBytes = convertToMonochromeSketch(args)
                        result.success(monoBytes)
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to process image: ${e.message}", null)
                    }
                }
                "convertToSplashSketch" -> {
                    val args = call.arguments as? ByteArray
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Argument is null or invalid", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val splashBytes = convertToSplashSketch(args)
                        result.success(splashBytes)
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to process image: ${e.message}", null)
                    }
                }
                "convertToColoringBook" -> {
                    val args = call.arguments as? ByteArray
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Argument is null or invalid", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val coloringBytes = convertToColoringBook(args)
                        result.success(coloringBytes)
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to process image: ${e.message}", null)
                    }
                }
                "convertToWaxSketch" -> {
                    val args = call.arguments as? ByteArray
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Argument is null or invalid", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val waxBytes = convertToWaxSketch(args)
                        result.success(waxBytes)
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to process image: ${e.message}", null)
                    }
                }
                "convertToPaperSketch" -> {
                    val args = call.arguments as? ByteArray
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Argument is null or invalid", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val paperBytes = convertToPaperSketch(args)
                        result.success(paperBytes)
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to process image: ${e.message}", null)
                    }
                }
                "convertToNeonSketch" -> {
                    val args = call.arguments as? ByteArray
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Argument is null or invalid", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val neonBytes = convertToNeonSketch(args)
                        result.success(neonBytes)
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to process image: ${e.message}", null)
                    }
                }
                "convertToAnime" -> {
                    val args = call.arguments as? ByteArray
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Argument is null or invalid", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val animeBytes = convertToAnime(args)
                        result.success(animeBytes)
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to process image: ${e.message}", null)
                    }
                }
                "convertToComicBook" -> {
                    val args = call.arguments as? ByteArray
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Argument is null or invalid", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val comicBytes = convertToComicBook(args)
                        result.success(comicBytes)
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to process image: ${e.message}", null)
                    }
                }
                // Frame extraction for new algorithm
                "extractVideoFrames" -> {
                    val args = call.arguments as? Map<String, Any>
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Arguments are null or invalid", null)
                        return@setMethodCallHandler
                    }
                    
                    val inputPath = args["inputPath"] as? String
                    val outputDirectory = args["outputDirectory"] as? String
                    val targetFPS = args["targetFPS"] as? Double
                    
                    if (inputPath == null || outputDirectory == null || targetFPS == null) {
                        result.error("INVALID_ARGUMENT", "Missing required arguments for frame extraction", null)
                        return@setMethodCallHandler
                    }
                    
                    try {
                        CoroutineScope(Dispatchers.IO).launch {
                            val extractionResult = extractVideoFrames(inputPath, outputDirectory, targetFPS.toFloat())
                            runOnUiThread {
                                result.success(extractionResult)
                            }
                        }
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to extract frames: ${e.message}", null)
                    }
                    return@setMethodCallHandler
                }
                
                // Filter application to existing frames
                "applyFilterToFrames" -> {
                    val args = call.arguments as? Map<String, Any>
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Arguments are null or invalid", null)
                        return@setMethodCallHandler
                    }
                    
                    val framePaths = args["framePaths"] as? List<String>
                    val outputPath = args["outputPath"] as? String
                    val filterType = args["filterType"] as? String
                    val frameCount = args["frameCount"] as? Int
                    val duration = args["duration"] as? Double
                    val targetFPS = args["targetFPS"] as? Double
                    
                    if (framePaths == null || outputPath == null || filterType == null || 
                        frameCount == null || duration == null || targetFPS == null) {
                        result.error("INVALID_ARGUMENT", "Missing required arguments for frame filtering", null)
                        return@setMethodCallHandler
                    }
                    
                    try {
                        CoroutineScope(Dispatchers.IO).launch {
                            val success = applyFilterToFrames(framePaths, outputPath, filterType, frameCount, duration, targetFPS.toFloat())
                            runOnUiThread {
                                result.success(success)
                            }
                        }
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to apply filter to frames: ${e.message}", null)
                    }
                    return@setMethodCallHandler
                }

                // Video processing with frame-by-frame filtering (legacy method for fallback)
                "processVideoWithFilter" -> {
                    val args = call.arguments as? Map<String, Any>
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Arguments are null or invalid", null)
                        return@setMethodCallHandler
                    }
                    
                    val inputPath = args["inputPath"] as? String
                    val outputPath = args["outputPath"] as? String
                    val filterType = args["filterType"] as? String
                    
                    if (inputPath == null || outputPath == null || filterType == null) {
                        result.error("INVALID_ARGUMENT", "Missing required arguments", null)
                        return@setMethodCallHandler
                    }
                    
                    try {
                        CoroutineScope(Dispatchers.IO).launch {
                            val success = processVideoWithFilter(inputPath, outputPath, filterType)
                            runOnUiThread {
                                result.success(success)
                            }
                        }
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to process video: ${e.message}", null)
                    }
                    return@setMethodCallHandler
                }

                "mergeAudioWithVideo" -> {
                    val args = call.arguments as? Map<String, Any>
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Arguments are null or invalid", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val videoPath = args["videoPath"] as? String
                        val audioSourcePath = args["audioSourcePath"] as? String
                        val outputPath = args["outputPath"] as? String

                        if (videoPath == null || audioSourcePath == null || outputPath == null) {
                            result.error("INVALID_ARGUMENT", "Missing required arguments", null)
                            return@setMethodCallHandler
                        }

                        CoroutineScope(Dispatchers.IO).launch {
                            try {
                                Log.d("MainActivity", "🎵 Android mergeAudioWithVideo called")
                                sendProgressUpdate(0.9, "Merging audio with video...")
                                val success = mergeAudioWithVideo(videoPath, audioSourcePath, outputPath)
                                
                                runOnUiThread {
                                    if (success) {
                                        sendProgressUpdate(1.0, "Audio merging complete!")
                                    } else {
                                        sendProgressUpdate(0.0, "Audio merging failed")
                                    }
                                    result.success(success)
                                }
                            } catch (e: Exception) {
                                Log.e("MainActivity", "❌ Error in mergeAudioWithVideo: ${e.message}", e)
                                runOnUiThread {
                                    result.error("AUDIO_MERGE_FAILED", "Failed to merge audio: ${e.message}", null)
                                }
                            }
                        }
                    } catch (e: Exception) {
                        result.error("AUDIO_MERGE_FAILED", "Failed to merge audio: ${e.message}", null)
                    }
                    return@setMethodCallHandler
                }

                // Legacy video processing method that calls new algorithm
                "processVideoWithFilter" -> {
                    val args = call.arguments as? Map<String, Any>
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Arguments are null or invalid", null)
                        return@setMethodCallHandler
                    }
                    
                    val inputPath = args["inputPath"] as? String
                    val outputPath = args["outputPath"] as? String
                    val filterType = args["filterType"] as? String
                    
                    if (inputPath == null || outputPath == null || filterType == null) {
                        result.error("INVALID_ARGUMENT", "Missing required arguments", null)
                        return@setMethodCallHandler
                    }
                    
                    try {
                        CoroutineScope(Dispatchers.IO).launch {
                            try {
                                Log.d("MainActivity", "🎬 Android processVideoWithFilter called")
                                sendProgressUpdate(0.0, "Preparing video processing...")
                                val success = processVideoWithFilter(inputPath, outputPath, filterType)
                                
                                runOnUiThread {
                                    if (success) {
                                        sendProgressUpdate(1.0, "Video processing complete!")
                                    } else {
                                        sendProgressUpdate(0.0, "Video processing failed")
                                    }
                                    result.success(success)
                                }
                            } catch (e: Exception) {
                                Log.e("MainActivity", "❌ Error in processVideoWithFilter: ${e.message}", e)
                                runOnUiThread {
                                    result.error("PROCESSING_FAILED", "Failed to process video: ${e.message}", null)
                                }
                            }
                        }
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to process video: ${e.message}", null)
                    }
                    return@setMethodCallHandler
                }

                "OLD_mergeAudioWithVideo" -> {
                    val args = call.arguments as? Map<String, Any>
                    if (args == null) {
                        result.error("INVALID_ARGUMENT", "Arguments are null or invalid", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val videoPath = args["videoPath"] as? String
                        val audioSourcePath = args["audioSourcePath"] as? String
                        val outputPath = args["outputPath"] as? String

                        if (videoPath == null || audioSourcePath == null || outputPath == null) {
                            result.error("INVALID_ARGUMENT", "Missing required arguments", null)
                            return@setMethodCallHandler
                        }

                        CoroutineScope(Dispatchers.IO).launch {
                            try {
                                val success = mergeAudioWithVideo(videoPath, audioSourcePath, outputPath)
                                runOnUiThread {
                                    result.success(success)
                                }
                            } catch (e: Exception) {
                                runOnUiThread {
                                    result.error("PROCESSING_FAILED", "Failed to merge audio: ${e.message}", null)
                                }
                            }
                        }
                    } catch (e: Exception) {
                        result.error("PROCESSING_FAILED", "Failed to merge audio: ${e.message}", null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun convertToSketch(imageBytes: ByteArray): ByteArray {
        val mat = Imgcodecs.imdecode(MatOfByte(*imageBytes), Imgcodecs.IMREAD_COLOR)
        if (mat == null || mat.empty()) {
            throw Exception("Failed to decode image bytes - src is empty")
        }
        val sketchMat = createSketch(mat)
        val matOfByte = MatOfByte()
        Imgcodecs.imencode(".png", sketchMat, matOfByte)
        return matOfByte.toArray()
    }

    private fun convertToCharcoalSketch(imageBytes: ByteArray): ByteArray {
        val mat = Imgcodecs.imdecode(MatOfByte(*imageBytes), Imgcodecs.IMREAD_COLOR)
            ?: throw Exception("Failed to decode image bytes")
        val charcoalMat = createCharcoalSketch(mat)
        val matOfByte = MatOfByte()
        Imgcodecs.imencode(".png", charcoalMat, matOfByte)
        return matOfByte.toArray()
    }

    private fun convertToInkPen(imageBytes: ByteArray): ByteArray {
        val mat = Imgcodecs.imdecode(MatOfByte(*imageBytes), Imgcodecs.IMREAD_COLOR)
            ?: throw Exception("Failed to decode image bytes")
        val inkMat = createInkPen(mat)
        val matOfByte = MatOfByte()
        Imgcodecs.imencode(".png", inkMat, matOfByte)
        return matOfByte.toArray()
    }

    private fun convertToColorSketch(imageBytes: ByteArray): ByteArray {
        val mat = Imgcodecs.imdecode(MatOfByte(*imageBytes), Imgcodecs.IMREAD_COLOR)
            ?: throw Exception("Failed to decode image bytes")
        val colorMat = createColorSketch(mat)
        val matOfByte = MatOfByte()
        Imgcodecs.imencode(".png", colorMat, matOfByte)
        return matOfByte.toArray()
    }

    private fun convertToCartoon(imageBytes: ByteArray): ByteArray {
        val mat = Imgcodecs.imdecode(MatOfByte(*imageBytes), Imgcodecs.IMREAD_COLOR)
            ?: throw Exception("Failed to decode image bytes")
        val cartoonMat = createCartoon(mat)
        val matOfByte = MatOfByte()
        Imgcodecs.imencode(".png", cartoonMat, matOfByte)
        return matOfByte.toArray()
    }

    private fun convertToTechPen(imageBytes: ByteArray): ByteArray {
        val mat = Imgcodecs.imdecode(MatOfByte(*imageBytes), Imgcodecs.IMREAD_COLOR)
            ?: throw Exception("Failed to decode image bytes")
        val techMat = createTechPen(mat)
        val matOfByte = MatOfByte()
        Imgcodecs.imencode(".png", techMat, matOfByte)
        return matOfByte.toArray()
    }

    private fun convertToSoftPen(imageBytes: ByteArray): ByteArray {
        val mat = Imgcodecs.imdecode(MatOfByte(*imageBytes), Imgcodecs.IMREAD_COLOR)
            ?: throw Exception("Failed to decode image bytes")
        val softMat = createSoftPen(mat)
        val matOfByte = MatOfByte()
        Imgcodecs.imencode(".png", softMat, matOfByte)
        return matOfByte.toArray()
    }

    private fun convertToNoirSketch(imageBytes: ByteArray): ByteArray {
        val mat = Imgcodecs.imdecode(MatOfByte(*imageBytes), Imgcodecs.IMREAD_COLOR)
            ?: throw Exception("Failed to decode image bytes")
        val noirMat = createNoirSketch(mat)
        val matOfByte = MatOfByte()
        Imgcodecs.imencode(".png", noirMat, matOfByte)
        return matOfByte.toArray()
    }

    private fun convertToCartoon2(imageBytes: ByteArray): ByteArray {
        val mat = Imgcodecs.imdecode(MatOfByte(*imageBytes), Imgcodecs.IMREAD_COLOR)
            ?: throw Exception("Failed to decode image bytes")
        val cartoon2Mat = createCartoon2(mat)
        val matOfByte = MatOfByte()
        Imgcodecs.imencode(".png", cartoon2Mat, matOfByte)
        return matOfByte.toArray()
    }

    private fun convertToStoryboard(imageBytes: ByteArray): ByteArray {
        val mat = Imgcodecs.imdecode(MatOfByte(*imageBytes), Imgcodecs.IMREAD_COLOR)
            ?: throw Exception("Failed to decode image bytes")
        val storyboardMat = createStoryboard(mat)
        val matOfByte = MatOfByte()
        Imgcodecs.imencode(".png", storyboardMat, matOfByte)
        return matOfByte.toArray()
    }

    private fun convertToChalk(imageBytes: ByteArray): ByteArray {
        val mat = Imgcodecs.imdecode(MatOfByte(*imageBytes), Imgcodecs.IMREAD_COLOR)
            ?: throw Exception("Failed to decode image bytes")
        val chalkMat = createChalk(mat)
        val matOfByte = MatOfByte()
        Imgcodecs.imencode(".png", chalkMat, matOfByte)
        return matOfByte.toArray()
    }

    private fun convertToFeltPen(imageBytes: ByteArray): ByteArray {
        val mat = Imgcodecs.imdecode(MatOfByte(*imageBytes), Imgcodecs.IMREAD_COLOR)
            ?: throw Exception("Failed to decode image bytes")
        val feltMat = createFeltPen(mat)
        val matOfByte = MatOfByte()
        Imgcodecs.imencode(".png", feltMat, matOfByte)
        return matOfByte.toArray()
    }

    private fun convertToMonochromeSketch(imageBytes: ByteArray): ByteArray {
        val mat = Imgcodecs.imdecode(MatOfByte(*imageBytes), Imgcodecs.IMREAD_COLOR)
            ?: throw Exception("Failed to decode image bytes")
        val monoMat = createMonochromeSketch(mat)
        val matOfByte = MatOfByte()
        Imgcodecs.imencode(".png", monoMat, matOfByte)
        return matOfByte.toArray()
    }

    private fun convertToSplashSketch(imageBytes: ByteArray): ByteArray {
        val mat = Imgcodecs.imdecode(MatOfByte(*imageBytes), Imgcodecs.IMREAD_COLOR)
            ?: throw Exception("Failed to decode image bytes")
        val splashMat = createSplashSketch(mat)
        val matOfByte = MatOfByte()
        Imgcodecs.imencode(".png", splashMat, matOfByte)
        return matOfByte.toArray()
    }

    private fun convertToColoringBook(imageBytes: ByteArray): ByteArray {
        val mat = Imgcodecs.imdecode(MatOfByte(*imageBytes), Imgcodecs.IMREAD_COLOR)
            ?: throw Exception("Failed to decode image bytes")
        val coloringMat = createColoringBook(mat)
        val matOfByte = MatOfByte()
        Imgcodecs.imencode(".png", coloringMat, matOfByte)
        return matOfByte.toArray()
    }

    private fun convertToWaxSketch(imageBytes: ByteArray): ByteArray {
        val mat = Imgcodecs.imdecode(MatOfByte(*imageBytes), Imgcodecs.IMREAD_COLOR)
            ?: throw Exception("Failed to decode image bytes")
        val waxMat = createWaxSketch(mat)
        val matOfByte = MatOfByte()
        Imgcodecs.imencode(".png", waxMat, matOfByte)
        return matOfByte.toArray()
    }

    private fun convertToPaperSketch(imageBytes: ByteArray): ByteArray {
        val mat = Imgcodecs.imdecode(MatOfByte(*imageBytes), Imgcodecs.IMREAD_COLOR)
            ?: throw Exception("Failed to decode image bytes")
        val paperMat = createPaperSketch(mat)
        val matOfByte = MatOfByte()
        Imgcodecs.imencode(".png", paperMat, matOfByte)
        return matOfByte.toArray()
    }

    private fun convertToNeonSketch(imageBytes: ByteArray): ByteArray {
        val mat = Imgcodecs.imdecode(MatOfByte(*imageBytes), Imgcodecs.IMREAD_COLOR)
            ?: throw Exception("Failed to decode image bytes")
        val neonMat = createNeonSketch(mat)
        val matOfByte = MatOfByte()
        Imgcodecs.imencode(".png", neonMat, matOfByte)
        return matOfByte.toArray()
    }

    private fun convertToAnime(imageBytes: ByteArray): ByteArray {
        val mat = Imgcodecs.imdecode(MatOfByte(*imageBytes), Imgcodecs.IMREAD_COLOR)
            ?: throw Exception("Failed to decode image bytes")
        val animeMat = createAnime(mat)
        val matOfByte = MatOfByte()
        Imgcodecs.imencode(".png", animeMat, matOfByte)
        return matOfByte.toArray()
    }

    private fun convertToComicBook(imageBytes: ByteArray): ByteArray {
        val mat = Imgcodecs.imdecode(MatOfByte(*imageBytes), Imgcodecs.IMREAD_COLOR)
            ?: throw Exception("Failed to decode image bytes")
        val comicMat = createComicBook(mat)
        val matOfByte = MatOfByte()
        Imgcodecs.imencode(".png", comicMat, matOfByte)
        return matOfByte.toArray()
    }

    // Filter implementation methods - Updated to mirror iOS implementations exactly
    private fun createSketch(src: Mat): Mat {
        if (src.empty()) {
            Log.e("OpenCV", "Input image is empty")
            return src.clone()
        }

        // Convert to grayscale - mirror iOS implementation exactly
        val gray = Mat()
        var srcBGR = Mat()
        if (src.channels() == 4) {
            Imgproc.cvtColor(src, srcBGR, Imgproc.COLOR_BGRA2BGR)
        } else {
            srcBGR = src.clone()
        }
        Imgproc.cvtColor(srcBGR, gray, Imgproc.COLOR_BGR2GRAY)

        // Invert grayscale - mirror iOS: Mat invGray = 255 - gray;
        val invGray = Mat()
        Core.subtract(Mat(gray.size(), gray.type(), Scalar(255.0)), gray, invGray)

        // Heavy Gaussian blur on inverted image - mirror iOS: Size(101, 101)
        val blurImg = Mat()
        Imgproc.GaussianBlur(invGray, blurImg, Size(101.0, 101.0), 0.0)

        // Invert the blurred image - mirror iOS: Mat invBlur = 255 - blurImg;
        val invBlur = Mat()
        Core.subtract(Mat(blurImg.size(), blurImg.type(), Scalar(255.0)), blurImg, invBlur)

        // Create sketch by dividing gray by invBlur, scale=255.0 - mirror iOS exactly
        val sketchImg = Mat()
        Core.divide(gray, invBlur, sketchImg, 255.0)

        return sketchImg
    }

    private fun createCharcoalSketch(src: Mat): Mat {
        if (src.empty()) {
            Log.e("OpenCV", "Input image is empty")
            return src.clone()
        }

        var srcBGR = Mat()
        if (src.channels() == 4) {
            Imgproc.cvtColor(src, srcBGR, Imgproc.COLOR_BGRA2BGR)
        } else {
            srcBGR = src.clone()
        }

        // Grayscale - mirror iOS implementation
        val gray = Mat()
        Imgproc.cvtColor(srcBGR, gray, Imgproc.COLOR_BGR2GRAY)

        // Gaussian Blur - mirror iOS: Size(5, 5), 2
        val blur = Mat()
        Imgproc.GaussianBlur(gray, blur, Size(5.0, 5.0), 2.0)

        // Sobel gradients - mirror iOS implementation exactly
        val sobelX = Mat()
        val sobelY = Mat()
        Imgproc.Sobel(blur, sobelX, CvType.CV_64F, 1, 0, 5)
        Imgproc.Sobel(blur, sobelY, CvType.CV_64F, 0, 1, 5)

        // Gradient magnitude: sqrt(sobelX^2 + sobelY^2) - mirror iOS
        val sobelXSq = Mat()
        val sobelYSq = Mat()
        Core.multiply(sobelX, sobelX, sobelXSq)
        Core.multiply(sobelY, sobelY, sobelYSq)
        val gradMagSq = Mat()
        Core.add(sobelXSq, sobelYSq, gradMagSq)

        val gradMag = Mat()
        Core.sqrt(gradMagSq, gradMag)

        // Convert to 8U - mirror iOS
        val gradMag8U = Mat()
        gradMag.convertTo(gradMag8U, CvType.CV_8U)

        // Invert - mirror iOS: Mat gradMagInv = 255 - gradMag8U;
        val gradMagInv = Mat()
        Core.subtract(Mat(gradMag8U.size(), gradMag8U.type(), Scalar(255.0)), gradMag8U, gradMagInv)

        // Threshold - mirror iOS: threshold 10
        val threshImg = Mat()
        Imgproc.threshold(gradMagInv, threshImg, 10.0, 255.0, Imgproc.THRESH_BINARY)

        return threshImg
    }

    private fun createInkPen(src: Mat): Mat {
        val gray = Mat()
        val edges = Mat()
        val ink = Mat()

        Imgproc.cvtColor(src, gray, Imgproc.COLOR_BGR2GRAY)
        
        // Apply bilateral filter to preserve edges - mirror iOS
        val filtered = Mat()
        Imgproc.bilateralFilter(gray, filtered, 9, 80.0, 80.0)
        
        // Use multiple edge detection techniques and combine - mirror iOS
        val canny = Mat()
        val sobel = Mat()
        
        // Canny edges - mirror iOS: 30, 90
        Imgproc.Canny(filtered, canny, 30.0, 90.0)
        
        // Sobel edges for additional detail - mirror iOS
        val sobelX = Mat()
        val sobelY = Mat()
        Imgproc.Sobel(filtered, sobelX, CvType.CV_64F, 1, 0, 3)
        Imgproc.Sobel(filtered, sobelY, CvType.CV_64F, 0, 1, 3)
        Core.magnitude(sobelX, sobelY, sobel)
        sobel.convertTo(sobel, CvType.CV_8U)
        Imgproc.threshold(sobel, sobel, 50.0, 255.0, Imgproc.THRESH_BINARY)
        
        // Combine both edge maps - mirror iOS
        Core.bitwise_or(canny, sobel, edges)
        Core.bitwise_not(edges, ink)

        return ink
    }

    private fun createColorSketch(src: Mat): Mat {
        if (src.empty()) {
            Log.e("OpenCV", "Input image is empty")
            return src.clone()
        }

        var srcBGR = Mat()
        if (src.channels() == 4) {
            Imgproc.cvtColor(src, srcBGR, Imgproc.COLOR_BGRA2BGR)
        } else {
            srcBGR = src.clone()
        }

        // Mirror iOS implementation using pencilSketch equivalent
        // Since Android OpenCV doesn't have pencilSketch, we'll simulate it
        val dstGray = Mat()
        val dstColor = Mat()
        
        // Apply bilateral filter for smoothing
        val smoothed = Mat()
        Imgproc.bilateralFilter(srcBGR, smoothed, 60, 0.07 * 255, 0.05 * 255)
        
        // Create edges
        val gray = Mat()
        Imgproc.cvtColor(srcBGR, gray, Imgproc.COLOR_BGR2GRAY)
        val edges = Mat()
        Imgproc.adaptiveThreshold(gray, edges, 255.0, Imgproc.ADAPTIVE_THRESH_MEAN_C, Imgproc.THRESH_BINARY, 9, 10.0)
        
        // Convert edges to color
        val edgesColor = Mat()
        Imgproc.cvtColor(edges, edgesColor, Imgproc.COLOR_GRAY2BGR)
        
        // Combine smoothed image with edges
        Core.bitwise_and(smoothed, edgesColor, dstColor)

        return dstColor
    }

    private fun createCartoon(src: Mat): Mat {
        if (src.empty()) {
            Log.e("OpenCV", "Input image is empty")
            return src.clone()
        }

        var srcBGR = Mat()
        if (src.channels() == 4) {
            Imgproc.cvtColor(src, srcBGR, Imgproc.COLOR_BGRA2BGR)
        } else {
            srcBGR = src.clone()
        }

        val color = Mat()
        val gray = Mat()
        val edges = Mat()
        val dst = Mat()

        // Mirror iOS implementation exactly
        Imgproc.bilateralFilter(srcBGR, color, 9, 75.0, 75.0)
        Imgproc.cvtColor(srcBGR, gray, Imgproc.COLOR_BGR2GRAY)
        Imgproc.medianBlur(gray, gray, 7)
        Imgproc.adaptiveThreshold(gray, edges, 255.0, Imgproc.ADAPTIVE_THRESH_MEAN_C, Imgproc.THRESH_BINARY, 9, 2.0)
        Imgproc.cvtColor(edges, edges, Imgproc.COLOR_GRAY2BGR)
        Core.bitwise_and(color, edges, dst)

        return dst
    }

    private fun createTechPen(src: Mat): Mat {
        if (src.empty()) {
            Log.e("OpenCV", "Input image is empty")
            return src.clone()
        }
        
        var srcBGR = Mat()
        if (src.channels() == 4) {
            Imgproc.cvtColor(src, srcBGR, Imgproc.COLOR_BGRA2BGR)
        } else {
            srcBGR = src.clone()
        }

        val color = Mat()
        val gray = Mat()
        val edges = Mat()
        val dst = Mat()

        // Mirror iOS implementation exactly
        Imgproc.bilateralFilter(srcBGR, color, 9, 75.0, 75.0)
        Imgproc.cvtColor(srcBGR, gray, Imgproc.COLOR_BGR2GRAY)
        Imgproc.medianBlur(gray, gray, 7)
        Imgproc.adaptiveThreshold(gray, edges, 255.0, Imgproc.ADAPTIVE_THRESH_MEAN_C, Imgproc.THRESH_BINARY, 9, 2.0)
        Imgproc.cvtColor(edges, edges, Imgproc.COLOR_GRAY2BGR)
        Core.bitwise_and(color, edges, dst)

        // Mirror iOS: Boost red channel by 60%, clamp max to 255
        val channels = mutableListOf<Mat>()
        Core.split(dst, channels)
        Core.multiply(channels[2], Scalar(1.6), channels[2]) // Red channel
        Core.min(channels[2], Scalar(255.0), channels[2])
        Core.merge(channels, dst)

        return dst
    }

    private fun createSoftPen(src: Mat): Mat {
        val gray = Mat()
        val invGray = Mat()
        val blur = Mat()
        val soft = Mat()

        Imgproc.cvtColor(src, gray, Imgproc.COLOR_BGR2GRAY)
        Core.bitwise_not(gray, invGray)
        Imgproc.GaussianBlur(invGray, blur, Size(25.0, 25.0), 0.0)
        
        // Mirror iOS: divide(gray, 255 - blur, soft, 256)
        val divisor = Mat()
        Core.subtract(Mat(blur.size(), blur.type(), Scalar(255.0)), blur, divisor)
        Core.divide(gray, divisor, soft, 256.0)
        
        // Additional softening - mirror iOS
        Imgproc.GaussianBlur(soft, soft, Size(3.0, 3.0), 0.0)

        return soft
    }

    private fun createNoirSketch(src: Mat): Mat {
        val gray = Mat()
        val noir = Mat()

        Imgproc.cvtColor(src, gray, Imgproc.COLOR_BGR2GRAY)
        
        // Mirror iOS: High contrast for noir effect (2.0, -50)
        gray.convertTo(noir, -1, 2.0, -50.0)
        
        // Mirror iOS: Apply threshold for dramatic effect
        Imgproc.threshold(noir, noir, 127.0, 255.0, Imgproc.THRESH_BINARY)

        return noir
    }

    private fun createCartoon2(src: Mat): Mat {
        if (src.empty()) {
            Log.e("OpenCV", "Input image is empty")
            return src.clone()
        }

        var srcBGR = Mat()
        if (src.channels() == 4) {
            Imgproc.cvtColor(src, srcBGR, Imgproc.COLOR_BGRA2BGR)
        } else {
            srcBGR = src.clone()
        }

        val color = Mat()
        val gray = Mat()
        val edges = Mat()
        val dst = Mat()

        // Mirror iOS implementation exactly
        Imgproc.bilateralFilter(srcBGR, color, 9, 75.0, 75.0)
        Imgproc.cvtColor(srcBGR, gray, Imgproc.COLOR_BGR2GRAY)
        
        // Mirror iOS: medianBlur with 45 (much larger than original)
        Imgproc.medianBlur(gray, gray, 45)
        
        Imgproc.adaptiveThreshold(gray, edges, 255.0, Imgproc.ADAPTIVE_THRESH_MEAN_C, Imgproc.THRESH_BINARY, 9, 2.0)
        Imgproc.cvtColor(edges, edges, Imgproc.COLOR_GRAY2BGR)
        Core.bitwise_and(color, edges, dst)

        // Mirror iOS: Boost red channel by 3x and green channel by 3x, clamp max to 255
        val channels = mutableListOf<Mat>()
        Core.split(dst, channels)
        Core.multiply(channels[2], Scalar(3.0), channels[2]) // Red channel
        Core.multiply(channels[1], Scalar(3.0), channels[1]) // Green channel
        Core.min(channels[2], Scalar(255.0), channels[2])
        Core.min(channels[1], Scalar(255.0), channels[1])
        Core.merge(channels, dst)

        return dst
    }

    private fun createStoryboard(src: Mat): Mat {
        return try {
            if (src.empty()) {
                Log.e("OpenCV", "Input image is empty for storyboard filter")
                return src.clone()
            }
            
            // Ensure proper color space - mirror iOS
            var srcBGR = Mat()
            if (src.channels() == 4) {
                Imgproc.cvtColor(src, srcBGR, Imgproc.COLOR_BGRA2BGR)
            } else {
                srcBGR = src.clone()
            }
            
            val gray = Mat()
            val edges = Mat()
            val storyboard = Mat()

            // Convert to grayscale - mirror iOS
            Imgproc.cvtColor(srcBGR, gray, Imgproc.COLOR_BGR2GRAY)
            
            // Apply histogram equalization for better contrast - mirror iOS
            Imgproc.equalizeHist(gray, gray)
            
            // Reduce noise while preserving edges - mirror iOS
            val denoised = Mat()
            Imgproc.bilateralFilter(gray, denoised, 9, 80.0, 80.0)
            
            // Create edges for storyboard outline effect - mirror iOS
            val edges1 = Mat()
            Imgproc.adaptiveThreshold(denoised, edges1, 255.0, 
                Imgproc.ADAPTIVE_THRESH_MEAN_C, Imgproc.THRESH_BINARY, 9, 10.0)
            
            // Invert edges so lines are black on white background - mirror iOS
            Core.bitwise_not(edges1, edges)
            
            // Create shading zones based on intensity levels - mirror iOS
            val shading = Mat()
            gray.copyTo(shading)
            
            // Create multiple intensity levels for sketch-like shading - mirror iOS
            val level1 = Mat()
            val level2 = Mat()
            val level3 = Mat()
            Imgproc.threshold(shading, level1, 200.0, 255.0, Imgproc.THRESH_BINARY)  // Highlights
            Imgproc.threshold(shading, level2, 120.0, 180.0, Imgproc.THRESH_BINARY)  // Mid-tones  
            Imgproc.threshold(shading, level3, 60.0, 120.0, Imgproc.THRESH_BINARY)   // Shadows
            
            // Combine shading levels - mirror iOS
            val shadingZones = Mat()
            Core.add(level1, level2, shadingZones)
            Core.add(shadingZones, level3, shadingZones)
            
            // Combine edges with shading using OR operation (not AND) - mirror iOS
            Core.bitwise_or(edges, shadingZones, storyboard)
            
            // Convert back to BGR for consistency - mirror iOS
            val result = Mat()
            Imgproc.cvtColor(storyboard, result, Imgproc.COLOR_GRAY2BGR)
            
            result
        } catch (e: Exception) {
            Log.e("OpenCV", "Exception in storyboard filter: ${e.message}", e)
            // Return a simple edge-detected version as fallback - mirror iOS
            try {
                val gray = Mat()
                val edges = Mat()
                Imgproc.cvtColor(src, gray, Imgproc.COLOR_BGR2GRAY)
                Imgproc.Canny(gray, edges, 50.0, 150.0)
                Core.bitwise_not(edges, edges) // Invert so lines are black
                val result = Mat()
                Imgproc.cvtColor(edges, result, Imgproc.COLOR_GRAY2BGR)
                result
            } catch (e2: Exception) {
                Log.e("OpenCV", "Even fallback failed: ${e2.message}")
                src.clone()
            }
        }
    }

    private fun createChalk(src: Mat): Mat {
        val gray = Mat()
        val inverted = Mat()
        val chalk = Mat()

        Imgproc.cvtColor(src, gray, Imgproc.COLOR_BGR2GRAY)
        
        // Invert for chalk on blackboard effect - mirror iOS
        Core.bitwise_not(gray, inverted)
        
        // Add texture-like noise - mirror iOS: randu(noise, 0, 50)
        val noise = Mat.zeros(inverted.size(), CvType.CV_8UC1)
        val random = Random.Default
        for (i in 0 until noise.rows()) {
            for (j in 0 until noise.cols()) {
                noise.put(i, j, random.nextInt(50).toDouble())
            }
        }
        Core.add(inverted, noise, chalk)

        return chalk
    }

    private fun createFeltPen(src: Mat): Mat {
        return try {
            if (src.empty()) {
                Log.e("OpenCV", "Input image is empty for felt pen filter")
                return src.clone()
            }
            
            // Ensure proper color space - mirror iOS
            var srcBGR = Mat()
            if (src.channels() == 4) {
                Imgproc.cvtColor(src, srcBGR, Imgproc.COLOR_BGRA2BGR)
            } else {
                srcBGR = src.clone()
            }

            val color = Mat()
            val gray = Mat()
            val edges = Mat()
            val dst = Mat()

            // Mirror iOS implementation exactly
            Imgproc.bilateralFilter(srcBGR, color, 9, 75.0, 75.0)
            Imgproc.cvtColor(srcBGR, gray, Imgproc.COLOR_BGR2GRAY)
            
            // Mirror iOS: medianBlur with 29
            Imgproc.medianBlur(gray, gray, 29)
            
            Imgproc.adaptiveThreshold(gray, edges, 255.0, Imgproc.ADAPTIVE_THRESH_MEAN_C, Imgproc.THRESH_BINARY, 9, 2.0)
            Imgproc.cvtColor(edges, edges, Imgproc.COLOR_GRAY2BGR)
            Core.bitwise_and(color, edges, dst)

            // Mirror iOS: Boost red channel by 2.2x and green by 2x, clamp max to 255
            val channels = mutableListOf<Mat>()
            Core.split(dst, channels)
            Core.multiply(channels[2], Scalar(2.2), channels[2]) // Red channel
            Core.multiply(channels[1], Scalar(2.0), channels[1]) // Green channel
            Core.min(channels[2], Scalar(255.0), channels[2])
            Core.min(channels[1], Scalar(255.0), channels[1])
            Core.merge(channels, dst)

            dst
        } catch (e: Exception) {
            Log.e("OpenCV", "Exception in felt pen filter: ${e.message}")
            src.clone()
        }
    }

    private fun createMonochromeSketch(src: Mat): Mat {
        if (src.empty()) {
            Log.e("OpenCV", "Input image is empty")
            return src.clone()
        }
        
        var srcBGR = Mat()
        if (src.channels() == 4) {
            Imgproc.cvtColor(src, srcBGR, Imgproc.COLOR_BGRA2BGR)
        } else {
            srcBGR = src.clone()
        }

        val color = Mat()
        val gray = Mat()
        val edges = Mat()
        val dst = Mat()

        // Mirror iOS implementation exactly
        Imgproc.bilateralFilter(srcBGR, color, 9, 75.0, 75.0)
        Imgproc.cvtColor(srcBGR, gray, Imgproc.COLOR_BGR2GRAY)
        Imgproc.medianBlur(gray, gray, 7)
        Imgproc.adaptiveThreshold(gray, edges, 255.0, Imgproc.ADAPTIVE_THRESH_MEAN_C, Imgproc.THRESH_BINARY, 9, 2.0)
        Imgproc.cvtColor(edges, edges, Imgproc.COLOR_GRAY2BGR)
        Core.bitwise_and(color, edges, dst)

        // Mirror iOS: Boost green channel by 1.6x, clamp max to 255
        val channels = mutableListOf<Mat>()
        Core.split(dst, channels)
        Core.multiply(channels[1], Scalar(1.6), channels[1]) // Green channel
        Core.min(channels[1], Scalar(255.0), channels[1])
        Core.merge(channels, dst)

        return dst
    }

    private fun createSplashSketch(src: Mat): Mat {
        if (src.empty()) {
            Log.e("OpenCV", "Input image is empty")
            return src.clone()
        }
        
        var srcBGR = Mat()
        if (src.channels() == 4) {
            Imgproc.cvtColor(src, srcBGR, Imgproc.COLOR_BGRA2BGR)
        } else {
            srcBGR = src.clone()
        }

        val color = Mat()
        val gray = Mat()
        val edges = Mat()
        val dst = Mat()

        // Mirror iOS implementation exactly
        Imgproc.bilateralFilter(srcBGR, color, 9, 75.0, 75.0)
        Imgproc.cvtColor(srcBGR, gray, Imgproc.COLOR_BGR2GRAY)
        Imgproc.medianBlur(gray, gray, 7)
        Imgproc.adaptiveThreshold(gray, edges, 255.0, Imgproc.ADAPTIVE_THRESH_MEAN_C, Imgproc.THRESH_BINARY, 9, 2.0)
        Imgproc.cvtColor(edges, edges, Imgproc.COLOR_GRAY2BGR)
        Core.bitwise_and(color, edges, dst)

        // Mirror iOS: Boost blue channel by 1.6x, clamp max to 255
        val channels = mutableListOf<Mat>()
        Core.split(dst, channels)
        Core.multiply(channels[0], Scalar(1.6), channels[0]) // Blue channel
        Core.min(channels[0], Scalar(255.0), channels[0])
        Core.merge(channels, dst)

        return dst
    }

    private fun createColoringBook(src: Mat): Mat {
        val gray = Mat()
        val edges = Mat()
        val coloring = Mat()

        Imgproc.cvtColor(src, gray, Imgproc.COLOR_BGR2GRAY)
        
        // Mirror iOS: Strong edge detection for coloring book outlines
        Imgproc.Canny(gray, edges, 50.0, 150.0)
        
        // Mirror iOS: Dilate edges to make them thicker
        val kernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, Size(2.0, 2.0))
        Imgproc.dilate(edges, edges, kernel)
        
        Core.bitwise_not(edges, coloring)

        return coloring
    }

    private fun createWaxSketch(src: Mat): Mat {
        val gray = Mat()
        val edges = Mat()
        val ink = Mat()

        Imgproc.cvtColor(src, gray, Imgproc.COLOR_BGR2GRAY)
        
        // Apply bilateral filter to preserve edges - mirror iOS
        val filtered = Mat()
        Imgproc.bilateralFilter(gray, filtered, 9, 80.0, 80.0)
        
        // Use multiple edge detection techniques and combine - mirror iOS
        val canny = Mat()
        val sobel = Mat()
        
        // Canny edges - mirror iOS
        Imgproc.Canny(filtered, canny, 30.0, 90.0)
        
        // Sobel edges for additional detail - mirror iOS
        val sobelX = Mat()
        val sobelY = Mat()
        Imgproc.Sobel(filtered, sobelX, CvType.CV_64F, 1, 0, 3)
        Imgproc.Sobel(filtered, sobelY, CvType.CV_64F, 0, 1, 3)
        Core.magnitude(sobelX, sobelY, sobel)
        sobel.convertTo(sobel, CvType.CV_8U)
        Imgproc.threshold(sobel, sobel, 50.0, 255.0, Imgproc.THRESH_BINARY)
        
        // Combine both edge maps - mirror iOS
        Core.bitwise_or(canny, sobel, edges)
        Core.bitwise_not(edges, ink)

        return ink
    }

    private fun createPaperSketch(src: Mat): Mat {
        if (src.empty()) {
            Log.e("OpenCV", "Input image is empty")
            return src.clone()
        }

        // Convert BGRA to BGR if needed - mirror iOS
        var srcBGR = Mat()
        if (src.channels() == 4) {
            Imgproc.cvtColor(src, srcBGR, Imgproc.COLOR_BGRA2BGR)
        } else {
            srcBGR = src.clone()
        }

        // Convert to grayscale - mirror iOS
        val gray = Mat()
        Imgproc.cvtColor(srcBGR, gray, Imgproc.COLOR_BGR2GRAY)

        // Median blur to smooth and reduce noise - mirror iOS
        val blurred = Mat()
        Imgproc.medianBlur(gray, blurred, 7)

        // Adaptive threshold to extract sketch-like edges - mirror iOS
        val edges = Mat()
        Imgproc.adaptiveThreshold(
            blurred, edges, 255.0,
            Imgproc.ADAPTIVE_THRESH_MEAN_C, Imgproc.THRESH_BINARY,
            9, 2.0
        )

        // Invert edges to make lines black on white - mirror iOS
        Core.bitwise_not(edges, edges)

        // Optional: Thicken lines via dilation - mirror iOS
        val kernel = Mat.ones(Size(2.0, 2.0), CvType.CV_8U)
        val dilated = Mat()
        Imgproc.dilate(edges, dilated, kernel, Point(-1.0, -1.0), 1)

        return dilated
    }

    private fun createNeonSketch(src: Mat): Mat {
        if (src.empty()) return src.clone()

        // Convert BGRA to BGR if needed - mirror iOS
        var srcBGR = Mat()
        if (src.channels() == 4) {
            Imgproc.cvtColor(src, srcBGR, Imgproc.COLOR_BGRA2BGR)
        } else {
            srcBGR = src.clone()
        }

        // Resize down for performance - mirror iOS
        val small = Mat()
        Imgproc.resize(srcBGR, small, Size(), 0.5, 0.5, Imgproc.INTER_LINEAR)

        // Ensure correct type (CV_8UC3) - mirror iOS
        if (small.type() != CvType.CV_8UC3) {
            small.convertTo(small, CvType.CV_8UC3)
        }

        // Apply bilateral filter twice for strong smoothing - mirror iOS
        val bilateral1 = Mat()
        val bilateral2 = Mat()
        Imgproc.bilateralFilter(small, bilateral1, 9, 75.0, 75.0)
        Imgproc.bilateralFilter(bilateral1, bilateral2, 9, 75.0, 75.0)

        // Resize smoothed image back to original size - mirror iOS
        val smooth = Mat()
        Imgproc.resize(bilateral2, smooth, srcBGR.size(), 0.0, 0.0, Imgproc.INTER_LINEAR)

        // Edge detection with adaptive threshold - mirror iOS
        val gray = Mat()
        val edges = Mat()
        Imgproc.cvtColor(srcBGR, gray, Imgproc.COLOR_BGR2GRAY)
        Imgproc.medianBlur(gray, gray, 7)
        Imgproc.adaptiveThreshold(gray, edges, 255.0, Imgproc.ADAPTIVE_THRESH_MEAN_C, Imgproc.THRESH_BINARY, 9, 2.0)
        Core.bitwise_not(edges, edges)  // Make lines black on white

        // Convert edge mask to 3-channel - mirror iOS
        val edgesColor = Mat()
        Imgproc.cvtColor(edges, edgesColor, Imgproc.COLOR_GRAY2BGR)

        // Blend edges with smoothed image - mirror iOS
        val smoothFloat = Mat()
        val edgesFloat = Mat()
        val blended = Mat()
        smooth.convertTo(smoothFloat, CvType.CV_32F, 1.0 / 255.0)
        edgesColor.convertTo(edgesFloat, CvType.CV_32F, 1.0 / 255.0)
        Core.multiply(smoothFloat, edgesFloat, blended)
        
        val finalResult = Mat()
        blended.convertTo(finalResult, CvType.CV_8U, 255.0)

        return finalResult
    }

    private fun createAnime(src: Mat): Mat {
        if (src.empty()) {
            Log.e("OpenCV", "Input image is empty")
            return src.clone()
        }

        var srcBGR = Mat()
        if (src.channels() == 4) {
            Imgproc.cvtColor(src, srcBGR, Imgproc.COLOR_BGRA2BGR)
        } else {
            srcBGR = src.clone()
        }

        try {
            val color = Mat()
            val gray = Mat()
            val edges = Mat()
            val anime = Mat()

            // Strong bilateral filter to smooth colors - mirror iOS
            Imgproc.bilateralFilter(srcBGR, color, 15, 200.0, 200.0)
            
            // Apply additional bilateral filtering for stronger color reduction
            val colorReduced = Mat()
            Imgproc.bilateralFilter(color, colorReduced, 15, 300.0, 300.0)

            // Create edge mask - mirror iOS
            Imgproc.cvtColor(srcBGR, gray, Imgproc.COLOR_BGR2GRAY)
            Imgproc.adaptiveThreshold(gray, edges, 255.0, Imgproc.ADAPTIVE_THRESH_MEAN_C, Imgproc.THRESH_BINARY, 9, 9.0)
            Imgproc.cvtColor(edges, edges, Imgproc.COLOR_GRAY2BGR)

            // Combine edges with color-reduced image - mirror iOS
            Core.bitwise_and(colorReduced, edges, anime)

            return anime
            
        } catch (e: Exception) {
            Log.e("OpenCV", "Error in anime filter: ${e.message}", e)
            // Fallback to a simple cartoon-like effect
            try {
                val color = Mat()
                val gray = Mat()
                val edges = Mat()
                val fallback = Mat()

                Imgproc.bilateralFilter(srcBGR, color, 9, 75.0, 75.0)
                Imgproc.cvtColor(srcBGR, gray, Imgproc.COLOR_BGR2GRAY)
                Imgproc.medianBlur(gray, gray, 7)
                Imgproc.adaptiveThreshold(gray, edges, 255.0, Imgproc.ADAPTIVE_THRESH_MEAN_C, Imgproc.THRESH_BINARY, 9, 9.0)
                Imgproc.cvtColor(edges, edges, Imgproc.COLOR_GRAY2BGR)
                Core.bitwise_and(color, edges, fallback)

                return fallback
            } catch (e2: Exception) {
                Log.e("OpenCV", "Fallback anime filter also failed: ${e2.message}")
                return srcBGR.clone()
            }
        }
    }

    private fun createComicBook(src: Mat): Mat {
        if (src.empty()) {
            Log.e("OpenCV", "Input image is empty")
            return src.clone()
        }
        
        var srcBGR = Mat()
        if (src.channels() == 4) {
            Imgproc.cvtColor(src, srcBGR, Imgproc.COLOR_BGRA2BGR)
        } else {
            srcBGR = src.clone()
        }

        val color = Mat()
        val gray = Mat()
        val edges = Mat()
        val dst = Mat()

        // Mirror iOS implementation exactly
        Imgproc.bilateralFilter(srcBGR, color, 9, 75.0, 75.0)
        Imgproc.cvtColor(srcBGR, gray, Imgproc.COLOR_BGR2GRAY)
        
        // Mirror iOS: medianBlur with 61 (much larger)
        Imgproc.medianBlur(gray, gray, 61)
        
        Imgproc.adaptiveThreshold(gray, edges, 255.0, Imgproc.ADAPTIVE_THRESH_MEAN_C, Imgproc.THRESH_BINARY, 9, 2.0)
        Imgproc.cvtColor(edges, edges, Imgproc.COLOR_GRAY2BGR)
        Core.bitwise_and(color, edges, dst)

        // Mirror iOS: Boost red channel by 1.6x and blue by 1.45x, clamp max to 255
        val channels = mutableListOf<Mat>()
        Core.split(dst, channels)
        Core.multiply(channels[2], Scalar(1.6), channels[2]) // Red channel
        Core.multiply(channels[0], Scalar(1.45), channels[0]) // Blue channel
        Core.min(channels[2], Scalar(255.0), channels[2])
        Core.min(channels[0], Scalar(255.0), channels[0])
        Core.merge(channels, dst)

        return dst
    }

    // Optimized frame extraction using MediaExtractor for better performance
    private fun extractVideoFrames(inputPath: String, outputDirectory: String, targetFPS: Float): Map<String, Any>? {
        return try {
            Log.d("VideoProcessing", "🎬 Starting optimized frame extraction: $inputPath -> $outputDirectory at ${targetFPS} FPS")
            
            // Check if input file exists
            val inputFile = File(inputPath)
            if (!inputFile.exists()) {
                Log.e("VideoProcessing", "❌ Input video file not found: $inputPath")
                return null
            }
            
            // Create output directory if it doesn't exist
            val outputDir = File(outputDirectory)
            outputDir.mkdirs()
            
            val extractor = MediaExtractor()
            var retriever: MediaMetadataRetriever? = null
            
            return try {
                extractor.setDataSource(inputPath)
                retriever = MediaMetadataRetriever()
                retriever.setDataSource(inputPath)
                
                // Get video track
                var videoTrackIndex = -1
                var videoFormat: MediaFormat? = null
                
                for (i in 0 until extractor.trackCount) {
                    val format = extractor.getTrackFormat(i)
                    val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
                    if (mime.startsWith("video/")) {
                        videoTrackIndex = i
                        videoFormat = format
                        break
                    }
                }
                
                if (videoTrackIndex == -1 || videoFormat == null) {
                    Log.e("VideoProcessing", "❌ No video track found")
                    return null
                }
                
                // Get video properties from retriever (more reliable for metadata)
                val durationString = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                val duration = durationString?.toLongOrNull() ?: 0L
                val durationSeconds = duration / 1000.0
                
                val widthString = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
                val heightString = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
                val width = widthString?.toIntOrNull() ?: 0
                val height = heightString?.toIntOrNull() ?: 0
                
                val frameRateString = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_CAPTURE_FRAMERATE)
                val originalFrameRate = frameRateString?.toFloatOrNull() ?: 30.0f
                
                Log.d("VideoProcessing", "📊 Video properties: ${durationSeconds} seconds, ${width}x${height}, original FPS: ${originalFrameRate}")
                
                if (duration == 0L || width == 0 || height == 0) {
                    Log.e("VideoProcessing", "❌ Invalid video metadata")
                    return null
                }
                
                // Calculate frame extraction parameters
                val frameInterval = 1.0f / targetFPS
                val totalFrames = (durationSeconds * targetFPS).toInt()
                
                Log.d("VideoProcessing", "🎯 Extracting $totalFrames frames at ${targetFPS} FPS (1 frame every ${frameInterval} seconds)")
                
                // Extract frames using optimized batch approach
                val framePaths = mutableListOf<String>()
                var successCount = 0
                
                // Send initial progress for frame extraction
                sendProgressUpdate(0.0, "Extracting video frames...")
                
                // Use coroutines for concurrent frame extraction
                runBlocking {
                    val semaphore = Semaphore(4) // Allow 4 concurrent extractions
                    val jobs = mutableListOf<Deferred<String?>>()
                    
                    for (frameIndex in 0 until totalFrames) {
                        val job = async(Dispatchers.IO) {
                            semaphore.acquire()
                            try {
                                // Calculate time for this frame
                                val frameTimeMs = frameIndex * frameInterval * 1000
                                val frameTimeUs = (frameTimeMs * 1000).toLong()
                                
                                // Use retriever for actual frame extraction (but in parallel)
                                val localRetriever = MediaMetadataRetriever()
                                localRetriever.setDataSource(inputPath)
                                
                                val bitmap = localRetriever.getFrameAtTime(frameTimeUs, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                                localRetriever.release()
                                
                                if (bitmap != null) {
                                    // Save frame as JPEG with optimized compression
                                    val framePath = File(outputDir, "frame_${String.format("%06d", frameIndex)}.jpg")
                                    val outputStream = FileOutputStream(framePath)
                                    bitmap.compress(Bitmap.CompressFormat.JPEG, 85, outputStream)
                                    outputStream.close()
                                    bitmap.recycle()
                                    
                                    synchronized(this@MainActivity) {
                                        successCount++
                                        
                                        // Send progress updates every 3 frames
                                        if (successCount % 3 == 0) {
                                            val progress = successCount.toDouble() / totalFrames * 0.3 // Frame extraction is 30% of total
                                            val percentage = (progress * 100 * 3.33).toInt() // Convert to extraction percentage
                                            Log.d("VideoProcessing", "📸 Extracted $successCount/$totalFrames frames ($percentage%)")
                                            sendProgressUpdate(progress, "Extracting frames... $percentage%")
                                        }
                                    }
                                    
                                    return@async framePath.absolutePath
                                }
                                null
                            } catch (e: Exception) {
                                Log.w("VideoProcessing", "⚠️ Failed to extract frame $frameIndex: ${e.message}")
                                null
                            } finally {
                                semaphore.release()
                            }
                        }
                        jobs.add(job)
                    }
                    
                    // Wait for all extractions and collect results
                    val results = jobs.awaitAll()
                    framePaths.addAll(results.filterNotNull())
                }
                
                Log.d("VideoProcessing", "✅ Optimized frame extraction completed: ${framePaths.size}/$totalFrames frames successful")
                
                // Send completion progress for frame extraction
                sendProgressUpdate(0.3, "Frame extraction complete!")
                
                if (framePaths.isEmpty()) {
                    Log.e("VideoProcessing", "❌ No frames were extracted successfully")
                    return null
                }
                
                // Return extraction results
                mapOf(
                    "framePaths" to framePaths,
                    "frameCount" to framePaths.size,
                    "duration" to durationSeconds,
                    "fps" to originalFrameRate,
                    "targetFPS" to targetFPS
                )
                
            } finally {
                extractor.release()
                retriever?.release()
            }
            
        } catch (e: Exception) {
            Log.e("VideoProcessing", "❌ Exception during optimized frame extraction: ${e.message}", e)
            null
        }
    }

    // Apply filter to frames and create video (matching iOS implementation)
    private fun applyFilterToFrames(framePaths: List<String>, outputPath: String, filterType: String, 
                                  frameCount: Int, duration: Double, targetFPS: Float): Boolean {
        return try {
            Log.d("VideoProcessing", "🎬 Starting filter application to $frameCount frames")
            Log.d("VideoProcessing", "🎯 Filter: $filterType, Output: $outputPath")
            Log.d("VideoProcessing", "⏱️ Duration: ${duration}s, Target FPS: ${targetFPS}")
            
            // Send initial progress
            sendProgressUpdate(0.0, "Preparing video processing...")
            
            // CRITICAL FIX: Check if output video already exists
            val outputFile = File(outputPath)
            if (outputFile.exists()) {
                Log.d("VideoProcessing", "✅ Filtered video already exists, using existing file: $outputPath")
                return true // File already exists, no need to process again
            }
            
            if (framePaths.isEmpty()) {
                Log.e("VideoProcessing", "❌ No frame paths provided")
                return false
            }
            
            // Clean up any existing temporary files first
            val tempBaseName = "filtered_frames"
            cacheDir.listFiles()?.forEach { file ->
                if (file.name.startsWith(tempBaseName)) {
                    file.deleteRecursively()
                }
            }
            
            // Create fresh temporary directory for processed frames
            val tempDir = File(cacheDir, "filtered_frames_${System.currentTimeMillis()}_${Thread.currentThread().id}")
            val processedFramesDir = File(tempDir, "processed")
            processedFramesDir.mkdirs()
            
            // Process each frame with the filter
            val processedFramePaths = mutableListOf<String>()
            var successCount = 0
            
            runBlocking {
                val semaphore = Semaphore(2) // Reduced concurrent processing for stability
                val jobs = mutableListOf<Deferred<String?>>()
                
                framePaths.forEachIndexed { index, inputFramePath ->
                    val job = async(Dispatchers.Default) {
                        semaphore.acquire()
                        try {
                            // Load frame image
                            val bitmap = BitmapFactory.decodeFile(inputFramePath)
                            if (bitmap != null) {
                                // Convert to OpenCV Mat
                                val stream = ByteArrayOutputStream()
                                bitmap.compress(Bitmap.CompressFormat.JPEG, 90, stream)
                                val frameBytes = stream.toByteArray()
                                
                                val frameMat = Imgcodecs.imdecode(MatOfByte(*frameBytes), Imgcodecs.IMREAD_COLOR)
                                if (!frameMat.empty()) {
                                    // Apply filter with texture overlay
                                    val filteredMat = applyFilterToMatWithTexture(frameMat, filterType)
                                    
                                    if (!filteredMat.empty()) {
                                        // Save processed frame
                                        val outputFramePath = File(processedFramesDir, "filtered_${String.format("%06d", index)}.jpg")
                                        val matOfByte = MatOfByte()
                                        Imgcodecs.imencode(".jpg", filteredMat, matOfByte, 
                                            MatOfInt(Imgcodecs.IMWRITE_JPEG_QUALITY, 30)) // Reduced to 30% quality for ultra-maximum speed
                                        outputFramePath.writeBytes(matOfByte.toArray())
                                        
                                        synchronized(this@MainActivity) {
                                            successCount++
                                            val progress = successCount.toDouble() / framePaths.size * 0.8 // 80% for frame processing
                                            val percentage = (progress * 100).toInt()
                                            
                                            if (successCount % 3 == 0) { // Log and update progress every 3 frames
                                                Log.d("VideoProcessing", "🎨 Processed $successCount/${framePaths.size} frames ($percentage%)")
                                                sendProgressUpdate(progress, "Processing frames... $percentage%")
                                            }
                                        }
                                        
                                        return@async outputFramePath.absolutePath
                                    }
                                }
                                bitmap.recycle()
                            }
                            null
                        } catch (e: Exception) {
                            Log.w("VideoProcessing", "⚠️ Failed to process frame $index, using original: ${e.message}")
                            // Fallback: copy original frame
                            try {
                                val fallbackPath = File(processedFramesDir, "filtered_${String.format("%06d", index)}.jpg")
                                File(inputFramePath).copyTo(fallbackPath, overwrite = true)
                                return@async fallbackPath.absolutePath
                            } catch (copyError: Exception) {
                                Log.e("VideoProcessing", "Failed to copy original frame: ${copyError.message}")
                                null
                            }
                        } finally {
                            semaphore.release()
                        }
                    }
                    jobs.add(job)
                }
                
                // Wait for all frame processing
                val results = jobs.awaitAll()
                processedFramePaths.addAll(results.filterNotNull())
            }
            
            Log.d("VideoProcessing", "✅ Filter application completed: $successCount/${framePaths.size} frames processed")
            
            if (processedFramePaths.isEmpty()) {
                Log.e("VideoProcessing", "❌ No frames were processed successfully")
                return false
            }
            
            // Send progress update for video creation phase
            sendProgressUpdate(0.8, "Creating video from processed frames...")
            
            // Create video from processed frames
            val videoCreated = createVideoFromFrames(processedFramePaths, outputPath, duration, targetFPS)
            
            // Cleanup temporary files - ensure cleanup even on errors
            try {
                tempDir.deleteRecursively()
                Log.d("VideoProcessing", "Cleaned up temporary directory: ${tempDir.name}")
            } catch (cleanupError: Exception) {
                Log.w("VideoProcessing", "Warning: Failed to clean up temp directory: ${cleanupError.message}")
            }
            
            if (videoCreated) {
                Log.d("VideoProcessing", "✅ Video creation completed successfully: $outputPath")
                sendProgressUpdate(1.0, "Video processing complete!")
            } else {
                Log.e("VideoProcessing", "❌ Video creation failed")
                sendProgressUpdate(0.0, "Video processing failed")
            }
            
            videoCreated
            
        } catch (e: Exception) {
            Log.e("VideoProcessing", "❌ Exception during filter application: ${e.message}", e)
            
            // Emergency cleanup on exception
            try {
                val tempBaseName = "filtered_frames"
                cacheDir.listFiles()?.forEach { file ->
                    if (file.name.startsWith(tempBaseName)) {
                        file.deleteRecursively()
                    }
                }
            } catch (cleanupError: Exception) {
                Log.w("VideoProcessing", "Failed to clean up after exception: ${cleanupError.message}")
            }
            
            false
        }
    }

    // Video processing with proper frame extraction and duration preservation (matching iOS implementation)
    private fun processVideoWithFilter(inputPath: String, outputPath: String, filterType: String): Boolean {
        return try {
            Log.d("VideoProcessing", "🎬 Android processVideoWithFilter called")
            Log.d("VideoProcessing", "Starting optimized video processing: $inputPath -> $outputPath with filter: $filterType")
            
            // Send initial progress
            Log.d("VideoProcessing", "📤 Sending initial progress from processVideoWithFilter...")
            sendProgressUpdate(0.0, "Preparing video processing...")
            
            // SMART FIX: If filtered video already exists, just use it directly to avoid conflicts
            val outputFile = File(outputPath)
            if (outputFile.exists()) {
                Log.d("VideoProcessing", "✅ Filtered video already exists, using existing file: $outputPath")
                return true // File already exists, no need to process again
            }
            
            val inputFile = File(inputPath)
            if (!inputFile.exists()) {
                Log.e("VideoProcessing", "Input video file not found: $inputPath")
                return false
            }
            
            val retriever = MediaMetadataRetriever()
            
            try {
                retriever.setDataSource(inputPath)
                
                // Get video metadata
                val durationString = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                val duration = durationString?.toLongOrNull() ?: 0L
                val durationSeconds = duration / 1000.0
                
                val widthString = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
                val heightString = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
                val width = widthString?.toIntOrNull() ?: 0
                val height = heightString?.toIntOrNull() ?: 0
                
                val frameRateString = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_CAPTURE_FRAMERATE)
                val originalFrameRate = frameRateString?.toFloatOrNull() ?: 30.0f
                
                Log.d("VideoProcessing", "Video metadata: ${duration}ms (${durationSeconds}s), ${width}x${height}, ${originalFrameRate}fps")
                
                if (duration == 0L || width == 0 || height == 0) {
                    Log.e("VideoProcessing", "Invalid video metadata")
                    return false
                }
                
                // Use ultra-low frame rate for maximum speed
                val targetFPS = 3.0f // Reduced to 3 FPS for ultra-maximum speed
                val frameIntervalMs = 1000.0 / targetFPS
                val totalFrames = (durationSeconds * targetFPS).toInt()
                
                Log.d("VideoProcessing", "Processing $totalFrames frames at ${targetFPS} FPS (interval: ${frameIntervalMs}ms) - ultra-low FPS for maximum speed")
                
                // Compression settings - ultra-low resolution for maximum speed
                val maxDimension = 240 // Reduced to ~240p for ultra-maximum speed
                var compressedWidth = width
                var compressedHeight = height
                
                if (width > maxDimension || height > maxDimension) {
                    val scale = maxDimension.toDouble() / maxOf(width, height)
                    compressedWidth = (width * scale).toInt()
                    compressedHeight = (height * scale).toInt()
                    // Ensure even dimensions for video encoding
                    compressedWidth = (compressedWidth / 2) * 2
                    compressedHeight = (compressedHeight / 2) * 2
                }
                
                Log.d("VideoProcessing", "Compressed frame size: ${compressedWidth}x${compressedHeight}")
                
                // Clean up any existing video processing temp files
                val videoProcessingBaseName = "video_processing"
                cacheDir.listFiles()?.forEach { file ->
                    if (file.name.startsWith(videoProcessingBaseName)) {
                        file.deleteRecursively()
                    }
                }
                
                // Create fresh temporary directory for processed frames
                val tempDir = File(cacheDir, "video_processing_${System.currentTimeMillis()}_${Thread.currentThread().id}")
                val processedFramesDir = File(tempDir, "processed_frames")
                processedFramesDir.mkdirs()
                
                val processedFramePaths = mutableListOf<String>()
                var successCount = 0
                
                // Process frames using coroutines with proper timing
                runBlocking {
                    val semaphore = Semaphore(2) // Reduced concurrent processing for stability
                    val jobs = mutableListOf<Deferred<String?>>()
                    
                    for (frameIndex in 0 until totalFrames) {
                        val job = async(Dispatchers.Default) {
                            semaphore.acquire()
                            try {
                                // Calculate exact time for this frame to maintain duration
                                val frameTimeMs = frameIndex * frameIntervalMs
                                val frameTimeUs = (frameTimeMs * 1000).toLong()
                                
                                val bitmap = retriever.getFrameAtTime(frameTimeUs, MediaMetadataRetriever.OPTION_CLOSEST)
                                if (bitmap != null) {
                                    // Compress frame while maintaining aspect ratio
                                    val compressedBitmap = if (compressedWidth != width || compressedHeight != height) {
                                        Bitmap.createScaledBitmap(bitmap, compressedWidth, compressedHeight, true)
                                    } else {
                                        bitmap
                                    }
                                    
                                    // Convert bitmap to OpenCV Mat with ultra-low quality for speed
                                    val stream = ByteArrayOutputStream()
                                    compressedBitmap.compress(Bitmap.CompressFormat.JPEG, 30, stream) // Reduced to 30% quality for ultra-maximum speed
                                    val frameBytes = stream.toByteArray()
                                    
                                    val mat = Imgcodecs.imdecode(MatOfByte(*frameBytes), Imgcodecs.IMREAD_COLOR)
                                    if (!mat.empty()) {
                                        // Apply filter
                                        val filteredMat = applyFilterToMat(mat, filterType)
                                        
                                        if (!filteredMat.empty()) {
                                            // Save processed frame with ultra-low compression for speed
                                            val matOfByte = MatOfByte()
                                            Imgcodecs.imencode(".jpg", filteredMat, matOfByte, 
                                                MatOfInt(Imgcodecs.IMWRITE_JPEG_QUALITY, 30)) // Reduced to 30% quality for ultra-maximum speed
                                            
                                            val framePath = File(processedFramesDir, "frame_${String.format("%06d", frameIndex)}.jpg")
                                            framePath.writeBytes(matOfByte.toArray())
                                            
                                            synchronized(this@MainActivity) {
                                                successCount++
                                                
                                                // Send progress updates
                                                val progress = successCount.toDouble() / totalFrames * 0.8 // 80% for frame processing
                                                val percentage = (progress * 100).toInt()
                                                
                                                if (successCount % 3 == 0) { // Log and update progress every 3 frames
                                                    Log.d("VideoProcessing", "Processed $successCount/$totalFrames frames ($percentage%)")
                                                    sendProgressUpdate(progress, "Processing frames... $percentage%")
                                                }
                                            }
                                            
                                            return@async framePath.absolutePath
                                        }
                                    }
                                    
                                    if (compressedBitmap != bitmap) {
                                        compressedBitmap.recycle()
                                    }
                                    bitmap.recycle()
                                }
                                null
                            } catch (e: Exception) {
                                Log.e("VideoProcessing", "Error processing frame $frameIndex: ${e.message}")
                                null
                            } finally {
                                semaphore.release()
                            }
                        }
                        jobs.add(job)
                    }
                    
                    // Wait for all frames and collect successful results
                    val results = jobs.awaitAll()
                    processedFramePaths.addAll(results.filterNotNull())
                }
                
                Log.d("VideoProcessing", "Frame processing completed: ${processedFramePaths.size}/$totalFrames frames successful")
                
                if (processedFramePaths.isEmpty()) {
                    Log.e("VideoProcessing", "No frames were processed successfully")
                    sendProgressUpdate(0.0, "Video processing failed")
                    return false
                }
                
                // Send progress update for video creation phase
                sendProgressUpdate(0.8, "Creating video from processed frames...")
                
                // Create video from processed frames maintaining original duration
                val success = createVideoFromFrames(
                    processedFramePaths,
                    outputPath,
                    durationSeconds,
                    targetFPS
                )
                
                // Cleanup - ensure cleanup even on errors
                try {
                    tempDir.deleteRecursively()
                    Log.d("VideoProcessing", "Cleaned up video processing temp directory: ${tempDir.name}")
                } catch (cleanupError: Exception) {
                    Log.w("VideoProcessing", "Warning: Failed to clean up video processing temp directory: ${cleanupError.message}")
                }
                
                if (success) {
                    Log.d("VideoProcessing", "Video processing completed successfully: YES")
                    sendProgressUpdate(1.0, "Video processing complete!")
                } else {
                    Log.d("VideoProcessing", "Video processing completed successfully: NO")
                    sendProgressUpdate(0.0, "Video processing failed")
                }
                return success
                
            } finally {
                retriever.release()
            }
            
        } catch (e: Exception) {
            Log.e("VideoProcessing", "Error processing video: ${e.message}", e)
            
            // Emergency cleanup on exception
            try {
                val videoProcessingBaseName = "video_processing"
                cacheDir.listFiles()?.forEach { file ->
                    if (file.name.startsWith(videoProcessingBaseName)) {
                        file.deleteRecursively()
                    }
                }
            } catch (cleanupError: Exception) {
                Log.w("VideoProcessing", "Failed to clean up after video processing exception: ${cleanupError.message}")
            }
            
            false
        }
    }
    

    
    // Helper method to apply filters to OpenCV Mat with texture overlays (matching iOS implementation)
    private fun applyFilterToMatWithTexture(mat: Mat, filterType: String): Mat {
        // Apply the base filter first
        val filteredMat = when (filterType) {
            "charcoalSketch" -> createCharcoalSketch(mat)
            "inkPen" -> createInkPen(mat)
            "cartoon" -> createCartoon(mat)
            "softPen" -> createSoftPen(mat)
            "noirSketch" -> createNoirSketch(mat)
            "storyboard" -> createStoryboard(mat)
            "chalk" -> createChalk(mat)
            "feltPen" -> createFeltPen(mat)
            "monochromeSketch" -> createMonochromeSketch(mat)
            "splashSketch" -> createSplashSketch(mat)
            "coloringBook" -> createColoringBook(mat)
            "paperSketch" -> createPaperSketch(mat)
            "neonSketch" -> createNeonSketch(mat)
            else -> mat.clone() // Return original if unknown filter
        }
        
        // Apply texture overlay for specific filters (reduced set)
        return when (filterType) {
            "feltPen" -> applyTextureOverlay(filteredMat, "texture10.png", 0.2)
            "monochromeSketch" -> applyTextureOverlay(filteredMat, "texture9.png", 0.5)
            else -> filteredMat // No texture overlay for other filters
        }
    }

    // Helper method to apply filters to OpenCV Mat using existing filter methods (without texture)
    private fun applyFilterToMat(mat: Mat, filterType: String): Mat {
        return when (filterType) {
            "charcoalSketch" -> createCharcoalSketch(mat)
            "inkPen" -> createInkPen(mat)
            "cartoon" -> createCartoon(mat)
            "softPen" -> createSoftPen(mat)
            "noirSketch" -> createNoirSketch(mat)
            "storyboard" -> createStoryboard(mat)
            "chalk" -> createChalk(mat)
            "feltPen" -> createFeltPen(mat)
            "monochromeSketch" -> createMonochromeSketch(mat)
            "splashSketch" -> createSplashSketch(mat)
            "coloringBook" -> createColoringBook(mat)
            "paperSketch" -> createPaperSketch(mat)
            "neonSketch" -> createNeonSketch(mat)
            else -> mat.clone() // Return original if unknown filter
        }
    }
    
    // Apply texture overlay to Mat (matching iOS implementation)
    private fun applyTextureOverlay(baseMat: Mat, textureAsset: String, opacity: Double): Mat {
        return try {
            // Load texture from assets
            val textureInputStream = assets.open(textureAsset)
            val textureBytes = textureInputStream.readBytes()
            textureInputStream.close()
            
            val textureMat = Imgcodecs.imdecode(MatOfByte(*textureBytes), Imgcodecs.IMREAD_COLOR)
            if (textureMat.empty()) {
                Log.w("TextureOverlay", "Failed to load texture: $textureAsset")
                return baseMat
            }
            
            // Resize texture to match base image size
            val resizedTexture = Mat()
            Imgproc.resize(textureMat, resizedTexture, baseMat.size())
            
            // Create result mat and apply overlay
            val result = Mat()
            baseMat.copyTo(result)
            
            // Convert to float for blending
            val baseFloat = Mat()
            val textureFloat = Mat()
            result.convertTo(baseFloat, CvType.CV_32F)
            resizedTexture.convertTo(textureFloat, CvType.CV_32F)
            
            // Apply weighted blend (addWeighted equivalent)
            val blended = Mat()
            Core.addWeighted(baseFloat, 1.0 - opacity, textureFloat, opacity, 0.0, blended)
            
            // Convert back to 8-bit
            blended.convertTo(result, CvType.CV_8U)
            
            Log.d("TextureOverlay", "Applied texture overlay: $textureAsset with opacity: $opacity")
            result
            
        } catch (e: Exception) {
            Log.e("TextureOverlay", "Error applying texture overlay: ${e.message}")
            baseMat // Return original on error
        }
    }

    // Proper video creation that mirrors iOS AVFoundation approach
    private fun createVideoFromFrames(framePaths: List<String>, outputPath: String, duration: Double, targetFPS: Float): Boolean {
        return try {
            Log.d("VideoCreation", "🎬 Creating MP4 video from ${framePaths.size} frames at ${targetFPS} FPS, duration: ${duration}s")
            
            if (framePaths.isEmpty()) {
                Log.e("VideoCreation", "❌ No frames to process")
                return false
            }
            
            // Get frame size from first frame
            val firstBitmap = BitmapFactory.decodeFile(framePaths[0])
            if (firstBitmap == null) {
                Log.e("VideoCreation", "❌ Failed to load first frame")
                return false
            }
            
            val frameWidth = firstBitmap.width
            val frameHeight = firstBitmap.height
            firstBitmap.recycle()
            
            // Ensure even dimensions for video encoding (required for H.264)
            val videoWidth = (frameWidth / 2) * 2
            val videoHeight = (frameHeight / 2) * 2
            
            Log.d("VideoCreation", "📐 Video size: ${videoWidth}x${videoHeight}")
            
            val outputFile = File(outputPath)
            outputFile.parentFile?.mkdirs()
            
            // Delete existing file if it exists
            if (outputFile.exists()) {
                outputFile.delete()
            }
            
            // Use simpler MediaMuxer approach that actually works
            return createVideoWithMediaMuxer(framePaths, outputPath, videoWidth, videoHeight, targetFPS)
            
        } catch (e: Exception) {
            Log.e("VideoCreation", "❌ Error creating MP4 video: ${e.message}", e)
            
            // Try fallback approach
            Log.d("VideoCreation", "🔄 Attempting fallback video creation...")
            return createVideoFromFramesFallback(framePaths, outputPath, duration, targetFPS)
        }
    }
    
    // Create video using MediaCodec + MediaMuxer (proper Android way)
    private fun createVideoWithMediaMuxer(framePaths: List<String>, outputPath: String, width: Int, height: Int, fps: Float): Boolean {
        return try {
            Log.d("VideoCreation", "🎥 Using MediaCodec + MediaMuxer approach for video creation")
            
            val outputFile = File(outputPath)
            if (outputFile.exists()) outputFile.delete()
            
            val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            var encoder: MediaCodec? = null
            var muxerStarted = false
            var videoTrackIndex = -1
            
            try {
                // Create and configure MediaCodec encoder
                encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
                val format = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, width, height).apply {
                    setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Planar)
                    setInteger(MediaFormat.KEY_BIT_RATE, 1500000)
                    setInteger(MediaFormat.KEY_FRAME_RATE, fps.toInt())
                    setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 2)
                }
                
                encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
                encoder.start()
                
                Log.d("VideoCreation", "✅ MediaCodec encoder started")
                
                // Process frames and encode to H.264
                val frameTimeUs = (1000000.0 / fps).toLong()
                var allFramesProcessed = false
                var frameIndex = 0
                var framesQueued = 0
                var framesEncoded = 0
                
                Log.d("VideoCreation", "🎯 Frame timing: ${frameTimeUs}μs per frame (${fps} FPS)")
                Log.d("VideoCreation", "🎯 Total frames to process: ${framePaths.size}")
                
                while (!allFramesProcessed) {
                    // Input frames to encoder
                    if (frameIndex < framePaths.size) {
                        val inputBufferIndex = encoder.dequeueInputBuffer(10000)
                        if (inputBufferIndex >= 0) {
                            val inputBuffer = encoder.getInputBuffer(inputBufferIndex)
                            
                            if (inputBuffer != null) {
                                // Load and convert frame to YUV420
                                val frameBitmap = BitmapFactory.decodeFile(framePaths[frameIndex])
                                if (frameBitmap != null) {
                                    val scaledBitmap = if (frameBitmap.width != width || frameBitmap.height != height) {
                                        Bitmap.createScaledBitmap(frameBitmap, width, height, true)
                                    } else {
                                        frameBitmap
                                    }
                                    
                                    val yuvData = bitmapToYUV420(scaledBitmap, width, height)
                                    inputBuffer.clear()
                                    inputBuffer.put(yuvData)
                                    
                                    val presentationTimeUs = frameIndex * frameTimeUs
                                    encoder.queueInputBuffer(inputBufferIndex, 0, yuvData.size, presentationTimeUs, 0)
                                    
                                    if (scaledBitmap != frameBitmap) scaledBitmap.recycle()
                                    frameBitmap.recycle()
                                    
                                    frameIndex++
                                    framesQueued++
                                    Log.d("VideoCreation", "📤 Queued frame $frameIndex/${framePaths.size} at ${presentationTimeUs}μs")
                                } else {
                                    // Send empty buffer for failed frame
                                    encoder.queueInputBuffer(inputBufferIndex, 0, 0, frameIndex * frameTimeUs, 0)
                                    frameIndex++
                                }
                            }
                        }
                    } else if (frameIndex >= framePaths.size) {
                        // Signal end of input
                        val inputBufferIndex = encoder.dequeueInputBuffer(10000)
                        if (inputBufferIndex >= 0) {
                            encoder.queueInputBuffer(inputBufferIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            frameIndex = Int.MAX_VALUE // Mark as done
                        }
                    }
                    
                    // Get encoded output
                    val bufferInfo = MediaCodec.BufferInfo()
                    val outputBufferIndex = encoder.dequeueOutputBuffer(bufferInfo, 10000)
                    
                    when {
                        outputBufferIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                            // Start muxer when we get the format
                            if (!muxerStarted) {
                                val newFormat = encoder.outputFormat
                                videoTrackIndex = muxer.addTrack(newFormat)
                                muxer.start()
                                muxerStarted = true
                                Log.d("VideoCreation", "✅ MediaMuxer started with format: $newFormat")
                            }
                        }
                        outputBufferIndex >= 0 -> {
                            val outputBuffer = encoder.getOutputBuffer(outputBufferIndex)
                            if (outputBuffer != null && muxerStarted) {
                                if (bufferInfo.size > 0) {
                                    muxer.writeSampleData(videoTrackIndex, outputBuffer, bufferInfo)
                                    framesEncoded++
                                    Log.d("VideoCreation", "✅ Encoded frame $framesEncoded at ${bufferInfo.presentationTimeUs}μs")
                                }
                                
                                if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                                    allFramesProcessed = true
                                    Log.d("VideoCreation", "✅ All frames encoded - Queued: $framesQueued, Encoded: $framesEncoded")
                                }
                            }
                            encoder.releaseOutputBuffer(outputBufferIndex, false)
                        }
                    }
                }
                
                // Clean up
                encoder.stop()
                encoder.release()
                
                if (muxerStarted) {
                    muxer.stop()
                }
                muxer.release()
                
                Log.d("VideoCreation", "✅ MediaCodec video creation completed: $outputPath")
                
                // Verify the output file
                val createdFile = File(outputPath)
                if (createdFile.exists() && createdFile.length() > 0) {
                    Log.d("VideoCreation", "✅ Output file verified: ${createdFile.length()} bytes")
                    return true
                } else {
                    Log.e("VideoCreation", "❌ Output file is empty or doesn't exist")
                    return false
                }
                
            } catch (e: Exception) {
                Log.e("VideoCreation", "❌ Error in MediaCodec approach: ${e.message}", e)
                
                // Clean up on error
                try {
                    encoder?.stop()
                    encoder?.release()
                    if (muxerStarted) muxer.stop()
                    muxer.release()
                } catch (cleanupError: Exception) {
                    Log.w("VideoCreation", "Error during cleanup: ${cleanupError.message}")
                }
                
                return false
            }
            
        } catch (e: Exception) {
            Log.e("VideoCreation", "❌ MediaCodec video creation failed: ${e.message}")
            return false
        }
    }
    
    // Helper method to convert bitmap to YUV420 format for MediaCodec
    private fun bitmapToYUV420(bitmap: Bitmap, width: Int, height: Int): ByteArray {
        val argb = IntArray(width * height)
        bitmap.getPixels(argb, 0, width, 0, 0, width, height)
        
        val yuv = ByteArray(width * height * 3 / 2)
        var yIndex = 0
        var uvIndex = width * height
        
        for (y in 0 until height) {
            for (x in 0 until width) {
                val pixel = argb[y * width + x]
                val r = (pixel shr 16) and 0xff
                val g = (pixel shr 8) and 0xff
                val b = pixel and 0xff
                
                // Calculate Y
                val yValue = ((66 * r + 129 * g + 25 * b + 128) shr 8) + 16
                yuv[yIndex++] = yValue.coerceIn(0, 255).toByte()
                
                // Calculate U and V for every 2x2 block
                if (y % 2 == 0 && x % 2 == 0) {
                    val uValue = ((-38 * r - 74 * g + 112 * b + 128) shr 8) + 128
                    val vValue = ((112 * r - 94 * g - 18 * b + 128) shr 8) + 128
                    yuv[uvIndex++] = uValue.coerceIn(0, 255).toByte()
                    yuv[uvIndex++] = vValue.coerceIn(0, 255).toByte()
                }
            }
        }
        
        return yuv
    }
    
    // Simple fallback: copy first processed frame as the result
    private fun createVideoFromFramesFallback(framePaths: List<String>, outputPath: String, duration: Double, targetFPS: Float): Boolean {
        return try {
            Log.d("VideoCreation", "🔄 Creating fallback result from processed frames")
            
            if (framePaths.isEmpty()) return false
            
            // Copy the first processed frame as the result (user can see the filter effect)
            val firstFrame = File(framePaths[0])
            if (firstFrame.exists()) {
                firstFrame.copyTo(File(outputPath), overwrite = true)
                
                // Create metadata to indicate this represents processed video
                val metadataFile = File(File(outputPath).parent, "${File(outputPath).nameWithoutExtension}_info.txt")
                metadataFile.writeText("Processed ${framePaths.size} frames with filter. Duration: ${duration}s, FPS: ${targetFPS}")
                
                Log.d("VideoCreation", "✅ Fallback: Processed frame saved as result")
                return true
            }
            
            false
        } catch (e: Exception) {
            Log.e("VideoCreation", "❌ Fallback creation failed: ${e.message}")
            false
        }
    }


    // Merge audio from original video with filtered video
    private fun mergeAudioWithVideo(videoPath: String, audioSourcePath: String, outputPath: String): Boolean {
        return try {
            Log.d("AudioMerge", "🎵 Merging audio from $audioSourcePath with video $videoPath")
            
            val videoFile = File(videoPath)
            val audioSourceFile = File(audioSourcePath)
            val outputFile = File(outputPath)
            
            if (!videoFile.exists()) {
                Log.e("AudioMerge", "❌ Video file not found: $videoPath")
                return false
            }
            
            if (!audioSourceFile.exists()) {
                Log.e("AudioMerge", "❌ Audio source file not found: $audioSourcePath")
                return false
            }
            
            // Ensure output directory exists
            outputFile.parentFile?.mkdirs()
            
            // Initialize MediaExtractor and MediaMuxer
            val videoExtractor = MediaExtractor()
            val audioExtractor = MediaExtractor()
            val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            
            try {
                // Set up video extractor
                videoExtractor.setDataSource(videoPath)
                var videoTrackIndex = -1
                var videoFormat: MediaFormat? = null
                
                for (i in 0 until videoExtractor.trackCount) {
                    val format = videoExtractor.getTrackFormat(i)
                    val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
                    if (mime.startsWith("video/")) {
                        videoTrackIndex = i
                        videoFormat = format
                        break
                    }
                }
                
                // Set up audio extractor
                audioExtractor.setDataSource(audioSourcePath)
                var audioTrackIndex = -1
                var audioFormat: MediaFormat? = null
                
                for (i in 0 until audioExtractor.trackCount) {
                    val format = audioExtractor.getTrackFormat(i)
                    val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
                    if (mime.startsWith("audio/")) {
                        audioTrackIndex = i
                        audioFormat = format
                        break
                    }
                }
                
                if (videoTrackIndex == -1 || videoFormat == null) {
                    Log.e("AudioMerge", "❌ No video track found in video file")
                    return false
                }
                
                if (audioTrackIndex == -1 || audioFormat == null) {
                    Log.w("AudioMerge", "⚠️ No audio track found in source file, copying video only")
                    // Just copy the video file if no audio track
                    videoFile.copyTo(outputFile, overwrite = true)
                    return true
                }
                
                // Add tracks to muxer
                val muxerVideoTrack = muxer.addTrack(videoFormat)
                val muxerAudioTrack = muxer.addTrack(audioFormat)
                
                muxer.start()
                
                // Copy video track
                videoExtractor.selectTrack(videoTrackIndex)
                val videoBuffer = java.nio.ByteBuffer.allocate(1024 * 1024) // 1MB buffer
                val videoBufferInfo = android.media.MediaCodec.BufferInfo()
                
                while (true) {
                    val sampleSize = videoExtractor.readSampleData(videoBuffer, 0)
                    if (sampleSize < 0) break
                    
                    videoBufferInfo.offset = 0
                    videoBufferInfo.size = sampleSize
                    videoBufferInfo.presentationTimeUs = videoExtractor.sampleTime
                    videoBufferInfo.flags = videoExtractor.sampleFlags
                    
                    muxer.writeSampleData(muxerVideoTrack, videoBuffer, videoBufferInfo)
                    videoExtractor.advance()
                }
                
                // Copy audio track
                audioExtractor.selectTrack(audioTrackIndex)
                val audioBuffer = java.nio.ByteBuffer.allocate(1024 * 1024) // 1MB buffer
                val audioBufferInfo = android.media.MediaCodec.BufferInfo()
                
                while (true) {
                    val sampleSize = audioExtractor.readSampleData(audioBuffer, 0)
                    if (sampleSize < 0) break
                    
                    audioBufferInfo.offset = 0
                    audioBufferInfo.size = sampleSize
                    audioBufferInfo.presentationTimeUs = audioExtractor.sampleTime
                    audioBufferInfo.flags = audioExtractor.sampleFlags
                    
                    muxer.writeSampleData(muxerAudioTrack, audioBuffer, audioBufferInfo)
                    audioExtractor.advance()
                }
                
                Log.d("AudioMerge", "✅ Audio merging completed successfully")
                true
                
            } finally {
                try {
                    muxer.stop()
                    muxer.release()
                } catch (e: Exception) {
                    Log.w("AudioMerge", "Warning: Error stopping muxer: ${e.message}")
                }
                
                try {
                    videoExtractor.release()
                    audioExtractor.release()
                } catch (e: Exception) {
                    Log.w("AudioMerge", "Warning: Error releasing extractors: ${e.message}")
                }
            }
            
        } catch (e: Exception) {
            Log.e("AudioMerge", "❌ Error merging audio: ${e.message}", e)
            
            // Fallback: copy original video file if merging fails
            try {
                File(videoPath).copyTo(File(outputPath), overwrite = true)
                Log.d("AudioMerge", "💾 Fallback: Copied video without audio merging")
                true
            } catch (fallbackError: Exception) {
                Log.e("AudioMerge", "❌ Fallback copy also failed: ${fallbackError.message}")
                false
            }
        }
    }
}
