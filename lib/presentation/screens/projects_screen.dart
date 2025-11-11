// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/projects_provider.dart';
import '../../data/models/project.dart';
import '../../data/models/enums.dart';
import 'image_editor_screen.dart';
import 'video_editor_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  ProjectsProvider? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = Provider.of<ProjectsProvider>(context, listen: false);
      _provider?.loadProjects();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Hide keyboard when tapping anywhere
        FocusScope.of(context).unfocus();
      },
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('My Projects'),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            child: const Icon(CupertinoIcons.back),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showFilterOptions,
            child: const Icon(CupertinoIcons.slider_horizontal_3),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: CupertinoSearchTextField(
                  controller: _searchController,
                  placeholder: 'Search projects...',
                  onChanged: (value) {
                    _provider?.searchProjects(value);
                  },
                ),
              ),

              // Filter indicators
              Consumer<ProjectsProvider>(
                builder: (context, provider, child) {
                  if (provider.searchQuery.isNotEmpty ||
                      provider.filterByType != null) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          if (provider.searchQuery.isNotEmpty)
                            _buildFilterChip(
                                'Search: "${provider.searchQuery}"'),
                          if (provider.filterByType != null)
                            _buildFilterChip(_getProjectTypeDisplayName(
                                provider.filterByType!)),
                          const Spacer(),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              _searchController.clear();
                              provider.clearFilters();
                            },
                            child: const Text('Clear',
                                style: TextStyle(fontSize: 14)),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Projects grid
              Expanded(
                child: Consumer<ProjectsProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(
                        child: CupertinoActivityIndicator(radius: 16),
                      );
                    }

                    if (provider.error != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.exclamationmark_triangle,
                              size: 64,
                              color: CupertinoColors.systemRed,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Error loading projects',
                              style: TextStyle(
                                fontSize: 18,
                                color: CupertinoColors.systemRed,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              provider.error!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.systemGrey2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            CupertinoButton(
                              onPressed: () => provider.refreshProjects(),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (provider.projects.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.folder,
                              size: 64,
                              color: CupertinoColors.systemGrey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No projects yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Create your first project by picking images or videos',
                              style: TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.systemGrey2,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: provider.projects.length,
                        itemBuilder: (context, index) {
                          final project = provider.projects[index];
                          return _buildProjectItem(project);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectItem(Project project) {
    return GestureDetector(
      onTap: () => _showProjectActionSheet(context, project),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: CupertinoColors.systemGrey6,
          border: Border.all(
            color: CupertinoColors.systemGrey4,
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildProjectPreview(project),
        ),
      ),
    );
  }

  Widget _buildProjectPreview(Project project) {
    String imagePath;
    if (project is ImageProject) {
      imagePath = project.processedImage;
    } else if (project is VideoProject) {
      // For video projects, use processed video path as placeholder
      // In a real app, you'd extract a thumbnail frame
      imagePath = project.processedVideo;
    } else {
      return _buildPlaceholder(CupertinoIcons.doc, 'Unknown type');
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (project is ImageProject)
          Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder(
                  CupertinoIcons.photo, 'Failed to load image');
            },
          )
        else
          // Video thumbnail placeholder
          Container(
            color: CupertinoColors.black,
            child: const Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.videocam_fill,
                        size: 32,
                        color: CupertinoColors.white,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Video Project',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Project name (top right)
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 65, 65, 65).withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              project.name,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Project type icon (bottom left)
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: project is ImageProject
                  ? CupertinoColors.systemBlue.withOpacity(0.9)
                  : CupertinoColors.systemPurple.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              project is ImageProject
                  ? CupertinoIcons.camera_fill
                  : CupertinoIcons.videocam_fill,
              color: CupertinoColors.white,
              size: 16,
            ),
          ),
        ),

        // Filter indicator (top left)
        if (project.filterMode != FilterMode.original)
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGreen.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getFilterModeDisplayName(project.filterMode).toUpperCase(),
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder(IconData icon, String text) {
    return Container(
      color: CupertinoColors.systemGrey5,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.systemBlue.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: CupertinoColors.systemBlue,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showProjectActionSheet(BuildContext context, Project project) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text(project.name),
          message: Text(
            project is ImageProject ? 'Image Project' : 'Video Project',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _editProject(project);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.pencil, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _duplicateProject(project);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.doc_on_doc, size: 18),
                  SizedBox(width: 8),
                  Text('Duplicate'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _renameProject(project);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.textformat, size: 18),
                  SizedBox(width: 8),
                  Text('Rename'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _deleteProject(project);
              },
              isDestructiveAction: true,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.delete, size: 18),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  void _showFilterOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text('Filter Projects'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _provider?.clearFilters();
              },
              child: const Text('All Projects'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _provider?.filterByProjectType(ProjectType.image);
              },
              child: const Text('Only Images'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _provider?.filterByProjectType(ProjectType.video);
              },
              child: const Text('Only Videos'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  void _editProject(Project project) {
    if (project is ImageProject) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => ImageEditorScreen(projectId: project.id),
        ),
      );
    } else if (project is VideoProject) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => VideoEditorScreen(projectId: project.id),
        ),
      );
    }
  }

  void _duplicateProject(Project project) async {
    final provider = Provider.of<ProjectsProvider>(context, listen: false);
    await provider.duplicateProject(project.id);
  }

  void _renameProject(Project project) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        final controller = TextEditingController(text: project.name);
        return CupertinoAlertDialog(
          title: const Text('Rename Project'),
          content: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: CupertinoTextField(
              controller: controller,
              placeholder: 'Project name',
              autofocus: true,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            CupertinoDialogAction(
              child: const Text('Rename'),
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  final provider =
                      Provider.of<ProjectsProvider>(context, listen: false);
                  await provider.renameProject(project.id, controller.text);
                }
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteProject(Project project) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Delete Project'),
          content: Text(
              'Are you sure you want to delete "${project.name}"? This action cannot be undone.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Delete'),
              onPressed: () async {
                final provider =
                    Provider.of<ProjectsProvider>(context, listen: false);
                await provider.deleteProject(project.id);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  String _getFilterModeDisplayName(FilterMode mode) {
    switch (mode) {
      case FilterMode.original:
        return 'Original';
      case FilterMode.pencilSketch:
        return 'Pencil Sketch';
      case FilterMode.charcoalSketch:
        return 'Charcoal';
      case FilterMode.inkPen:
        return 'Ink Pen';
      case FilterMode.colorSketch:
        return 'Color Sketch';
      case FilterMode.cartoon:
        return 'Cartoon';
      case FilterMode.techPen:
        return 'Azure';
      case FilterMode.softPen:
        return 'Soft Pen';
      case FilterMode.noirSketch:
        return 'Noir Sketch';
      case FilterMode.cartoon2:
        return 'Marker';
      case FilterMode.storyboard:
        return 'Storyboard';
      case FilterMode.chalk:
        return 'Chalk';
      case FilterMode.feltPen:
        return 'Aquarel';
      case FilterMode.monochromeSketch:
        return 'Moss';
      case FilterMode.splashSketch:
        return 'Crimson';
      case FilterMode.coloringBook:
        return 'Coloring Book';
      case FilterMode.waxSketch:
        return 'Graphite';
      case FilterMode.paperSketch:
        return 'Invert';
      case FilterMode.neonSketch:
        return 'Neon Sketch';
      case FilterMode.anime:
        return 'Anime';
      case FilterMode.comicBook:
        return 'Dust';
    }
  }

  String _getProjectTypeDisplayName(ProjectType type) {
    switch (type) {
      case ProjectType.image:
        return 'Images';
      case ProjectType.video:
        return 'Videos';
    }
  }
}
