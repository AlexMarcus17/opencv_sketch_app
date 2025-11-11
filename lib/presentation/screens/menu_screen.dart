// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:sketch/application/utils.dart';
import 'settings_screen.dart';
import 'projects_screen.dart';
import 'image_editor_screen.dart';
import 'video_editor_screen.dart';
import 'package:sketch/presentation/providers/projects_provider.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    Future.delayed(const Duration(seconds: 0), () {
      GetIt.I.get<SharedPreferences>().setBool('oldUser', true);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Safe area content
          SafeArea(
            child: Column(
              children: [
                // Top row with icons
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Share icon (left)
                      GestureDetector(
                        onTap: () {
                          Utils.shareApp();
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: CupertinoColors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.share,
                            color: CupertinoColors.white,
                            size: 24,
                          ),
                        ),
                      ),

                      // Settings icon (right)
                      GestureDetector(
                        onTap: () {
                          SettingsScreen.showSettingsSheet(context);
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: CupertinoColors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.settings,
                            color: CupertinoColors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Spacer to center the buttons
                const Spacer(),

                // Main menu buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    children: [
                      // Take a photo button
                      _buildMenuButton(
                        icon: CupertinoIcons.camera,
                        text: 'Take a photo',
                        onPressed: _takePhoto,
                      ),

                      const SizedBox(height: 20),

                      if (Platform.isIOS)
                        _buildMenuButton(
                          icon: CupertinoIcons.videocam_circle_fill,
                          text: 'Take a video',
                          onPressed: _takeVideo,
                        ),
                      if (Platform.isIOS) const SizedBox(height: 20),

                      // Choose from gallery button
                      _buildMenuButton(
                        icon: CupertinoIcons.photo,
                        text: 'Choose from gallery',
                        onPressed: _chooseFromGallery,
                      ),

                      const SizedBox(height: 20),

                      // My Projects button
                      _buildMenuButton(
                        icon: CupertinoIcons.folder,
                        text: 'My Projects',
                        onPressed: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => const ProjectsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Spacer for bottom
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        final projectId = await _createImageProject(photo);
        if (projectId != null) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => ImageEditorScreen(projectId: projectId),
            ),
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to take photo: $e');
    }
  }

  Future<void> _takeVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        final projectId = await _createVideoProject(video);
        if (projectId != null) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => VideoEditorScreen(projectId: projectId),
            ),
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to take video: $e');
    }
  }

  Future<void> _chooseFromGallery() async {
    try {
      final result = Platform.isIOS
          ? await showCupertinoModalPopup<String>(
              context: context,
              builder: (BuildContext context) {
                return CupertinoActionSheet(
                  title: const Text('Choose Media Type'),
                  message: const Text(
                      'What would you like to select from your gallery?'),
                  actions: [
                    CupertinoActionSheetAction(
                      onPressed: () => Navigator.pop(context, 'image'),
                      child: const Text('Image'),
                    ),
                    CupertinoActionSheetAction(
                      onPressed: () => Navigator.pop(context, 'video'),
                      child: const Text('Video'),
                    ),
                  ],
                  cancelButton: CupertinoActionSheetAction(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                );
              },
            )
          : "image";

      if (result == 'image') {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (image != null) {
          final projectId = await _createImageProject(image);
          if (projectId != null) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => ImageEditorScreen(projectId: projectId),
              ),
            );
          }
        }
      } else if (result == 'video') {
        final XFile? video = await _picker.pickVideo(
          source: ImageSource.gallery,
        );
        if (video != null) {
          final projectId = await _createVideoProject(video);
          if (projectId != null) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => VideoEditorScreen(projectId: projectId),
              ),
            );
          }
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to select from gallery: $e');
    }
  }

  Future<String?> _createImageProject(XFile image) async {
    try {
      // Copy image to permanent location
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/original_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'image_$timestamp.jpg';
      final permanentPath = '${imagesDir.path}/$fileName';

      await File(image.path).copy(permanentPath);

      // Create project using ProjectsProvider
      final provider = Provider.of<ProjectsProvider>(context, listen: false);
      final projectId = await provider.createImageProject(
        name: 'Photo $timestamp',
        imagePath: permanentPath,
      );

      return projectId;
    } catch (e) {
      _showErrorDialog('Failed to create image project: $e');
      return null;
    }
  }

  Future<String?> _createVideoProject(XFile video) async {
    try {
      // Copy video to permanent location
      final directory = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${directory.path}/original_videos');
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'video_$timestamp.mp4';
      final permanentPath = '${videosDir.path}/$fileName';

      await File(video.path).copy(permanentPath);

      // Create project using ProjectsProvider
      final provider = Provider.of<ProjectsProvider>(context, listen: false);
      final projectId = await provider.createVideoProject(
        name: 'Video $timestamp',
        videoPath: permanentPath,
      );

      return projectId;
    } catch (e) {
      _showErrorDialog('Failed to create video project: $e');
      return null;
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
          onPressed: onPressed,
          color: const Color.fromARGB(255, 215, 1, 133), //Color(0xFFE91E63)
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: CupertinoColors.white,
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
