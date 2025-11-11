import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:injectable/injectable.dart';
import '../../data/models/project.dart';
import '../../data/models/enums.dart';
import '../../data/helpers/opencv_helper.dart';
import '../../data/helpers/db_helper.dart';

@injectable
class VideoProjectProvider extends ChangeNotifier {
  VideoProject? _currentProject;
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false; // Track disposal state

  // Progress tracking
  double _processingProgress = 0.0; // 0.0 to 1.0
  String _processingStatus = '';

  // Cancellation support
  bool _isCancelled = false;

  // Temporary adjustments for real-time preview
  int _tempBrightness = 0;
  int _tempContrast = 0;
  int _tempSaturation = 0;
  int _tempBlur = 0;
  int _tempTemperature = 0;
  int _tempSharpen = 0;
  double _tempSpeed = 1.0;

  // Getters
  VideoProject? get currentProject => _currentProject;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProject => _currentProject != null;
  bool get isCancelled => _isCancelled;

  // Progress getters
  double get processingProgress => _processingProgress;
  String get processingStatus => _processingStatus;
  int get processingPercentage => (_processingProgress * 100).round();

  // Current adjustment getters
  int get tempBrightness => _tempBrightness;
  int get tempContrast => _tempContrast;
  int get tempSaturation => _tempSaturation;
  int get tempBlur => _tempBlur;
  int get tempTemperature => _tempTemperature;
  int get tempSharpen => _tempSharpen;
  double get tempSpeed => _tempSpeed;

  // Applied adjustment getters
  int get appliedBrightness => _currentProject?.brightness ?? 0;
  int get appliedContrast => _currentProject?.contrast ?? 0;
  int get appliedSaturation => _currentProject?.saturation ?? 0;
  int get appliedBlur => _currentProject?.blur ?? 0;
  int get appliedTemperature => _currentProject?.temperature ?? 0;
  int get appliedSharpen => _currentProject?.sharpen ?? 0;
  double get appliedSpeed => _currentProject?.speed ?? 1.0;

