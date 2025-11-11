// ignore_for_file: unused_catch_clause

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:injectable/injectable.dart';
import 'package:image/image.dart' as img;
import '../models/project.dart';
import '../models/enums.dart';

@singleton
class OpenCVHelper {
  static const platform = MethodChannel('opencv_channel');
  static const progressChannel = EventChannel('opencv_progress_channel');

  static Stream<Map<String, dynamic>>? _progressStream;

  static Stream<Map<String, dynamic>> get progressStream {
    _progressStream ??= progressChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event);
    });
    return _progressStream!;
  }

  static Future<ImageProject> applyImageFilter(
    ImageProject project,
    FilterMode filterMode,
  ) async {
    try {
      // Read original image file
      final originalFile = File(project.originalImage);
      if (!await originalFile.exists()) {
        throw Exception(
            'Original image file not found: ${project.originalImage}');
      }

      final originalBytes = await originalFile.readAsBytes();

      // Pre-process image to handle orientation for ALL filters in a separate isolate
      final orientationCorrectedBytes =
          await _correctImageOrientationInIsolate(originalBytes);

      // Apply filter based on FilterMode
      Uint8List? processedBytes;

      switch (filterMode) {
        case FilterMode.original:
          // For original mode, just use the orientation-corrected bytes
          processedBytes = orientationCorrectedBytes;
          break;
        case FilterMode.pencilSketch:
          processedBytes = await platform.invokeMethod(
            'convertToSketch',
            Uint8List.fromList(orientationCorrectedBytes),
          );
          break;
        case FilterMode.charcoalSketch:
          processedBytes = await platform.invokeMethod(
            'convertToCharcoalSketch',
            Uint8List.fromList(orientationCorrectedBytes),
          );
          break;
        case FilterMode.inkPen:
          processedBytes = await platform.invokeMethod(
            'convertToInkPen',
            Uint8List.fromList(orientationCorrectedBytes),
          );
          break;
        case FilterMode.colorSketch:
          processedBytes = await platform.invokeMethod(
            'convertToColorSketch',
            Uint8List.fromList(orientationCorrectedBytes),
          );
          break;
        case FilterMode.cartoon:
          processedBytes = await platform.invokeMethod(
            'convertToCartoon',
            Uint8List.fromList(orientationCorrectedBytes),
          );
          break;
        case FilterMode.techPen:
          processedBytes = await platform.invokeMethod(
            'convertToTechPen',
            Uint8List.fromList(orientationCorrectedBytes),
          );
          break;
        case FilterMode.softPen:
          processedBytes = await platform.invokeMethod(
            'convertToSoftPen',
            Uint8List.fromList(orientationCorrectedBytes),
          );
          break;
        case FilterMode.noirSketch:
          processedBytes = await platform.invokeMethod(
            'convertToNoirSketch',
            Uint8List.fromList(orientationCorrectedBytes),
          );
          break;
        case FilterMode.cartoon2:
          processedBytes = await platform.invokeMethod(
            'convertToCartoon2',
            Uint8List.fromList(orientationCorrectedBytes),
          );
          break;
        case FilterMode.storyboard:
          processedBytes = await platform.invokeMethod(
            'convertToStoryboard',
            Uint8List.fromList(orientationCorrectedBytes),
          );
          break;
        case FilterMode.chalk:
          processedBytes = await platform.invokeMethod(
            'convertToChalk',
            Uint8List.fromList(orientationCorrectedBytes),
          );
          break;
        case FilterMode.feltPen:
          processedBytes = await platform.invokeMethod(
            'convertToFeltPen',
            Uint8List.fromList(orientationCorrectedBytes),
          );
          break;
        case FilterMode.monochromeSketch:
          processedBytes = await platform.invokeMethod(
            'convertToMonochromeSketch',
            Uint8List.fromList(orientationCorrectedBytes),
          );
          break;
        case FilterMode.splashSketch:
          processedBytes = await platform.invokeMethod(
            'convertToSplashSketch',
            Uint8List.fromList(orientationCorrectedBytes),
          );
          break;
        case FilterMode.coloringBook:
          processedBytes = await platform.invokeMethod(
            'convertToColoringBook',
            Uint8List.fromList(orientationCorrectedBytes),
          );
          break;
        case FilterMode.waxSketch:
          processedBytes = await platform.invokeMethod(
            'convertToWaxSketch',
            Uint8List.fromList(orientationCorrectedBytes),
          );
          break;
        case FilterMode.paperSketch:
          processedBytes = await platform.invokeMethod(
            'convertToPaperSketch',
            Uint8List.fromList(orientationCorrectedBytes),
          );
          break;
        case FilterMode.neonSketch:
          processedBytes = await platform.invokeMethod(
            'convertToNeonSketch',
            Uint8List.fromList(orientationCorrectedBytes),
          );
          break;
        case FilterMode.anime:
          processedBytes = await platform.invokeMethod(
            'convertToAnime',
            Uint8List.fromList(orientationCorrectedBytes),
          );
          break;
        case FilterMode.comicBook:
          processedBytes = await platform.invokeMethod(
            'convertToComicBook',
            Uint8List.fromList(orientationCorrectedBytes),
          );
          break;
      }

      if (processedBytes == null) {
        throw Exception('Failed to process image with filter: $filterMode');
      }

      // Save processed image to new file
      final processedImagePath = await _saveProcessedImage(
        processedBytes,
        project.id,
        filterMode,
      );

      // Return updated project
      return project.copyWith(
        processedImage: processedImagePath,
        filterMode: filterMode,
      );
    } on PlatformException catch (e) {
      throw Exception('Platform error applying filter: ${e.message}');
    } catch (e) {
      throw Exception('Error applying image filter: $e');
    }
  }

  static Future<VideoProject> applyVideoFilterWithProgress(
    VideoProject project,
    FilterMode filterMode, {
    Function(double progress, String status)? onProgress,
    bool Function()? isCancelled,
  }) async {
    return await applyVideoFilter(project, filterMode,
        onProgress: onProgress, isCancelled: isCancelled);
  }

  static Future<VideoProject> applyVideoFilter(
    VideoProject project,
    FilterMode filterMode, {
    Function(double progress, String status)? onProgress,
    bool Function()? isCancelled,
  }) async {
    try {
      // Check for cancellation at the start
      if (isCancelled?.call() == true) {
        throw Exception('Operation cancelled');
      }

      // For original mode, just copy the original video
      if (filterMode == FilterMode.original) {
        final originalFile = File(project.originalVideo);
        if (!await originalFile.exists()) {
          throw Exception(
              'Original video file not found: ${project.originalVideo}');
        }

        final processedVideoPath = await _saveProcessedVideo(
          await originalFile.readAsBytes(),
          project.id,
          filterMode,
        );

        return project.copyWith(
          processedVideo: processedVideoPath,
          filterMode: filterMode,
        );
      }

      // Check if we have extracted frames
      if (!project.hasExtractedFrames) {
        // Check for cancellation before frame extraction
        if (isCancelled?.call() == true) {
          throw Exception('Operation cancelled');
        }

        // Report frame extraction progress (0-40%)
        onProgress?.call(0.0, 'Extracting video frames...');

        // Extract frames with progress reporting (0-40% range)
        final frameExtractionResult = await extractVideoFrames(
          project.originalVideo,
          project.id,
          onProgress: onProgress,
          isCancelled: isCancelled,
        );

        if (frameExtractionResult == null) {
          if (isCancelled?.call() == true) {
            throw Exception('Operation cancelled');
          }
          throw Exception('Failed to extract frames for video processing');
        }

        // Check for cancellation after frame extraction
        if (isCancelled?.call() == true) {
          throw Exception('Operation cancelled');
        }

        // Report completion of frame extraction (40%)
        onProgress?.call(0.4, 'Frame extraction complete, applying filter...');

        // Update project with frame information
        final updatedProject = project.copyWith(
          extractedFramePaths:
              frameExtractionResult['framePaths'] as List<String>?,
          totalFrameCount: frameExtractionResult['frameCount'] as int?,
          originalDuration: frameExtractionResult['duration'] as double?,
          originalFPS: frameExtractionResult['fps'] as double?,
          framesDirectory: frameExtractionResult['framesDirectory'] as String?,
        );

        // Now apply filter to the updated project with frames (40-100% range)
        return await applyVideoFilter(updatedProject, filterMode,
            onProgress: _createMappedProgressCallback(onProgress, 0.4, 1.0),
            isCancelled: isCancelled);
      }

      // Check for cancellation before applying filter to frames
      if (isCancelled?.call() == true) {
        throw Exception('Operation cancelled');
      }

      // Apply filter to existing frames and create new video
      final processedVideoPath = await _applyFilterToFrames(
        project,
        filterMode,
        onProgress: onProgress,
        isCancelled: isCancelled,
      );

      // Return updated project
      return project.copyWith(
        processedVideo: processedVideoPath,
        filterMode: filterMode,
      );
    } on PlatformException catch (e) {
      throw Exception('Platform error applying filter: ${e.message}');
    } catch (e) {
      throw Exception('Error applying video filter: $e');
    }
  }

  /// Applies filter to any Project type (ImageProject or VideoProject)
  static Future<Project> applyFilter(
    Project project,
    FilterMode filterMode,
  ) async {
    if (project is ImageProject) {
      return await applyImageFilter(project, filterMode);
    } else if (project is VideoProject) {
      return await applyVideoFilter(project, filterMode);
    } else {
      throw Exception('Unsupported project type: ${project.runtimeType}');
    }
  }

  /// Save processed image bytes to app documents directory
  static Future<String> _saveProcessedImage(
    Uint8List imageBytes,
    String projectId,
    FilterMode filterMode,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final processedDir =
        Directory(path.join(directory.path, 'processed_images'));

    if (!await processedDir.exists()) {
      await processedDir.create(recursive: true);
    }

    final fileName = '${projectId}_${filterMode.name}.jpg';
    final filePath = path.join(processedDir.path, fileName);
    final file = File(filePath);

    await file.writeAsBytes(imageBytes);
    return filePath;
  }

  /// Save processed video bytes to app documents directory
  static Future<String> _saveProcessedVideo(
    Uint8List videoBytes,
    String projectId,
    FilterMode filterMode,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final processedDir =
        Directory(path.join(directory.path, 'processed_videos'));

    if (!await processedDir.exists()) {
      await processedDir.create(recursive: true);
    }

    final fileName = '${projectId}_${filterMode.name}.mp4';
    final filePath = path.join(processedDir.path, fileName);
    final file = File(filePath);

    await file.writeAsBytes(videoBytes);
    return filePath;
  }

  /// Get filter display name for UI
  static String getFilterDisplayName(FilterMode filterMode) {
    switch (filterMode) {
      case FilterMode.original:
        return 'Original';
      case FilterMode.pencilSketch:
        return 'Pencil Sketch';
      case FilterMode.charcoalSketch:
        return 'Charcoal Sketch';
      case FilterMode.inkPen:
        return 'Ink Pen';
      case FilterMode.colorSketch:
        return 'Color Sketch';
      case FilterMode.cartoon:
        return 'Cartoon';
      case FilterMode.techPen:
        return 'Tech Pen';
      case FilterMode.softPen:
        return 'Soft Pen';
      case FilterMode.noirSketch:
        return 'Noir Sketch';
      case FilterMode.cartoon2:
        return 'Cartoon 2';
      case FilterMode.storyboard:
        return 'Storyboard';
      case FilterMode.chalk:
        return 'Chalk';
      case FilterMode.feltPen:
        return 'Felt Pen';
      case FilterMode.monochromeSketch:
        return 'Monochrome Sketch';
      case FilterMode.splashSketch:
        return 'Splash Sketch';
      case FilterMode.coloringBook:
        return 'Coloring Book';
      case FilterMode.waxSketch:
        return 'Wax Sketch';
      case FilterMode.paperSketch:
        return 'Paper Sketch';
      case FilterMode.neonSketch:
        return 'Neon Sketch';
      case FilterMode.anime:
        return 'Anime';
      case FilterMode.comicBook:
        return 'Comic Book';
    }
  }

  /// Extract video frames at 15 FPS for frame-based processing
  static Future<Map<String, dynamic>?> extractVideoFrames(
    String videoPath,
    String projectId, {
    Function(double progress, String status)? onProgress,
    bool Function()? isCancelled,
  }) async {
    try {
      // Check for cancellation at the start
      if (isCancelled?.call() == true) {
        return null;
      }

      // Generate frames directory path
      final directory = await getApplicationDocumentsDirectory();
      final framesDir =
          Directory(path.join(directory.path, 'video_frames', projectId));

      if (!await framesDir.exists()) {
        await framesDir.create(recursive: true);
      }

      // Create a safe progress callback that checks for cancellation
      void safeProgressCallback(Map<String, dynamic> data) {
        if (isCancelled?.call() == true) return;

        try {
          final progress = (data['progress'] as num?)?.toDouble() ?? 0.0;
          final status = data['status'] as String? ?? 'Extracting frames...';

          // Map the native progress (0-100%) to our range (0-40%)
          final mappedProgress = progress * 0.4;
          onProgress?.call(mappedProgress, status);
        } catch (e) {
          // Ignore progress update errors if cancelled
        }
      }

      // Listen to progress updates during frame extraction if callback is provided
      StreamSubscription? progressSubscription;
      if (onProgress != null) {
        progressSubscription = progressStream.listen(safeProgressCallback);
      }

      try {
        // Check for cancellation before making platform call
        if (isCancelled?.call() == true) {
          return null;
        }

        // Call native method to extract frames at 15 FPS
        final result = await platform.invokeMethod('extractVideoFrames', {
          'inputPath': videoPath,
          'outputDirectory': framesDir.path,
          'targetFPS': 15.0,
        });

        // Check for cancellation after platform call
        if (isCancelled?.call() == true) {
          return null;
        }

        if (result != null && result is Map) {
          final framePaths =
              (result['framePaths'] as List?)?.cast<String>() ?? [];
          final frameCount = result['frameCount'] as int? ?? 0;
          final duration = result['duration'] as double? ?? 0.0;
          final fps = result['fps'] as double? ?? 15.0;

          return {
            'framePaths': framePaths,
            'frameCount': frameCount,
            'duration': duration,
            'fps': fps,
            'framesDirectory': framesDir.path,
          };
        } else {
          return null;
        }
      } finally {
        // Clean up progress subscription
        await progressSubscription?.cancel();
      }
    } on PlatformException catch (e) {
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Apply filter to existing frames and create new video
  static Future<String> _applyFilterToFrames(
    VideoProject project,
    FilterMode filterMode, {
    Function(double progress, String status)? onProgress,
    bool Function()? isCancelled,
  }) async {
    // Check for cancellation at the start
    if (isCancelled?.call() == true) {
      throw Exception('Operation cancelled');
    }

    // Generate output path
    final directory = await getApplicationDocumentsDirectory();
    final processedDir =
        Directory(path.join(directory.path, 'processed_videos'));

    if (!await processedDir.exists()) {
      await processedDir.create(recursive: true);
    }

    final fileName = '${project.id}_${filterMode.name}.mp4';
    final outputPath = path.join(processedDir.path, fileName);

    // Report initial progress
    onProgress?.call(0.0, 'Starting video processing...');

    // Create a safe progress callback that checks for cancellation
    void safeProgressCallback(Map<String, dynamic> data) {
      if (isCancelled?.call() == true) return;

      try {
        final progress = (data['progress'] as num?)?.toDouble() ?? 0.0;
        final status = data['status'] as String? ?? 'Processing...';
        onProgress?.call(progress, status);
      } catch (e) {
        // Ignore progress update errors if cancelled
      }
    }

    // Listen to progress updates if callback is provided
    StreamSubscription? progressSubscription;
    if (onProgress != null) {
      progressSubscription = progressStream.listen(safeProgressCallback);
    }

    try {
      // Check for cancellation before making platform call
      if (isCancelled?.call() == true) {
        throw Exception('Operation cancelled');
      }

      // Call native method to apply filter to frames and reassemble video
      final result = await platform.invokeMethod('applyFilterToFrames', {
        'framePaths': project.extractedFramePaths,
        'outputPath': outputPath,
        'filterType': filterMode.name,
        'frameCount': project.totalFrameCount,
        'duration': project.originalDuration,
        'targetFPS': project.targetFPS,
      });

      // Check for cancellation after platform call
      if (isCancelled?.call() == true) {
        throw Exception('Operation cancelled');
      }

      // Report completion
      onProgress?.call(1.0, 'Video processing complete!');

      if (result == null || result != true) {
        throw Exception(
            'Failed to apply filter to frames and reassemble video');
      }

      return outputPath;
    } finally {
      // Clean up progress subscription
      await progressSubscription?.cancel();
    }
  }

  /// Correct image orientation in a separate isolate to avoid blocking UI
  static Future<Uint8List> _correctImageOrientationInIsolate(
      Uint8List imageBytes) async {
    final receivePort = ReceivePort();

    await Isolate.spawn(_orientationCorrectionIsolate, {
      'sendPort': receivePort.sendPort,
      'imageBytes': imageBytes,
    });

    final result = await receivePort.first;
    return result as Uint8List;
  }

  /// Isolate entry point for orientation correction
  static void _orientationCorrectionIsolate(Map<String, dynamic> message) {
    final sendPort = message['sendPort'] as SendPort;
    final imageBytes = message['imageBytes'] as Uint8List;

    try {
      img.Image? tempImage = img.decodeImage(imageBytes);
      if (tempImage != null) {
        tempImage = img.bakeOrientation(tempImage);
        final correctedBytes = img.encodeJpg(tempImage, quality: 100);
        sendPort.send(correctedBytes);
      } else {
        sendPort.send(imageBytes);
      }
    } catch (e) {
      // If orientation correction fails, send original bytes
      sendPort.send(imageBytes);
    }
  }

  /// Create a progress callback that maps progress from one range to another
  static Function(double progress, String status)?
      _createMappedProgressCallback(
    Function(double progress, String status)? originalCallback,
    double startRange,
    double endRange,
  ) {
    if (originalCallback == null) return null;

    return (double progress, String status) {
      // Map progress from 0-1 to startRange-endRange
      final mappedProgress = startRange + (progress * (endRange - startRange));
      originalCallback(mappedProgress, status);
    };
  }
}
