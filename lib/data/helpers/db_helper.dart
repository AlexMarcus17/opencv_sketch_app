import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import '../models/project.dart';
import '../models/enums.dart';

@singleton
class DBHelper {
  static const String _projectsBoxName = 'projects';
  static Box<Project>? _projectsBox;

  /// Initialize Hive database
  static Future<void> init() async {
    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(CropRectDataAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ImageProjectAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(VideoProjectAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(FilterModeAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(AspectRatioModeAdapter());
      }

      // Open boxes
      _projectsBox = await Hive.openBox<Project>(_projectsBoxName);
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  /// Get projects box
  static Box<Project> get _box {
    if (_projectsBox == null || !_projectsBox!.isOpen) {
      throw Exception('Database not initialized. Call DBHelper.init() first.');
    }
    return _projectsBox!;
  }

  /// Create a new project
  static Future<void> createProject(Project project) async {
    try {
      await _box.put(project.id, project);
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  /// Get project by ID
  static Project? getProject(String id) {
    try {
      return _box.get(id);
    } catch (e) {
      throw Exception('Failed to get project: $e');
    }
  }

  /// Get all projects
  static List<Project> getAllProjects() {
    try {
      return _box.values.toList();
    } catch (e) {
      throw Exception('Failed to get all projects: $e');
    }
  }

  /// Get all image projects
  static List<ImageProject> getAllImageProjects() {
    try {
      return _box.values.whereType<ImageProject>().toList();
    } catch (e) {
      throw Exception('Failed to get image projects: $e');
    }
  }

  /// Get all video projects
  static List<VideoProject> getAllVideoProjects() {
    try {
      return _box.values.whereType<VideoProject>().toList();
    } catch (e) {
      throw Exception('Failed to get video projects: $e');
    }
  }

  /// Update an existing project
  static Future<void> updateProject(Project project) async {
    try {
      if (!_box.containsKey(project.id)) {
        throw Exception('Project with ID ${project.id} not found');
      }
      await _box.put(project.id, project);
    } catch (e) {
      throw Exception('Failed to update project: $e');
    }
  }

  /// Delete project by ID
  static Future<void> deleteProject(String id) async {
    try {
      if (!_box.containsKey(id)) {
        throw Exception('Project with ID $id not found');
      }
      await _box.delete(id);
    } catch (e) {
      throw Exception('Failed to delete project: $e');
    }
  }

  /// Delete all projects
  static Future<void> deleteAllProjects() async {
    try {
      await _box.clear();
    } catch (e) {
      throw Exception('Failed to delete all projects: $e');
    }
  }

  /// Check if project exists
  static bool projectExists(String id) {
    try {
      return _box.containsKey(id);
    } catch (e) {
      throw Exception('Failed to check project existence: $e');
    }
  }

  /// Get projects count
  static int getProjectsCount() {
    try {
      return _box.length;
    } catch (e) {
      throw Exception('Failed to get projects count: $e');
    }
  }

  /// Get projects by filter mode
  static List<Project> getProjectsByFilterMode(FilterMode filterMode) {
    try {
      return _box.values
          .where((project) => project.filterMode == filterMode)
          .toList();
    } catch (e) {
      throw Exception('Failed to get projects by filter mode: $e');
    }
  }

  /// Search projects by name
  static List<Project> searchProjectsByName(String searchTerm) {
    try {
      final term = searchTerm.toLowerCase();
      return _box.values
          .where((project) => project.name.toLowerCase().contains(term))
          .toList();
    } catch (e) {
      throw Exception('Failed to search projects: $e');
    }
  }

  /// Close the database
  static Future<void> close() async {
    try {
      if (_projectsBox != null && _projectsBox!.isOpen) {
        await _projectsBox!.close();
        _projectsBox = null;
      }
    } catch (e) {
      throw Exception('Failed to close database: $e');
    }
  }

  /// Check if database is initialized
  static bool get isInitialized {
    return _projectsBox != null && _projectsBox!.isOpen;
  }
}
