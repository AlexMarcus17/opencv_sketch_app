// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sketch/application/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:overlay_support/overlay_support.dart';
import '../providers/video_project_provider.dart';
import '../providers/projects_provider.dart';
import '../../application/injection.dart';
import '../../data/models/enums.dart';
import '../widgets/modern_tick_slider.dart';
import '../widgets/export_preference_dropdown.dart';

enum VideoEditMode { style, adjust, speed, export }

class VideoEditorScreen extends StatelessWidget {
  final String projectId;

  const VideoEditorScreen({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VideoProjectProvider>(
      create: (context) =>
          getIt<VideoProjectProvider>()..loadProject(projectId),
      child: const _VideoEditorContent(),
    );
  }
}

class _VideoEditorContent extends StatefulWidget {
  const _VideoEditorContent();

  @override
  State<_VideoEditorContent> createState() => _VideoEditorContentState();
}

class _VideoEditorContentState extends State<_VideoEditorContent> {
  VideoEditMode _currentEditMode = VideoEditMode.style;

  // Current selected adjustment for Edit mode
  String _selectedAdjustment = 'brightness';

  // Preserve scroll position of filter row
  final ScrollController _filterScrollController = ScrollController();

  // Whether the modern slider overlay is currently visible
  bool _showSlider = false;

  // Video player controller
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  String? _lastVideoPath;

  // Export preferences
  String _exportAudio = 'On';

  // Flag to prevent double navigation
  bool _isFinishing = false;

  // Loading state tracking
  bool _isProcessingNewFilter =
      false; // true = show full sheet, false = show simple indicator

  // Download state
  bool _isDownloading = false;

  // Define allowed filters for video processing (excluding problematic ones)
  static const List<FilterMode> _allowedVideoFilters = [
    FilterMode.original,
    FilterMode.charcoalSketch,
    FilterMode.inkPen,
    FilterMode.cartoon,
    FilterMode.softPen,
    FilterMode.noirSketch,
    FilterMode.storyboard,
    FilterMode.chalk,
    FilterMode.feltPen,
    FilterMode.monochromeSketch,
    FilterMode.splashSketch,
    FilterMode.coloringBook,
    FilterMode.paperSketch,
    FilterMode.neonSketch,
  ];

  /// Check if a filtered video already exists for the given filter
  Future<bool> _doesFilteredVideoExist(
      String projectId, FilterMode filterMode) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final processedDir =
          Directory(path.join(directory.path, 'processed_videos'));
      final fileName = '${projectId}_${filterMode.name}.mp4';
      final filePath = path.join(processedDir.path, fileName);
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    // Cancel any ongoing video processing to prevent disposed provider errors
    try {
      final provider = context.read<VideoProjectProvider>();
      if (provider.isLoading) {
        provider.cancelProcessing();
      }
    } catch (e) {
      // Provider might already be disposed, ignore error
    }

    // Dispose other resources
    _videoController?.dispose();
    _filterScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _showReviewPromptIfNeeded();
    super.initState();
  }

