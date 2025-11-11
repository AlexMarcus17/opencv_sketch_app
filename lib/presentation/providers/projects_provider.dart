import 'package:flutter/cupertino.dart';
import 'package:injectable/injectable.dart';
import '../../data/models/project.dart';
import '../../data/models/enums.dart';
import '../../data/helpers/db_helper.dart';

@singleton
class ProjectsProvider extends ChangeNotifier {
  List<Project> _projects = [];
  List<Project> _filteredProjects = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  FilterMode? _filterByMode;
  ProjectType? _filterByType;

  // Getters
  List<Project> get projects => _filteredProjects;
  List<Project> get allProjects => _projects;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get projectsCount => _projects.length;
  String get searchQuery => _searchQuery;
  FilterMode? get filterByMode => _filterByMode;
  ProjectType? get filterByType => _filterByType;

  // Filtered getters
  List<ImageProject> get imageProjects =>
      _projects.whereType<ImageProject>().toList();
  List<VideoProject> get videoProjects =>
      _projects.whereType<VideoProject>().toList();

  /// Initialize and load all projects
  Future<void> loadProjects() async {
    _setLoading(true);
    _clearError();

    try {
      _projects = DBHelper.getAllProjects();
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load projects: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create new image project
  Future<String> createImageProject({
    required String name,
    required String imagePath,
    FilterMode filterMode = FilterMode.original,
    AspectRatioMode aspectRatioMode = AspectRatioMode.original,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      final project = ImageProject(
        id: id,
        name: name,
        originalImage: imagePath,
        processedImage: imagePath,
        filterMode: filterMode,
        aspectRatioMode: aspectRatioMode,
      );

      await DBHelper.createProject(project);
      _projects.add(project);
      _applyFilters();
      notifyListeners();

      return id;
    } catch (e) {
      _setError('Failed to create image project: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Create new video project
  Future<String> createVideoProject({
    required String name,
    required String videoPath,
    FilterMode filterMode = FilterMode.original,
    AspectRatioMode aspectRatioMode = AspectRatioMode.original,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      final project = VideoProject(
        id: id,
        name: name,
        originalVideo: videoPath,
        processedVideo: videoPath,
        filterMode: filterMode,
        aspectRatioMode: aspectRatioMode,
      );

      await DBHelper.createProject(project);
      _projects.add(project);
      _applyFilters();
      notifyListeners();

      return id;
    } catch (e) {
      _setError('Failed to create video project: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Get project by ID
  Project? getProject(String id) {
    try {
      return _projects.firstWhere((project) => project.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Update project by ID
  Future<void> updateProject(String id, Project updatedProject) async {
    _setLoading(true);
    _clearError();

    try {
      if (updatedProject.id != id) {
        throw Exception('Project ID mismatch');
      }

      await DBHelper.updateProject(updatedProject);

      final index = _projects.indexWhere((project) => project.id == id);
      if (index != -1) {
        _projects[index] = updatedProject;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update project: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete project by ID
  Future<void> deleteProject(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await DBHelper.deleteProject(id);
      _projects.removeWhere((project) => project.id == id);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete project: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete multiple projects by IDs
  Future<void> deleteProjects(List<String> ids) async {
    _setLoading(true);
    _clearError();

    try {
      for (final id in ids) {
        await DBHelper.deleteProject(id);
      }

      _projects.removeWhere((project) => ids.contains(project.id));
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete projects: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Rename project by ID
  Future<void> renameProject(String id, String newName) async {
    try {
      final project = getProject(id);
      if (project == null) {
        throw Exception('Project not found');
      }

      Project updatedProject;
      if (project is ImageProject) {
        updatedProject = project.copyWith(name: newName);
      } else if (project is VideoProject) {
        updatedProject = project.copyWith(name: newName);
      } else {
        throw Exception('Unknown project type');
      }

      await updateProject(id, updatedProject);
    } catch (e) {
      _setError('Failed to rename project: $e');
    }
  }

  /// Duplicate project by ID
  Future<String?> duplicateProject(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final originalProject = getProject(id);
      if (originalProject == null) {
        throw Exception('Project not found');
      }

      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final newName = '${originalProject.name} (Copy)';

      Project duplicatedProject;
      if (originalProject is ImageProject) {
        duplicatedProject = ImageProject(
          id: newId,
          name: newName,
          originalImage: originalProject.originalImage,
          processedImage: originalProject.processedImage,
          filterMode: originalProject.filterMode,
          aspectRatioMode: originalProject.aspectRatioMode,
          cropRect: originalProject.cropRect,
          brightness: originalProject.brightness,
          contrast: originalProject.contrast,
          saturation: originalProject.saturation,
          temperature: originalProject.temperature,
          sharpen: originalProject.sharpen,
          blur: originalProject.blur,
        );
      } else if (originalProject is VideoProject) {
        duplicatedProject = VideoProject(
          id: newId,
          name: newName,
          originalVideo: originalProject.originalVideo,
          processedVideo: originalProject.processedVideo,
          filterMode: originalProject.filterMode,
          aspectRatioMode: originalProject.aspectRatioMode,
          cropRect: originalProject.cropRect,
          temperature: originalProject.temperature,
          sharpen: originalProject.sharpen,
          blur: originalProject.blur,
        );
      } else {
        throw Exception('Unknown project type');
      }

      await DBHelper.createProject(duplicatedProject);
      _projects.add(duplicatedProject);
      _applyFilters();
      notifyListeners();

      return newId;
    } catch (e) {
      _setError('Failed to duplicate project: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Search projects by name
  void searchProjects(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Filter projects by filter mode
  void filterByFilterMode(FilterMode? mode) {
    _filterByMode = mode;
    _applyFilters();
    notifyListeners();
  }

  /// Filter projects by type
  void filterByProjectType(ProjectType? type) {
    _filterByType = type;
    _applyFilters();
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _filterByMode = null;
    _filterByType = null;
    _applyFilters();
    notifyListeners();
  }

  /// Get projects by filter mode
  List<Project> getProjectsByFilterMode(FilterMode filterMode) {
    return _projects
        .where((project) => project.filterMode == filterMode)
        .toList();
  }

  /// Get recent projects (last 10)
  List<Project> getRecentProjects({int limit = 10}) {
    final sortedProjects = List<Project>.from(_projects);
    sortedProjects
        .sort((a, b) => b.id.compareTo(a.id)); // Sort by ID (timestamp)
    return sortedProjects.take(limit).toList();
  }

  /// Check if project exists
  bool projectExists(String id) {
    return _projects.any((project) => project.id == id);
  }

  /// Get project statistics
  Map<String, int> getProjectStats() {
    return {
      'total': _projects.length,
      'images': imageProjects.length,
      'videos': videoProjects.length,
      'original': getProjectsByFilterMode(FilterMode.original).length,
      'pencilSketch': getProjectsByFilterMode(FilterMode.pencilSketch).length,
      'charcoalSketch':
          getProjectsByFilterMode(FilterMode.charcoalSketch).length,
      'inkPen': getProjectsByFilterMode(FilterMode.inkPen).length,
      'colorSketch': getProjectsByFilterMode(FilterMode.colorSketch).length,
      'cartoon': getProjectsByFilterMode(FilterMode.cartoon).length,
      'techPen': getProjectsByFilterMode(FilterMode.techPen).length,
      'softPen': getProjectsByFilterMode(FilterMode.softPen).length,
      'noirSketch': getProjectsByFilterMode(FilterMode.noirSketch).length,
      'cartoon2': getProjectsByFilterMode(FilterMode.cartoon2).length,
      'storyboard': getProjectsByFilterMode(FilterMode.storyboard).length,
      'chalk': getProjectsByFilterMode(FilterMode.chalk).length,
      'feltPen': getProjectsByFilterMode(FilterMode.feltPen).length,
      'monochromeSketch':
          getProjectsByFilterMode(FilterMode.monochromeSketch).length,
      'splashSketch': getProjectsByFilterMode(FilterMode.splashSketch).length,
      'coloringBook': getProjectsByFilterMode(FilterMode.coloringBook).length,
      'waxSketch': getProjectsByFilterMode(FilterMode.waxSketch).length,
      'paperSketch': getProjectsByFilterMode(FilterMode.paperSketch).length,
      'neonSketch': getProjectsByFilterMode(FilterMode.neonSketch).length,
      'anime': getProjectsByFilterMode(FilterMode.anime).length,
      'comicBook': getProjectsByFilterMode(FilterMode.comicBook).length,
    };
  }

  /// Refresh projects from database
  Future<void> refreshProjects() async {
    await loadProjects();
  }

  // Private helper methods
  void _applyFilters() {
    _filteredProjects = List<Project>.from(_projects);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      _filteredProjects = _filteredProjects
          .where((project) => project.name.toLowerCase().contains(query))
          .toList();
    }

    // Apply filter mode filter
    if (_filterByMode != null) {
      _filteredProjects = _filteredProjects
          .where((project) => project.filterMode == _filterByMode)
          .toList();
    }

    // Apply project type filter
    if (_filterByType != null) {
      switch (_filterByType!) {
        case ProjectType.image:
          _filteredProjects = _filteredProjects
              .whereType<ImageProject>()
              .cast<Project>()
              .toList();
          break;
        case ProjectType.video:
          _filteredProjects = _filteredProjects
              .whereType<VideoProject>()
              .cast<Project>()
              .toList();
          break;
      }
    }
  }

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
}

/// Enum for project type filtering
enum ProjectType {
  image,
  video,
}