  /// Load existing project
  Future<void> loadProject(String projectId) async {
    _setLoading(true);
    _clearError();

    try {
      final project = DBHelper.getProject(projectId);
      if (project != null && project is VideoProject) {
        _currentProject = project;
        _resetTempAdjustments();
        // Initialize temp speed from saved project speed
        _tempSpeed = _currentProject!.speed ?? 1.0;
        _safeNotifyListeners();
      } else {
        _setError('Project not found or invalid type');
      }
    } catch (e) {
      _setError('Failed to load project: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create new project from video path
  Future<void> createProject({
    required String id,
    required String name,
    required String videoPath,
  }) async {
    // Reset cancellation state
    _isCancelled = false;

    _setLoading(true);
    _clearError();

    try {
      // First create a basic project
      _currentProject = VideoProject(
        id: id,
        name: name,
        originalVideo: videoPath,
        processedVideo: videoPath, // Initially same as original
        filterMode: FilterMode.original,
        aspectRatioMode: AspectRatioMode.original,
      );

      // Check for cancellation before frame extraction
      if (_isCancelled || _isDisposed) return;

      // Extract frames at 15 FPS for future filter processing
      final frameExtractionResult = await OpenCVHelper.extractVideoFrames(
        videoPath,
        id,
        isCancelled: () => _isCancelled || _isDisposed,
      );

      // Check for cancellation after frame extraction
      if (_isCancelled || _isDisposed) return;

      if (frameExtractionResult != null) {
        // Update project with frame information
        _currentProject = _currentProject!.copyWith(
          extractedFramePaths:
              frameExtractionResult['framePaths'] as List<String>?,
          totalFrameCount: frameExtractionResult['frameCount'] as int?,
          originalDuration: frameExtractionResult['duration'] as double?,
          originalFPS: frameExtractionResult['fps'] as double?,
          framesDirectory: frameExtractionResult['framesDirectory'] as String?,
        );
      } else {
        // If frame extraction failed and we're not cancelled, log but continue
        if (!_isCancelled && !_isDisposed) {
          print(
              'Frame extraction failed, but project will be created without frames');
        }
      }

      // Only save and notify if not cancelled or disposed
      if (!_isCancelled && !_isDisposed) {
        await DBHelper.createProject(_currentProject!);
        _resetTempAdjustments();
        _safeNotifyListeners();
      }
    } catch (e) {
      if (!_isDisposed && !_isCancelled) {
        _setError('Failed to create project: $e');
      }
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  /// Apply filter using OpenCV with progress tracking
  Future<void> applyFilter(FilterMode filterMode) async {
    if (_currentProject == null) return;

    // Reset cancellation state
    _isCancelled = false;

    // Set loading state immediately for responsive UI
    _setLoading(true);
    _clearError();
    _resetProgress();

    // Add a microtask to ensure UI updates before heavy processing
    await Future.delayed(Duration.zero);

    try {
      final updatedProject = await OpenCVHelper.applyVideoFilterWithProgress(
        _currentProject!,
        filterMode,
        onProgress: _safeUpdateProgress,
        isCancelled: () => _isCancelled || _isDisposed,
      );

      // Only update if not cancelled and not disposed
      if (!_isCancelled && !_isDisposed) {
        _currentProject = updatedProject;
        await DBHelper.updateProject(_currentProject!);
        _safeNotifyListeners();
      }
    } catch (e) {
      if (!_isDisposed) {
        _setError('Failed to apply filter: $e');
      }
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
        _resetProgress();
      }
    }
  }

  /// Cancel current processing operation
  void cancelProcessing() {
    _isCancelled = true;
    _setLoading(false);
    _resetProgress();
    _safeNotifyListeners();
  }

  /// Safe progress update that checks if provider is disposed
  void _safeUpdateProgress(double progress, String status) {
    if (_isDisposed || _isCancelled) return;

    try {
      _processingProgress = progress.clamp(0.0, 1.0);
      _processingStatus = status;
      _safeNotifyListeners();
    } catch (e) {
      // Silently ignore errors if provider is disposed
    }
  }

  /// Safe notifyListeners that checks disposal state
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      try {
        notifyListeners();
      } catch (e) {
        // Provider might have been disposed between the check and the call
        _isDisposed = true;
      }
    }
  }

  /// Update temporary brightness adjustment
  void updateTempBrightness(int value) {
    _tempBrightness = value.clamp(-100, 100);
    _safeNotifyListeners();
  }

  /// Update temporary contrast adjustment
  void updateTempContrast(int value) {
    _tempContrast = value.clamp(-100, 100);
    _safeNotifyListeners();
  }

  /// Update temporary saturation adjustment
  void updateTempSaturation(int value) {
    _tempSaturation = value.clamp(-100, 100);
    _safeNotifyListeners();
  }

  /// Update temporary blur adjustment
  void updateTempBlur(int value) {
    _tempBlur = value.clamp(0, 100);
    _safeNotifyListeners();
  }

  /// Update temporary temperature adjustment
  void updateTempTemperature(int value) {
    _tempTemperature = value.clamp(-100, 100);
    _safeNotifyListeners();
  }

  /// Update temporary sharpen adjustment
  void updateTempSharpen(int value) {
    _tempSharpen = value.clamp(-100, 100);
    _safeNotifyListeners();
  }

  /// Update temporary speed (0.5 - 2.0)
  void updateTempSpeed(double value) {
    _tempSpeed = value.clamp(0.5, 2.0);
    _safeNotifyListeners();
  }

  /// Apply all video adjustments
  Future<void> applyVideoAdjustments() async {
    if (_currentProject == null) return;

    _setLoading(true);
    _clearError();

    try {
      // Update project with new values (accumulate adjustments)
      _currentProject = _currentProject!.copyWith(
        brightness: (_currentProject!.brightness ?? 0) + _tempBrightness,
        contrast: (_currentProject!.contrast ?? 0) + _tempContrast,
        saturation: (_currentProject!.saturation ?? 0) + _tempSaturation,
        blur: (_currentProject!.blur ?? 0) + _tempBlur,
        temperature: (_currentProject!.temperature ?? 0) + _tempTemperature,
        sharpen: (_currentProject!.sharpen ?? 0) + _tempSharpen,
        speed: _tempSpeed, // Speed is absolute, not accumulated
      );

      await DBHelper.updateProject(_currentProject!);
      _resetTempAdjustments();
      _safeNotifyListeners();
    } catch (e) {
      _setError('Failed to apply adjustments: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Reset all temporary adjustments
  void resetTempAdjustments() {
    _resetTempAdjustments();
    _safeNotifyListeners();
  }

  /// Update crop rect
  Future<void> updateCropRect(CropRectData? cropRect) async {
    if (_currentProject == null) return;

    try {
      _currentProject = _currentProject!.copyWith(cropRect: cropRect);
      await DBHelper.updateProject(_currentProject!);
      _safeNotifyListeners();
    } catch (e) {
      _setError('Failed to update crop: $e');
    }
  }

  /// Update aspect ratio mode
  Future<void> updateAspectRatioMode(AspectRatioMode mode) async {
    if (_currentProject == null) return;

    try {
      _currentProject = _currentProject!.copyWith(aspectRatioMode: mode);
      await DBHelper.updateProject(_currentProject!);
      _safeNotifyListeners();
    } catch (e) {
      _setError('Failed to update aspect ratio: $e');
    }
  }

  /// Save project with new name
  Future<void> saveProjectAs(String newName) async {
    if (_currentProject == null) return;

    try {
      // Create new project with different ID
      final newProject = VideoProject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: newName,
        originalVideo: _currentProject!.originalVideo,
        processedVideo: _currentProject!.processedVideo,
        filterMode: _currentProject!.filterMode,
        aspectRatioMode: _currentProject!.aspectRatioMode,
        cropRect: _currentProject!.cropRect,
        brightness: _currentProject!.brightness,
        contrast: _currentProject!.contrast,
        saturation: _currentProject!.saturation,
        blur: _currentProject!.blur,
        temperature: _currentProject!.temperature,
        sharpen: _currentProject!.sharpen,
        speed: _currentProject!.speed,
      );

      await DBHelper.createProject(newProject);
      _currentProject = newProject;
      _safeNotifyListeners();
    } catch (e) {
      _setError('Failed to save project: $e');
    }
  }

  /// Save current project state to database
  Future<void> saveCurrentState() async {
    if (_currentProject == null) return;

    try {
      await DBHelper.updateProject(_currentProject!);
    } catch (e) {
      _setError('Failed to save project state: $e');
    }
  }

  /// Clear current project
  void clearProject() {
    _currentProject = null;
    _resetTempAdjustments();
    _clearError();
    _safeNotifyListeners();
  }

  /// Get video duration (if available)
  Future<Duration?> getVideoDuration() async {
    if (_currentProject == null) return null;

    try {
      // This would typically use a video player package to get duration
      // For now, return null as it depends on video processing libraries
      return null;
    } catch (e) {
      _setError('Failed to get video duration: $e');
      return null;
    }
  }

  /// Get video resolution (if available)
  Future<Size?> getVideoResolution() async {
    if (_currentProject == null) return null;

    try {
      // This would typically use a video processing package to get resolution
      // For now, return null as it depends on video processing libraries
      return null;
    } catch (e) {
      _setError('Failed to get video resolution: $e');
      return null;
    }
  }

  /// Export processed video
  Future<String?> exportVideo({
    String? customName,
    String? exportPath,
  }) async {
    if (_currentProject == null) return null;

    _setLoading(true);
    _clearError();

    try {
      final sourceFile = File(_currentProject!.processedVideo);
      if (!await sourceFile.exists()) {
        throw Exception('Processed video file not found');
      }

      // Generate export filename
      final fileName = customName ?? '${_currentProject!.name}_export';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final exportFileName = '${fileName}_$timestamp.mp4';

      // Determine export path
      String finalExportPath;
      if (exportPath != null) {
        finalExportPath = '$exportPath/$exportFileName';
      } else {
        // Default to app documents directory
        final directory = await getApplicationDocumentsDirectory();
        final exportDir = Directory('${directory.path}/exports');

        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }

        finalExportPath = '${exportDir.path}/$exportFileName';
      }

      // Copy processed video to export location
      await sourceFile.copy(finalExportPath);

      return finalExportPath;
    } catch (e) {
      _setError('Failed to export video: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    if (_isDisposed) return;

    _isLoading = loading;
    if (loading) _clearError();
    _safeNotifyListeners();
  }

  void _setError(String error) {
    if (_isDisposed) return;

    _error = error;
    _isLoading = false;
    _safeNotifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _resetTempAdjustments() {
    _tempBrightness = 0;
    _tempContrast = 0;
    _tempSaturation = 0;
    _tempBlur = 0;
    _tempTemperature = 0;
    _tempSharpen = 0;
    _tempSpeed = 1.0;
  }

  // Progress tracking methods
  void _updateProgress(double progress, String status) {
    _processingProgress = progress.clamp(0.0, 1.0);
    _processingStatus = status;
    notifyListeners();
  }

  void _resetProgress() {
    _processingProgress = 0.0;
    _processingStatus = '';
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isCancelled = true;
    super.dispose();
  }
}