  void _showReviewPromptIfNeeded() async {
    final rating = GetIt.I.get<SharedPreferences>().getBool("rating");

    if (rating == null) {
      GetIt.I.get<SharedPreferences>().setBool("rating", true);
      Future.delayed(const Duration(seconds: 1)).then((value) {
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (BuildContext context) {
              return CupertinoAlertDialog(
                title: const Text("Enjoying Our App?"),
                content: const Text("We'd love to hear your feedback."),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () {
                      Navigator.pop(context);
                      showCupertinoDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return CupertinoAlertDialog(
                            title: const Text("Thanks for the feedback!"),
                            content: const Text(
                                "We'd really appreciate it if you could let us know how we can improve."),
                            actions: [
                              CupertinoDialogAction(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text("Cancel"),
                              ),
                              CupertinoDialogAction(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  final Uri emailUri = Uri(
                                    scheme: 'mailto',
                                    path: 'alphasoftgames@gmail.com',
                                  );

                                  if (await canLaunchUrl(emailUri)) {
                                    await launchUrl(emailUri,
                                        mode: LaunchMode.externalApplication);
                                  } else {
                                    toast('Could not open email app');
                                  }
                                },
                                child: const Text("Tell Us"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text("No"),
                  ),
                  CupertinoDialogAction(
                    onPressed: () {
                      Navigator.pop(context);
                      InAppReview.instance.requestReview();
                    },
                    child: const Text("Yes"),
                  ),
                ],
              );
            },
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: fifthColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: fifthColor,
        middle: Text(
          _getEditModeTitle(_currentEditMode),
          style: const TextStyle(color: CupertinoColors.white),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.white),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () async {
            // Prevent double navigation
            if (_isFinishing) return;
            _isFinishing = true;

            try {
              // Apply adjustments and finish
              final provider = context.read<VideoProjectProvider>();

              if (provider.tempBrightness != 0 ||
                  provider.tempContrast != 0 ||
                  provider.tempSaturation != 0 ||
                  provider.tempTemperature != 0 ||
                  provider.tempSharpen != 0 ||
                  provider.tempBlur != 0 ||
                  provider.tempSpeed != 1.0) {
                await provider.applyVideoAdjustments();
              }

              // Update the projects provider with the current project state
              if (provider.currentProject != null) {
                final projectsProvider =
                    Provider.of<ProjectsProvider>(context, listen: false);
                await projectsProvider.updateProject(
                  provider.currentProject!.id,
                  provider.currentProject!,
                );
              }

              if (mounted) {
                Navigator.pop(context);
              }
            } finally {
              _isFinishing = false;
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: CupertinoColors.systemPurple,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Finish',
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      child: Consumer<VideoProjectProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            // Show different loading states based on whether we're processing a new filter
            if (_isProcessingNewFilter) {
              // Full loading sheet for new filter processing
              return Container(
                color: fifthColor,
                child: Center(
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CupertinoColors.systemGrey4.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const CupertinoActivityIndicator(
                            radius: 20,
                            color: CupertinoColors.systemBlue,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Processing Video...',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${provider.processingPercentage}% Complete',
                          style: TextStyle(
                            color: CupertinoColors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Progress bar
                        Container(
                          width: 200,
                          height: 4,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey4.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: provider.processingProgress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemBlue,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        if (provider.processingStatus.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            provider.processingStatus,
                            style: TextStyle(
                              color: CupertinoColors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            } else {
              // Simple circular indicator for existing filter loading
              return const Center(
                child: CupertinoActivityIndicator(
                  radius: 16,
                  color: CupertinoColors.white,
                ),
              );
            }
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
                  Text(
                    'Error: ${provider.error}',
                    style: const TextStyle(
                      color: CupertinoColors.systemRed,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton(
                    onPressed: () =>
                        provider.loadProject(provider.currentProject?.id ?? ''),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!provider.hasProject) {
            return const Center(
              child: Text(
                'No project loaded',
                style: TextStyle(color: CupertinoColors.white),
              ),
            );
          }

          // Initialize video controller if not done yet or if video path changed
          if (_videoController == null ||
              (_lastVideoPath != provider.currentProject?.processedVideo)) {
            _lastVideoPath = provider.currentProject?.processedVideo;
            _initializeVideoController(provider);
          }

          return Column(
            children: [
              const SizedBox(height: 6),
              // Video navigation/scrubber
              _buildVideoNavigation(),

              // Video display area with effects
              Expanded(
                child: _buildVideoArea(provider),
              ),

              // Controls area based on edit mode
              _buildControlsArea(provider),

              // Bottom navigation
              _buildBottomNavigation(),
            ],
          );
        },
      ),
    );
  }

  void _initializeVideoController(VideoProjectProvider provider) {
    if (provider.currentProject != null) {
      // Dispose previous controller if it exists
      _videoController?.dispose();
      _videoController = null;
      _isVideoInitialized = false;

      _videoController = VideoPlayerController.file(
        File(provider.currentProject!.processedVideo),
      )..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
            // Enable looping
            _videoController!.setLooping(true);
            // Set the correct playback speed from saved project
            final savedSpeed = provider.currentProject!.speed ?? 1.0;
            _videoController!.setPlaybackSpeed(savedSpeed);
          }
        });
    }
  }

  Widget _buildVideoNavigation() {
    return Container(
      //color: Color.fromARGB(255, 29, 50, 125),
      height: 48, // Increased height for better slider
      decoration: const BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: Color.fromARGB(255, 100, 100, 100),
            width: 0.25,
          ),
          bottom: BorderSide(
            color: Color.fromARGB(255, 100, 100, 100),
            width: 0.25,
          ),
        ),
      ),
      padding: const EdgeInsets.only(left: 4, right: 12, top: 0, bottom: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Play/Pause button
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _togglePlayback,
            child: Icon(
              _videoController?.value.isPlaying == true
                  ? CupertinoIcons.pause_fill
                  : CupertinoIcons.play_fill,
              color: CupertinoColors.white,
              size: 22,
            ),
          ),

          const SizedBox(width: 16),

          // Video scrubber/timeline - enhanced with draggable thumb
          Expanded(
            child: _buildVideoScrubber(),
          ),

          const SizedBox(width: 16),

          // Time display
          if (_isVideoInitialized) _buildTimeDisplay(),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay() {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _videoController!,
      builder: (context, value, child) {
        final position = value.position;
        final duration = value.duration;

        String formatDuration(Duration duration) {
          String twoDigits(int n) => n.toString().padLeft(2, "0");
          String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
          String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
          return "$twoDigitMinutes:$twoDigitSeconds";
        }

        return Text(
          "${formatDuration(position)} / ${formatDuration(duration)}",
          style: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }

  Widget _buildVideoScrubber() {
    if (_videoController == null || !_isVideoInitialized) {
      return Container(
        height: 6,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey4.withOpacity(0.5),
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _videoController!,
      builder: (context, value, child) {
        final progress = value.duration.inMilliseconds > 0
            ? value.position.inMilliseconds / value.duration.inMilliseconds
            : 0.0;

        return SizedBox(
          height: 48, // Enough for a thumb to sit above the track
          child: LayoutBuilder(
            builder: (context, constraints) {
              const double horizontalPadding = 18;
              final double trackWidth =
                  constraints.maxWidth - horizontalPadding * 2;
              final double clampedProgress = progress.clamp(0.0, 1.0);
              final double thumbPosition = clampedProgress * trackWidth;

              return GestureDetector(
                onTapDown: (details) => _seekToPositionFromTap(details),
                onPanStart: (details) => _seekToPositionFromPanStart(details),
                onPanUpdate: (details) => _seekToPositionFromPan(details),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Stack(
                    children: [
                      // Track background
                      Positioned(
                        top: 15,
                        left: horizontalPadding,
                        right: horizontalPadding,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey4.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      // Active track
                      Positioned(
                        top: 15,
                        left: horizontalPadding,
                        child: Container(
                          height: 6,
                          width: thumbPosition,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 66, 53, 237),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      // Draggable thumb
                      Positioned(
                        top: 8,
                        left: horizontalPadding + thumbPosition - 8,
                        child: Container(
                          width: 24,
                          height: 20,
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: const Color.fromARGB(255, 0, 0, 0)
                                  .withOpacity(0.8),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _seekToPositionFromTap(TapDownDetails details) {
    if (_videoController == null || !_isVideoInitialized) return;

    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final progress = (localPosition.dx - 12) /
        (renderBox.size.width - 24); // Account for larger padding
    final clampedProgress = progress.clamp(0.0, 1.0);
    final duration = _videoController!.value.duration;
    final seekPosition = duration * clampedProgress;

    _videoController!.seekTo(seekPosition);
  }

  void _seekToPositionFromPanStart(DragStartDetails details) {
    if (_videoController == null || !_isVideoInitialized) return;

    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final progress = (localPosition.dx - 12) /
        (renderBox.size.width - 24); // Account for larger padding
    final clampedProgress = progress.clamp(0.0, 1.0);
    final duration = _videoController!.value.duration;
    final seekPosition = duration * clampedProgress;

    _videoController!.seekTo(seekPosition);
  }

  void _seekToPositionFromPan(DragUpdateDetails details) {
    if (_videoController == null || !_isVideoInitialized) return;

    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final progress = (localPosition.dx - 12) /
        (renderBox.size.width - 24); // Account for larger padding
    final clampedProgress = progress.clamp(0.0, 1.0);
    final duration = _videoController!.value.duration;
    final seekPosition = duration * clampedProgress;

    _videoController!.seekTo(seekPosition);
  }

  Widget _buildVideoArea(VideoProjectProvider provider) {
    return Container(
      height: 400, // Fixed height to prevent size changes
      margin: const EdgeInsets.all(16),
      child: Center(
        child: _buildVideoPlayer(provider),
      ),
    );
  }

  Widget _buildVideoPlayer(VideoProjectProvider provider) {
    if (!_isVideoInitialized || _videoController == null) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    // Build the base video player widget
    Widget videoWidget = AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: VideoPlayer(_videoController!),
    );

    // Apply effects directly to the video player
    videoWidget = _applyVideoEffects(videoWidget, provider);

    // Wrap with ClipRRect for rounded corners
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: videoWidget,
    );
  }

  Widget _applyVideoEffects(Widget videoWidget, VideoProjectProvider provider) {
    Widget effectsWidget = videoWidget;

    // Apply brightness adjustment
    if (provider.tempBrightness != 0) {
      final brightness = 1.0 + (provider.tempBrightness / 100.0);
      effectsWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix([
          brightness,
          0,
          0,
          0,
          0,
          0,
          brightness,
          0,
          0,
          0,
          0,
          0,
          brightness,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: effectsWidget,
      );
    }

    // Apply contrast adjustment
    if (provider.tempContrast != 0) {
      final contrast = 1.0 + (provider.tempContrast / 100.0);
      final intercept = -(contrast - 1.0) * 0.5;
      effectsWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix([
          contrast,
          0,
          0,
          0,
          intercept * 255,
          0,
          contrast,
          0,
          0,
          intercept * 255,
          0,
          0,
          contrast,
          0,
          intercept * 255,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: effectsWidget,
      );
    }

    // Apply saturation adjustment
    if (provider.tempSaturation != 0) {
      final saturation = 1.0 + (provider.tempSaturation / 100.0);
      const lumR = 0.213;
      const lumG = 0.715;
      const lumB = 0.072;

      effectsWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix([
          lumR * (1 - saturation) + saturation,
          lumG * (1 - saturation),
          lumB * (1 - saturation),
          0,
          0,
          lumR * (1 - saturation),
          lumG * (1 - saturation) + saturation,
          lumB * (1 - saturation),
          0,
          0,
          lumR * (1 - saturation),
          lumG * (1 - saturation),
          lumB * (1 - saturation) + saturation,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: effectsWidget,
      );
    }

    // Apply temperature adjustment
    if (provider.tempTemperature != 0) {
      final temp = provider.tempTemperature / 100.0;
      if (temp > 0) {
        effectsWidget = ColorFiltered(
          colorFilter: ColorFilter.matrix([
            1.0 + temp * 0.3,
            0,
            0,
            0,
            0,
            0,
            1.0 + temp * 0.1,
            0,
            0,
            0,
            0,
            0,
            1.0 - temp * 0.2,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: effectsWidget,
        );
      } else {
        final cool = -temp;
        effectsWidget = ColorFiltered(
          colorFilter: ColorFilter.matrix([
            1.0 - cool * 0.2,
            0,
            0,
            0,
            0,
            0,
            1.0 - cool * 0.1,
            0,
            0,
            0,
            0,
            0,
            1.0 + cool * 0.3,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: effectsWidget,
        );
      }
    }

    // Apply sharpen (contrast-like boost)
    if (provider.tempSharpen > 0) {
      final sharpen = 1.0 + (provider.tempSharpen / 100.0 * 0.5);
      final intercept = -(sharpen - 1.0) * 0.5;
      effectsWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix([
          sharpen,
          0,
          0,
          0,
          intercept * 255,
          0,
          sharpen,
          0,
          0,
          intercept * 255,
          0,
          0,
          sharpen,
          0,
          intercept * 255,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: effectsWidget,
      );
    }

    // Apply blur effect
    if (provider.tempBlur > 0) {
      final blurAmount = provider.tempBlur / 10.0;
      effectsWidget = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: effectsWidget,
      );
    }

    return effectsWidget;
  }

  Widget _buildControlsArea(VideoProjectProvider provider) {
    switch (_currentEditMode) {
      case VideoEditMode.style:
        return _buildStyleControls(provider);
      case VideoEditMode.adjust:
        return _buildAdjustControls(provider);
      case VideoEditMode.speed:
        return _buildAdjustControls(provider);
      case VideoEditMode.export:
        return _buildExportControls();
    }
  }

  Widget _buildStyleControls(VideoProjectProvider provider) {
    return SizedBox(
      height: baseHeight,
      child: Column(
        children: [
          const Spacer(), // Empty transparent space
          Container(
            decoration: const BoxDecoration(
              color: backgroundColor,
              border: Border(
                top: BorderSide(
                  color: Color.fromARGB(255, 100, 100, 100),
                  width: 0.25,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SizedBox(
              // This constrains the ListView's height
              height: 100, // or null if you want it to size to content
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                controller: _filterScrollController,
                itemCount: _allowedVideoFilters.length,
                itemBuilder: (context, index) {
                  final filter = _allowedVideoFilters[index];
                  final isSelected =
                      provider.currentProject?.filterMode == filter;

                  return GestureDetector(
                    onTap: () => _applyFilter(provider, filter),
                    child: Container(
                      width: 75,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? CupertinoColors.systemPurple
                                    : CupertinoColors.systemGrey4,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _buildFilterPreview(filter),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _getFilterDisplayName(filter),
                            style: TextStyle(
                              color: isSelected
                                  ? CupertinoColors.systemPurple
                                  : CupertinoColors.white,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                key: const PageStorageKey('videoFilterList'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPreview(FilterMode filter) {
    // For original filter, show video thumbnail with play icon
    if (filter == FilterMode.original) {
      return Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 218, 218, 218),
        ),
        child: const Icon(
          CupertinoIcons.video_camera_solid,
          color: Color.fromARGB(255, 28, 28, 28),
          size: 24,
        ),
      );
    }

    // Use actual filter preview images for other filters
    final imagePath = _getFilterPreviewImage(filter);
    if (imagePath != null) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to gradient if image fails to load
          final colors = _getFilterColors(filter);
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          );
        },
      );
    } else {
      // Fallback to gradient
      final colors = _getFilterColors(filter);
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    }
  }

  String? _getFilterPreviewImage(FilterMode filter) {
    switch (filter) {
      case FilterMode.original:
        return null; // Keep gradient for original
      case FilterMode.charcoalSketch:
        return 'assets/charcoal.jpg';
      case FilterMode.inkPen:
        return 'assets/ink.jpg';
      case FilterMode.cartoon:
        return 'assets/cartoon.jpg';
      case FilterMode.softPen:
        return 'assets/soft.jpg';
      case FilterMode.noirSketch:
        return 'assets/noir.jpg';
      case FilterMode.storyboard:
        return 'assets/storyboard.jpg';
      case FilterMode.chalk:
        return 'assets/chalk.jpg';
      case FilterMode.feltPen:
        return 'assets/felt.jpg';
      case FilterMode.monochromeSketch:
        return 'assets/monochrome.jpg';
      case FilterMode.splashSketch:
        return 'assets/splash.jpg';
      case FilterMode.coloringBook:
        return 'assets/coloring.jpg';
      case FilterMode.paperSketch:
        return 'assets/paper.jpg';
      case FilterMode.neonSketch:
        return 'assets/neon.jpg';
      default:
        return null; // Fallback for any missing filters
    }
  }

  List<Color> _getFilterColors(FilterMode filter) {
    switch (filter) {
      case FilterMode.original:
        return [CupertinoColors.systemBlue, CupertinoColors.systemGreen];
      case FilterMode.charcoalSketch:
        return [CupertinoColors.systemGrey3, CupertinoColors.black];
      case FilterMode.inkPen:
        return [CupertinoColors.systemIndigo, CupertinoColors.black];
      case FilterMode.cartoon:
        return [CupertinoColors.systemYellow, CupertinoColors.systemRed];
      case FilterMode.softPen:
        return [CupertinoColors.systemPink, CupertinoColors.systemPurple];
      case FilterMode.noirSketch:
        return [CupertinoColors.black, CupertinoColors.systemGrey];
      case FilterMode.storyboard:
        return [CupertinoColors.systemBrown, CupertinoColors.systemOrange];
      case FilterMode.chalk:
        return [CupertinoColors.white, CupertinoColors.systemGrey5];
      case FilterMode.feltPen:
        return [CupertinoColors.systemGreen, CupertinoColors.systemTeal];
      case FilterMode.monochromeSketch:
        return [CupertinoColors.systemGrey2, CupertinoColors.systemGrey4];
      case FilterMode.splashSketch:
        return [CupertinoColors.systemCyan, CupertinoColors.systemBlue];
      case FilterMode.coloringBook:
        return [CupertinoColors.systemGrey6, CupertinoColors.black];
      case FilterMode.paperSketch:
        return [CupertinoColors.systemGrey5, CupertinoColors.systemGrey3];
      case FilterMode.neonSketch:
        return [CupertinoColors.systemPink, CupertinoColors.systemPurple];
      default:
        // Default colors for filters not available in video processing
        return [CupertinoColors.systemGrey, CupertinoColors.systemGrey3];
    }
  }

  Widget _buildAdjustControls(VideoProjectProvider provider) {
    if (_showSlider && _currentEditMode == VideoEditMode.speed) {
      return SpeedTickSlider(
        initialValue: provider.tempSpeed,
        onChanged: (speed) {
          provider.updateTempSpeed(speed);
          _videoController?.setPlaybackSpeed(speed);
        },
      );
    }
    if (_showSlider) {
      return TickSlider(
        label: _selectedAdjustment,
        initialValue: _getCurrentAdjustmentValue(provider),
        min: _getMinValue().toInt(),
        max: _getMaxValue().toInt(),
        onChanged: (val) => _updateCurrentAdjustment(provider, val),
        onConfirm: () => setState(() => _showSlider = false),
      );
    }

    // Row of adjustment options only with reserved 120 height,
    // actual container pushed to bottom with transparent space above
    return SizedBox(
      height: baseHeight,
      child: Column(
        children: [
          const Spacer(), // empty transparent space above
          Container(
            decoration: const BoxDecoration(
              color: backgroundColor,
              border: Border(
                top: BorderSide(
                  color: Color.fromARGB(255, 100, 100, 100),
                  width: 0.25,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: SizedBox(
              height: 72, // you can adjust this to fit content nicely
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minWidth: constraints.maxWidth),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildAdjustmentOption('brightness', 'Brightness',
                              CupertinoIcons.sun_max),
                          _buildAdjustmentOption('contrast', 'Contrast',
                              CupertinoIcons.circle_lefthalf_fill),
                          _buildAdjustmentOption(
                              'saturation', 'Saturation', CupertinoIcons.drop),
                          _buildAdjustmentOption('temperature', 'Temperature',
                              CupertinoIcons.thermometer),
                          _buildAdjustmentOption(
                              'sharpen', 'Sharpen', CupertinoIcons.sparkles),
                          _buildAdjustmentOption('blur', 'Blur',
                              CupertinoIcons.circle_grid_3x3_fill),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentOption(String key, String name, IconData icon) {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedAdjustment = key;
        _showSlider = true;
        if (key == 'speed') {
          _showSlider = true;
        }
      }),
      child: Container(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: CupertinoColors.systemGrey4,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: CupertinoColors.white,
                size: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: EdgeInsets.only(bottom: Platform.isIOS ? 0 : 12),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: backgroundColor,
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Container(
          padding:
              const EdgeInsets.only(bottom: 8, top: 12, left: 10, right: 10),
          decoration: const BoxDecoration(
            color: navigationBarColor,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(
                icon: CupertinoIcons.paintbrush,
                mode: VideoEditMode.style,
              ),
              _buildNavItem(
                icon: CupertinoIcons.slider_horizontal_3,
                mode: VideoEditMode.adjust,
              ),
              _buildNavItem(
                icon: CupertinoIcons.speedometer,
                mode: VideoEditMode.speed,
              ),
              _buildNavItem(
                icon: CupertinoIcons.share,
                mode: VideoEditMode.export,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required VideoEditMode mode,
  }) {
    final isSelected = _currentEditMode == mode;

    return GestureDetector(
      onTap: () => setState(() {
        _currentEditMode = mode;
        _showSlider = false;
        if (mode == VideoEditMode.speed) {
          _showSlider = true;
        }
      }),
      child: Container(
        padding: const EdgeInsets.only(top: 0, bottom: 6, left: 16, right: 16),
        child: Icon(
          icon,
          color: isSelected
              ? CupertinoColors.systemBlue
              : CupertinoColors.systemGrey.withOpacity(0.8),
          size: 28,
        ),
      ),
    );
  }

  // Helper methods
  void _togglePlayback() {
    if (_videoController != null && _isVideoInitialized) {
      setState(() {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
        } else {
          _videoController!.play();
        }
      });
    }
  }

  void _applyFilter(VideoProjectProvider provider, FilterMode filter) async {
    if (provider.currentProject == null) return;

    // Check if filtered video already exists
    final filterExists =
        await _doesFilteredVideoExist(provider.currentProject!.id, filter);

    // Set the appropriate loading state
    setState(() {
      _isProcessingNewFilter =
          !filterExists; // Show full sheet for new filters, simple indicator for existing
    });

    await provider.applyFilter(filter);

    // Reset loading state
    setState(() {
      _isProcessingNewFilter = false;
    });

    // Update the projects provider with the current project state
    if (provider.currentProject != null) {
      final projectsProvider =
          Provider.of<ProjectsProvider>(context, listen: false);
      await projectsProvider.updateProject(
        provider.currentProject!.id,
        provider.currentProject!,
      );

      // Force video controller refresh since processed video path changed
      setState(() {
        _lastVideoPath = null; // This will trigger reinitialization
      });
    }
  }

  String _getEditModeTitle(VideoEditMode mode) {
    switch (mode) {
      case VideoEditMode.style:
        return 'Stylise';
      case VideoEditMode.adjust:
        return 'Edit';
      case VideoEditMode.speed:
        return 'Speed';
      case VideoEditMode.export:
        return 'Export';
    }
  }

  String _getFilterDisplayName(FilterMode filter) {
    switch (filter) {
      case FilterMode.original:
        return 'Original';
      case FilterMode.charcoalSketch:
        return 'Charcoal';
      case FilterMode.inkPen:
        return 'Ink';
      case FilterMode.cartoon:
        return 'Cartoon';
      case FilterMode.softPen:
        return 'Soft';
      case FilterMode.noirSketch:
        return 'Noir';
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
        return 'Book';
      case FilterMode.paperSketch:
        return 'Invert';
      case FilterMode.neonSketch:
        return 'Neon';
      default:
        // Default name for filters not available in video processing
        return 'Unavailable';
    }
  }

  int _getCurrentAdjustmentValue(VideoProjectProvider provider) {
    switch (_selectedAdjustment) {
      case 'brightness':
        return provider.tempBrightness + 50;
      case 'contrast':
        return provider.tempContrast + 50;
      case 'saturation':
        return provider.tempSaturation + 50;
      case 'temperature':
        return provider.tempTemperature + 50;
      case 'sharpen':
        return provider.tempSharpen;
      case 'blur':
        return provider.tempBlur;
      case 'speed':
        return (provider.tempSpeed * 10).round();
      default:
        return 0;
    }
  }

  void _updateCurrentAdjustment(VideoProjectProvider provider, int value) {
    switch (_selectedAdjustment) {
      case 'brightness':
        provider.updateTempBrightness(value - 50);
        break;
      case 'contrast':
        provider.updateTempContrast(value - 50);
        break;
      case 'saturation':
        provider.updateTempSaturation(value - 50);
        break;
      case 'temperature':
        provider.updateTempTemperature(value - 50);
        break;
      case 'sharpen':
        provider.updateTempSharpen(value);
        break;
      case 'blur':
        provider.updateTempBlur(value);
        break;
      case 'speed':
        final speed = value / 10.0;
        provider.updateTempSpeed(speed);
        _videoController?.setPlaybackSpeed(speed);
        break;
    }
  }

  double _getMinValue() {
    switch (_selectedAdjustment) {
      case 'speed':
        return 5;
      case 'sharpen':
      case 'blur':
        return 0;
      default:
        return 0;
    }
  }

  double _getMaxValue() {
    return 100;
  }

  Widget _buildExportControls() {
    return SizedBox(
      height: baseHeight,
      child: Column(
        children: [
          const Spacer(), // Empty transparent space on top

          Container(
            decoration: const BoxDecoration(
              color: backgroundColor,
              border: Border(
                top: BorderSide(
                  color: Color.fromARGB(255, 100, 100, 100),
                  width: 0.25,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                ExportPreferenceDropdown<String>(
                  label: 'Audio:',
                  value: _exportAudio,
                  values: const ['On', 'Off'],
                  onSelected: (v) => setState(() => _exportAudio = v),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: CupertinoButton(
                    padding: const EdgeInsets.only(
                        top: 4, bottom: 12, left: 16, right: 16),
                    onPressed: _isDownloading ? null : _handleVideoExport,
                    child: Container(
                      height: 43,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDD5E2A), Color(0xFFCC2CCD)],
                        ),
                      ),
                      child: Center(
                        child: _isDownloading
                            ? const CupertinoActivityIndicator(
                                color: Colors.white,
                                radius: 12,
                              )
                            : const Text(
                                'Download',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVideoExport() async {
    final provider = context.read<VideoProjectProvider>();
    if (provider.currentProject == null) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      if (Platform.isAndroid) {
        PermissionStatus? status;
        var info = await DeviceInfoPlugin().androidInfo;
        var androidVersion = info.version.sdkInt;

        if (androidVersion < 33) {
          status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
        } else {
          PermissionStatus? status = await Permission.photos.status;
          if (!status.isGranted && !status.isLimited) {
            status = await Permission.photos.request();
          }
        }
      } else {
        PermissionStatus? status = await Permission.photos.status;
        if (!status.isGranted && !status.isLimited) {
          status = await Permission.photos.request();
        }
      }

      String videoPathToSave = provider.currentProject!.processedVideo;

      // If audio is enabled and we're not using the original video, merge audio
      if (_exportAudio == 'On' &&
          provider.currentProject!.filterMode != FilterMode.original) {
        videoPathToSave = await _mergeAudioWithVideo(
          provider.currentProject!.processedVideo,
          provider.currentProject!.originalVideo,
        );
      }

      // Save video to gallery
      final result = await ImageGallerySaver.saveFile(
        videoPathToSave,
        name: 'sketch_video_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result['isSuccess'] == true) {
        _showSuccessMessage('Video saved to gallery');
      } else {
        _showErrorMessage('Failed to save video');
      }
    } catch (e) {
      _showErrorMessage('Failed to save video');
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<String> _mergeAudioWithVideo(
      String videoPath, String originalVideoPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath = path.join(tempDir.path,
          'merged_video_${DateTime.now().millisecondsSinceEpoch}.mp4');

      // Use platform method to merge audio
      final result = await const MethodChannel('opencv_channel').invokeMethod(
        'mergeAudioWithVideo',
        {
          'videoPath': videoPath,
          'audioSourcePath': originalVideoPath,
          'outputPath': outputPath,
        },
      );

      if (result == true && await File(outputPath).exists()) {
        return outputPath;
      } else {
        // If merging fails, return original processed video
        return videoPath;
      }
    } catch (e) {
      // If merging fails, return original processed video
      return videoPath;
    }
  }

  void _showSuccessMessage(String message) {
    toast(message);
  }

  void _showErrorMessage(String message) {
    toast(message);
  }
}
