// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

import 'package:sketch/data/models/enums.dart';

part 'project.g.dart';

abstract class Project extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  FilterMode filterMode;

  @HiveField(3)
  AspectRatioMode aspectRatioMode;

  @HiveField(4)
  CropRectData? cropRect;

  Project({
    required this.id,
    required this.name,
    this.filterMode = FilterMode.original,
    this.aspectRatioMode = AspectRatioMode.original,
    this.cropRect,
  });
}

@HiveType(typeId: 1)
class ImageProject extends Project {
  @HiveField(10)
  final String originalImage;

  @HiveField(11)
  final String processedImage;

  @HiveField(12)
  int? saturation;

  @HiveField(13)
  int? brightness;

  @HiveField(14)
  int? contrast;

  @HiveField(15)
  int? temperature;

  @HiveField(16)
  int? sharpen;

  @HiveField(17)
  int? blur;

  ImageProject({
    required super.id,
    required super.name,
    required this.originalImage,
    required this.processedImage,
    required super.filterMode,
    required super.aspectRatioMode,
    super.cropRect,
    this.saturation,
    this.brightness,
    this.contrast,
    this.temperature,
    this.sharpen,
    this.blur,
  });

  ImageProject copyWith({
    String? name,
    String? originalImage,
    String? processedImage,
    int? saturation,
    int? brightness,
    int? contrast,
    int? temperature,
    int? sharpen,
    int? blur,
    FilterMode? filterMode,
    AspectRatioMode? aspectRatioMode,
    CropRectData? cropRect,
  }) {
    return ImageProject(
      originalImage: originalImage ?? this.originalImage,
      processedImage: processedImage ?? this.processedImage,
      saturation: saturation ?? this.saturation,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      temperature: temperature ?? this.temperature,
      sharpen: sharpen ?? this.sharpen,
      blur: blur ?? this.blur,
      id: id,
      name: name ?? this.name,
      filterMode: filterMode ?? this.filterMode,
      aspectRatioMode: aspectRatioMode ?? this.aspectRatioMode,
      cropRect: cropRect ?? this.cropRect,
    );
  }
}

@HiveType(typeId: 2)
class VideoProject extends Project {
  @HiveField(20)
  final String originalVideo;

  @HiveField(21)
  final String processedVideo;

  @HiveField(22)
  int? saturation;

  @HiveField(23)
  int? brightness;

  @HiveField(24)
  int? contrast;

  @HiveField(25)
  int? blur;

  @HiveField(26)
  int? temperature;

  @HiveField(27)
  int? sharpen;

  @HiveField(28)
  double? speed;

  // New fields for frame-based processing
  @HiveField(29)
  List<String>? extractedFramePaths; // Paths to extracted frames at 15 FPS

  @HiveField(30)
  int? totalFrameCount; // Total number of frames extracted

  @HiveField(31)
  double? originalDuration; // Original video duration in seconds

  @HiveField(32)
  double? originalFPS; // Original video FPS

  @HiveField(33)
  String? framesDirectory; // Directory where frames are stored

  VideoProject({
    required super.id,
    required super.name,
    required this.originalVideo,
    required this.processedVideo,
    required super.filterMode,
    required super.aspectRatioMode,
    super.cropRect,
    this.saturation,
    this.brightness,
    this.contrast,
    this.blur,
    this.temperature,
    this.sharpen,
    this.speed,
    this.extractedFramePaths,
    this.totalFrameCount,
    this.originalDuration,
    this.originalFPS,
    this.framesDirectory,
  });

  VideoProject copyWith({
    String? name,
    String? originalVideo,
    String? processedVideo,
    FilterMode? filterMode,
    AspectRatioMode? aspectRatioMode,
    CropRectData? cropRect,
    int? saturation,
    int? brightness,
    int? contrast,
    int? blur,
    int? temperature,
    int? sharpen,
    double? speed,
    List<String>? extractedFramePaths,
    int? totalFrameCount,
    double? originalDuration,
    double? originalFPS,
    String? framesDirectory,
  }) {
    return VideoProject(
      originalVideo: originalVideo ?? this.originalVideo,
      processedVideo: processedVideo ?? this.processedVideo,
      id: id,
      name: name ?? this.name,
      filterMode: filterMode ?? this.filterMode,
      aspectRatioMode: aspectRatioMode ?? this.aspectRatioMode,
      cropRect: cropRect ?? this.cropRect,
      saturation: saturation ?? this.saturation,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      blur: blur ?? this.blur,
      temperature: temperature ?? this.temperature,
      sharpen: sharpen ?? this.sharpen,
      speed: speed ?? this.speed,
      extractedFramePaths: extractedFramePaths ?? this.extractedFramePaths,
      totalFrameCount: totalFrameCount ?? this.totalFrameCount,
      originalDuration: originalDuration ?? this.originalDuration,
      originalFPS: originalFPS ?? this.originalFPS,
      framesDirectory: framesDirectory ?? this.framesDirectory,
    );
  }

  // Helper methods
  bool get hasExtractedFrames =>
      extractedFramePaths != null &&
      extractedFramePaths!.isNotEmpty &&
      totalFrameCount != null &&
      totalFrameCount! > 0;

  double get targetFPS => 15.0; // Always process at 15 FPS
}

@HiveType(typeId: 0)
class CropRectData {
  @HiveField(0)
  double left;

  @HiveField(1)
  double top;

  @HiveField(2)
  double right;

  @HiveField(3)
  double bottom;

  CropRectData({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  Rect toRect() => Rect.fromLTRB(left, top, right, bottom);

  static CropRectData fromRect(Rect rect) => CropRectData(
        left: rect.left,
        top: rect.top,
        right: rect.right,
        bottom: rect.bottom,
      );
}
