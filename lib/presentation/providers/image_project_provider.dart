import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:injectable/injectable.dart';
import '../../data/models/project.dart';
import '../../data/models/enums.dart';
import '../../data/helpers/opencv_helper.dart';
import '../../data/helpers/db_helper.dart';

@injectable
class ImageProjectProvider extends ChangeNotifier {
  ImageProject? _currentProject;
  bool _isLoading = false;
  String? _error;

  // Current adjustments (temporary values before applying)
  int _tempBrightness = 0;
  int _tempContrast = 0;
  int _tempSaturation = 0;
  int _tempTemperature = 0;
  int _tempSharpen = 0;
  int _tempBlur = 0;

  // Getters
  ImageProject? get currentProject => _currentProject;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProject => _currentProject != null;

  // Current adjustment getters
  int get tempBrightness => _tempBrightness;
  int get tempContrast => _tempContrast;
  int get tempSaturation => _tempSaturation;
  int get tempTemperature => _tempTemperature;
  int get tempSharpen => _tempSharpen;
  int get tempBlur => _tempBlur;

  // Applied adjustment getters
  int get appliedBrightness => _currentProject?.brightness ?? 0;
  int get appliedContrast => _currentProject?.contrast ?? 0;
  int get appliedSaturation => _currentProject?.saturation ?? 0;
  int get appliedTemperature => _currentProject?.temperature ?? 0;
  int get appliedSharpen => _currentProject?.sharpen ?? 0;
  int get appliedBlur => _currentProject?.blur ?? 0;

  /// Load existing project
  Future<void> loadProject(String projectId) async {
    _setLoading(true);
    _clearError();

    try {
      final project = DBHelper.getProject(projectId);
      if (project != null && project is ImageProject) {
        _currentProject = project;
        _resetTempAdjustments();
        notifyListeners();
      } else {
        _setError('Project not found or invalid type');
      }
    } catch (e) {
      _setError('Failed to load project: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create new project from image path
  Future<void> createProject({
    required String id,
    required String name,
    required String imagePath,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _currentProject = ImageProject(
        id: id,
        name: name,
        originalImage: imagePath,
        processedImage: imagePath, // Initially same as original
        filterMode: FilterMode.original,
        aspectRatioMode: AspectRatioMode.original,
      );

      await DBHelper.createProject(_currentProject!);
      _resetTempAdjustments();
      notifyListeners();
    } catch (e) {
      _setError('Failed to create project: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Apply filter using OpenCV
  Future<void> applyFilter(FilterMode filterMode) async {
    if (_currentProject == null) return;

    // Set loading state immediately for responsive UI
    _setLoading(true);
    _clearError();

    // Add a microtask to ensure UI updates before heavy processing
    await Future.delayed(Duration.zero);

    try {
      final updatedProject = await OpenCVHelper.applyImageFilter(
        _currentProject!,
        filterMode,
      );

      _currentProject = updatedProject;
      await DBHelper.updateProject(_currentProject!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to apply filter: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update temporary brightness adjustment
  void updateTempBrightness(int value) {
    _tempBrightness = value.clamp(-100, 100);
    notifyListeners();
  }

  /// Update temporary contrast adjustment
  void updateTempContrast(int value) {
    _tempContrast = value.clamp(-100, 100);
    notifyListeners();
  }

  /// Update temporary saturation adjustment
  void updateTempSaturation(int value) {
    _tempSaturation = value.clamp(-100, 100);
    notifyListeners();
  }

  /// Update temporary temperature adjustment
  void updateTempTemperature(int value) {
    _tempTemperature = value.clamp(-100, 100);
    notifyListeners();
  }

  /// Update temporary sharpen adjustment
  void updateTempSharpen(int value) {
    _tempSharpen = value.clamp(0, 100);
    notifyListeners();
  }

  /// Update temporary blur adjustment
  void updateTempBlur(int value) {
    _tempBlur = value.clamp(0, 100);
    notifyListeners();
  }

  /// Apply all image adjustments using Flutter image package
  Future<void> applyImageAdjustments() async {
    if (_currentProject == null) return;

    _setLoading(true);
    _clearError();

    try {
      // Read the base image (either original or filtered)
      final imageFile = File(_currentProject!.processedImage);
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Preserve original orientation by checking EXIF data
      image = img.bakeOrientation(image);

      // Apply adjustments sequentially
      if (_tempBrightness != 0) {
        image = _adjustBrightness(image, _tempBrightness);
      }

      if (_tempContrast != 0) {
        image = _adjustContrast(image, _tempContrast);
      }

      if (_tempSaturation != 0) {
        image = _adjustSaturation(image, _tempSaturation);
      }

      if (_tempTemperature != 0) {
        image = _adjustTemperature(image, _tempTemperature);
      }

      if (_tempSharpen > 0) {
        image = _applySharpen(image, _tempSharpen);
      }

      if (_tempBlur > 0) {
        image = _applyBlur(image, _tempBlur);
      }

      // Save the adjusted image
      final adjustedImagePath = await _saveAdjustedImage(image);

      // Update project with new values (accumulate adjustments)
      _currentProject = _currentProject!.copyWith(
        processedImage: adjustedImagePath,
        brightness: (_currentProject!.brightness ?? 0) + _tempBrightness,
        contrast: (_currentProject!.contrast ?? 0) + _tempContrast,
        saturation: (_currentProject!.saturation ?? 0) + _tempSaturation,
        temperature: (_currentProject!.temperature ?? 0) + _tempTemperature,
        sharpen: (_currentProject!.sharpen ?? 0) + _tempSharpen,
        blur: (_currentProject!.blur ?? 0) + _tempBlur,
      );

      await DBHelper.updateProject(_currentProject!);
      _resetTempAdjustments();
      notifyListeners();
    } catch (e) {
      _setError('Failed to apply adjustments: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Reset all temporary adjustments
  void resetTempAdjustments() {
    _resetTempAdjustments();
    notifyListeners();
  }

  /// Update crop rect
  Future<void> updateCropRect(CropRectData? cropRect) async {
    if (_currentProject == null) return;

    try {
      _currentProject = _currentProject!.copyWith(cropRect: cropRect);
      await DBHelper.updateProject(_currentProject!);
      notifyListeners();
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
      notifyListeners();
    } catch (e) {
      _setError('Failed to update aspect ratio: $e');
    }
  }

  /// Save new processed image path (e.g. after cropping)
  Future<void> updateProcessedImage(String newPath) async {
    if (_currentProject == null) return;
    try {
      _currentProject = _currentProject!.copyWith(processedImage: newPath);
      await DBHelper.updateProject(_currentProject!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to update processed image: $e');
    }
  }

  /// Save project with new name
  Future<void> saveProjectAs(String newName) async {
    if (_currentProject == null) return;

    try {
      _currentProject = _currentProject!.copyWith();
      // Create new project with different ID
      final newProject = ImageProject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: newName,
        originalImage: _currentProject!.originalImage,
        processedImage: _currentProject!.processedImage,
        filterMode: _currentProject!.filterMode,
        aspectRatioMode: _currentProject!.aspectRatioMode,
        cropRect: _currentProject!.cropRect,
        brightness: _currentProject!.brightness,
        contrast: _currentProject!.contrast,
        saturation: _currentProject!.saturation,
        temperature: _currentProject!.temperature,
        sharpen: _currentProject!.sharpen,
        blur: _currentProject!.blur,
      );

      await DBHelper.createProject(newProject);
      _currentProject = newProject;
      notifyListeners();
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
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _clearError();
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _resetTempAdjustments() {
    _tempBrightness = 0;
    _tempContrast = 0;
    _tempSaturation = 0;
    _tempTemperature = 0;
    _tempSharpen = 0;
    _tempBlur = 0;
  }

  // Image processing methods using Flutter image package
  img.Image _adjustBrightness(img.Image image, int value) {
    return img.adjustColor(image, brightness: value / 100.0);
  }

  img.Image _adjustContrast(img.Image image, int value) {
    return img.adjustColor(image, contrast: 1.0 + (value / 100.0));
  }

  img.Image _adjustSaturation(img.Image image, int value) {
    return img.adjustColor(image, saturation: 1.0 + (value / 100.0));
  }

  img.Image _adjustTemperature(img.Image image, int value) {
    // Temperature adjustment using gamma and exposure
    final factor = value / 100.0;
    return img.adjustColor(image,
        gamma: 1.0 + factor * 0.1, exposure: factor * 0.2);
  }

  img.Image _applySharpen(img.Image image, int value) {
    final amount = value / 100.0 * 2.0; // Scale to reasonable range

    final kernel = [
      0,
      -amount,
      0,
      -amount,
      1 + 4 * amount,
      -amount,
      0,
      -amount,
      0,
    ];

    return img.convolution(image, filter: kernel);
  }

  img.Image _applyBlur(img.Image image, int value) {
    final radius = (value / 100.0 * 10).round(); // Scale to 0-10 radius
    return img.gaussianBlur(image, radius: radius);
  }

  Future<String> _saveAdjustedImage(img.Image image) async {
    // Generate unique filename for adjusted image
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = '${_currentProject!.id}_adjusted_$timestamp.jpg';

    // Get app documents directory
    final directory = await getApplicationDocumentsDirectory();
    final adjustedDir = Directory('${directory.path}/adjusted_images');

    if (!await adjustedDir.exists()) {
      await adjustedDir.create(recursive: true);
    }

    final filePath = '${adjustedDir.path}/$filename';
    final file = File(filePath);

    // Encode and save
    final jpegBytes = img.encodeJpg(image, quality: 95);
    await file.writeAsBytes(jpegBytes);

    return filePath;
  }
}
