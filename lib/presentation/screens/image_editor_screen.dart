// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sketch/application/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/image_project_provider.dart';
import '../providers/projects_provider.dart';
import '../../application/injection.dart';
import '../../data/models/enums.dart';
import '../widgets/modern_tick_slider.dart';
import '../widgets/export_preference_dropdown.dart';

enum EditMode { style, adjust, crop, export }

class ImageEditorScreen extends StatelessWidget {
  final String projectId;

  const ImageEditorScreen({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ImageProjectProvider>(
      create: (context) =>
          getIt<ImageProjectProvider>()..loadProject(projectId),
      child: const _ImageEditorContent(),
    );
  }
}

class _ImageEditorContent extends StatefulWidget {
  const _ImageEditorContent();

  @override
  State<_ImageEditorContent> createState() => _ImageEditorContentState();
}

class _ImageEditorContentState extends State<_ImageEditorContent> {
  EditMode _currentEditMode = EditMode.style;

  // Current selected adjustment for Edit mode
  String _selectedAdjustment = 'brightness';

  // Whether the modern slider overlay is currently visible
  bool _showSlider = false;

  // Add variables for export preferences
  String _exportFormat = 'JPG';

  // Flag to prevent double navigation
  bool _isFinishing = false;

  // Preserve scroll position of filter row
  final ScrollController _filterScrollController = ScrollController();

  // RepaintBoundary key for capturing the image
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  // Download state
  bool _isDownloading = false;

  @override
  void dispose() {
    // Cancel any ongoing image processing to prevent disposed provider errors
    try {
      final provider = context.read<ImageProjectProvider>();
      if (provider.isLoading) {
        // Note: ImageProjectProvider doesn't have cancelProcessing yet,
        // but we can at least attempt to access it safely
      }
    } catch (e) {
      // Provider might already be disposed, ignore error
    }

    // Note: Cannot safely access context in dispose method for state saving
    // State saving is handled by the finish button instead
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
              final provider = context.read<ImageProjectProvider>();

              if (provider.tempBrightness != 0 ||
                  provider.tempContrast != 0 ||
                  provider.tempSaturation != 0 ||
                  provider.tempTemperature != 0 ||
                  provider.tempSharpen != 0 ||
                  provider.tempBlur != 0) {
                await provider.applyImageAdjustments();
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
      child: Consumer<ImageProjectProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CupertinoActivityIndicator(
                radius: 16,
                color: CupertinoColors.white,
              ),
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

          return Column(
            children: [
              // Image display area
              Expanded(
                child: _buildImageArea(provider),
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

  Widget _buildImageArea(ImageProjectProvider provider) {
    return Container(
      height: 400, // Fixed height to prevent size changes when switching modes
      margin: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Image - centered and filling available space
          Positioned.fill(
            child: _buildCurrentImage(provider),
          ),

          // Loading indicator when processing
          if (provider.isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CupertinoActivityIndicator(
                    radius: 20,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ),

          // Crop overlay
          if (_currentEditMode == EditMode.crop) _buildCropOverlay(),
        ],
      ),
    );
  }

  Widget _buildCurrentImage(ImageProjectProvider provider) {
    final project = provider.currentProject;
    if (project == null) return const SizedBox();

    // Build the base image widget
    Widget imageWidget = Image.file(
      File(project.processedImage),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: double.infinity,
          height: 400,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey5.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.systemGrey4.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.photo,
                  size: 64,
                  color: CupertinoColors.systemGrey,
                ),
                SizedBox(height: 16),
                Text(
                  'Unable to load image',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Apply real-time adjustments directly to the image
    imageWidget = _applyImageAdjustmentOverlays(imageWidget, provider);

    // Wrap with ClipRRect for rounded corners and RepaintBoundary around the final image
    return Center(
      child: RepaintBoundary(
        key: _repaintBoundaryKey,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: imageWidget,
        ),
      ),
    );
  }

  Widget _applyImageAdjustmentOverlays(
      Widget imageWidget, ImageProjectProvider provider) {
    Widget overlay = imageWidget;

    // Apply brightness adjustment
    if (provider.tempBrightness != 0) {
      final brightness = 1.0 + (provider.tempBrightness / 100.0);
      overlay = ColorFiltered(
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
        child: overlay,
      );
    }

    // Apply contrast adjustment
    if (provider.tempContrast != 0) {
      final contrast = 1.0 + (provider.tempContrast / 100.0);
      final intercept = -(contrast - 1.0) * 0.5;
      overlay = ColorFiltered(
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
        child: overlay,
      );
    }

    // Apply saturation adjustment
    if (provider.tempSaturation != 0) {
      final saturation = 1.0 + (provider.tempSaturation / 100.0);
      const lumR = 0.213;
      const lumG = 0.715;
      const lumB = 0.072;

      overlay = ColorFiltered(
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
        child: overlay,
      );
    }

    // Apply temperature adjustment
    if (provider.tempTemperature != 0) {
      final temp = provider.tempTemperature / 100.0;
      // Temperature adjustment using color matrix
      if (temp > 0) {
        // Warmer (more red/yellow)
        overlay = ColorFiltered(
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
          child: overlay,
        );
      } else {
        // Cooler (more blue)
        final coolTemp = -temp;
        overlay = ColorFiltered(
          colorFilter: ColorFilter.matrix([
            1.0 - coolTemp * 0.2,
            0,
            0,
            0,
            0,
            0,
            1.0 - coolTemp * 0.1,
            0,
            0,
            0,
            0,
            0,
            1.0 + coolTemp * 0.3,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: overlay,
        );
      }
    }

    // Apply sharpen effect (using contrast-like matrix)
    if (provider.tempSharpen > 0) {
      final sharpen = 1.0 + (provider.tempSharpen / 100.0 * 0.5);
      final intercept = -(sharpen - 1.0) * 0.5;
      overlay = ColorFiltered(
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
        child: overlay,
      );
    }

    // Apply blur effect
    if (provider.tempBlur > 0) {
      final blurAmount = provider.tempBlur / 10.0;
      overlay = ImageFiltered(
        imageFilter:
            ui.ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: overlay,
      );
    }

    // Texture overlay for selected sketch filters
    final filter = provider.currentProject?.filterMode;
    if (filter == FilterMode.cartoon2 ||
        filter == FilterMode.waxSketch ||
        filter == FilterMode.comicBook ||
        filter == FilterMode.feltPen ||
        filter == FilterMode.monochromeSketch) {
      String textureAsset;
      switch (filter) {
        case FilterMode.cartoon2:
          textureAsset = 'assets/texture8.png';
          break;
        case FilterMode.waxSketch:
          textureAsset = 'assets/texture7.png';
          break;
        case FilterMode.comicBook:
          textureAsset = 'assets/texture4.png';
          break;
        case FilterMode.feltPen:
          textureAsset = 'assets/texture10.png';
          break;
        case FilterMode.monochromeSketch:
          textureAsset = 'assets/texture9.png';
          break;
        default:
          textureAsset = '';
      }
      double opacity = 0.0;
      switch (filter) {
        case FilterMode.waxSketch:
          opacity = 0.2;
          break;
        case FilterMode.cartoon2:
          opacity = 0.45;
          break;
        case FilterMode.comicBook:
          opacity = 0.4;
          break;
        case FilterMode.feltPen:
          opacity = 0.15;
          break;
        case FilterMode.monochromeSketch:
          opacity = 0.5;
          break;
        default:
          opacity = 0.0;
      }

      if (textureAsset.isNotEmpty) {
        overlay = // Parent will have the image's intrinsic size.
            Stack(
          children: [
            // Base image
            overlay,

            // Texture on top of image
            Positioned.fill(
              child: Opacity(
                opacity: opacity,
                child: Image.asset(
                  textureAsset,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        );
      }
    }

    return overlay;
  }

  Widget _buildCropOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: CropOverlayPainter(),
      ),
    );
  }

  Widget _buildControlsArea(ImageProjectProvider provider) {
    switch (_currentEditMode) {
      case EditMode.style:
        return _buildStyleControls(provider);
      case EditMode.adjust:
        return _buildAdjustControls(provider);
      case EditMode.crop:
        return const SizedBox.shrink(); // No controls needed for crop mode
      case EditMode.export:
        return _buildExportControls();
    }
  }

  Widget _buildStyleControls(ImageProjectProvider provider) {
    return SizedBox(
      height: baseHeight,
      child: Column(
        children: [
          const Spacer(), // Pushes the visible part to the bottom

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
              height: 100, // original height minus top empty space
              child: ListView.builder(
                key: const PageStorageKey('imageFilterList'),
                controller: _filterScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: FilterMode.values.length,
                itemBuilder: (context, index) {
                  final filter = FilterMode.values[index];
                  final isSelected =
                      provider.currentProject?.filterMode == filter;

                  return GestureDetector(
                    onTap: () => _applyFilter(provider, filter),
                    child: Container(
                      width: 75,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPreview(FilterMode filter) {
    // For original filter, show the actual user image
    if (filter == FilterMode.original) {
      return Consumer<ImageProjectProvider>(
        builder: (context, provider, child) {
          if (provider.currentProject != null) {
            return Image.file(
              File(provider.currentProject!.originalImage),
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
            // Fallback to gradient if no project loaded
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
        },
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
      case FilterMode.pencilSketch:
        return 'assets/pencil.jpg';
      case FilterMode.charcoalSketch:
        return 'assets/charcoal.jpg';
      case FilterMode.inkPen:
        return 'assets/ink.jpg';
      case FilterMode.colorSketch:
        return 'assets/color.jpg';
      case FilterMode.cartoon:
        return 'assets/cartoon.jpg';
      case FilterMode.techPen:
        return 'assets/tech.jpg';
      case FilterMode.softPen:
        return 'assets/soft.jpg';
      case FilterMode.noirSketch:
        return 'assets/noir.jpg';
      case FilterMode.cartoon2:
        return 'assets/cartoon2.jpg';
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
      case FilterMode.waxSketch:
        return 'assets/wax.jpg';
      case FilterMode.paperSketch:
        return 'assets/paper.jpg';
      case FilterMode.neonSketch:
        return 'assets/neon.jpg';
      case FilterMode.anime:
        return 'assets/anime.jpg';
      case FilterMode.comicBook:
        return 'assets/comic.jpg';
    }
  }

  List<Color> _getFilterColors(FilterMode filter) {
    switch (filter) {
      case FilterMode.original:
        return [CupertinoColors.systemBlue, CupertinoColors.systemGreen];
      case FilterMode.pencilSketch:
        return [CupertinoColors.systemGrey6, CupertinoColors.systemGrey2];
      case FilterMode.charcoalSketch:
        return [CupertinoColors.systemGrey3, CupertinoColors.black];
      case FilterMode.inkPen:
        return [CupertinoColors.systemIndigo, CupertinoColors.black];
      case FilterMode.colorSketch:
        return [CupertinoColors.systemPink, CupertinoColors.systemOrange];
      case FilterMode.cartoon:
        return [CupertinoColors.systemYellow, CupertinoColors.systemRed];
      case FilterMode.techPen:
        return [CupertinoColors.systemBlue, CupertinoColors.systemIndigo];
      case FilterMode.softPen:
        return [CupertinoColors.systemPink, CupertinoColors.systemPurple];
      case FilterMode.noirSketch:
        return [CupertinoColors.black, CupertinoColors.systemGrey];
      case FilterMode.cartoon2:
        return [CupertinoColors.systemOrange, CupertinoColors.systemYellow];
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
      case FilterMode.waxSketch:
        return [CupertinoColors.systemYellow, CupertinoColors.systemBrown];
      case FilterMode.paperSketch:
        return [CupertinoColors.systemGrey5, CupertinoColors.systemGrey3];
      case FilterMode.neonSketch:
        return [CupertinoColors.systemPink, CupertinoColors.systemPurple];
      case FilterMode.anime:
        return [CupertinoColors.systemPink, CupertinoColors.systemBlue];
      case FilterMode.comicBook:
        return [CupertinoColors.systemRed, CupertinoColors.systemBlue];
    }
  }

  Widget _buildAdjustControls(ImageProjectProvider provider) {
    // When slider overlay is visible, show it instead of the adjustment icons row
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

    // Adjustment options row with space above
    return SizedBox(
      height: baseHeight,
      child: Column(
        children: [
          const Spacer(), // Empty space above

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
              height: 72, // 120 - 32 from Spacer
              child: LayoutBuilder(builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildAdjustmentOption(
                            'brightness', 'Brightness', CupertinoIcons.sun_max),
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
              }),
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
        _showSlider = true; // Show modern slider when an adjustment is selected
      }),
      child: Container(
        width: 70, // Slightly smaller to fit better
        child: Column(
          mainAxisSize: MainAxisSize.min, // Prevent overflow
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
          decoration: const BoxDecoration(
            color: navigationBarColor,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          padding:
              const EdgeInsets.only(bottom: 8, top: 12, left: 10, right: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNavItem(
                icon: CupertinoIcons.paintbrush,
                mode: EditMode.style,
              ),
              _buildNavItem(
                icon: CupertinoIcons.slider_horizontal_3,
                mode: EditMode.adjust,
              ),
              _buildNavItem(
                icon: CupertinoIcons.crop,
                mode: EditMode.crop,
              ),
              _buildNavItem(
                icon: CupertinoIcons.share,
                mode: EditMode.export,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required EditMode mode,
  }) {
    final isSelected = _currentEditMode == mode;

    return GestureDetector(
      onTap: () => _handleNavItemTap(mode),
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

  void _applyFilter(ImageProjectProvider provider, FilterMode filter) async {
    await provider.applyFilter(filter);

    // Update the projects provider with the current project state
    if (provider.currentProject != null) {
      final projectsProvider =
          Provider.of<ProjectsProvider>(context, listen: false);
      await projectsProvider.updateProject(
        provider.currentProject!.id,
        provider.currentProject!,
      );
    }
  }

  String _getEditModeTitle(EditMode mode) {
    switch (mode) {
      case EditMode.style:
        return 'Stylise';
      case EditMode.adjust:
        return 'Edit';
      case EditMode.crop:
        return 'Crop';
      case EditMode.export:
        return 'Export';
    }
  }

  String _getFilterDisplayName(FilterMode filter) {
    switch (filter) {
      case FilterMode.original:
        return 'Original';
      case FilterMode.pencilSketch:
        return 'Pencil';
      case FilterMode.charcoalSketch:
        return 'Charcoal';
      case FilterMode.inkPen:
        return 'Ink';
      case FilterMode.colorSketch:
        return 'Color';
      case FilterMode.cartoon:
        return 'Cartoon';
      case FilterMode.techPen:
        return 'Azure';
      case FilterMode.softPen:
        return 'Soft';
      case FilterMode.noirSketch:
        return 'Noir';
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
        return 'Book';
      case FilterMode.waxSketch:
        return 'Graphite';
      case FilterMode.paperSketch:
        return 'Invert';
      case FilterMode.neonSketch:
        return 'Neon';
      case FilterMode.anime:
        return 'Anime';
      case FilterMode.comicBook:
        return 'Dust';
    }
  }

  int _getCurrentAdjustmentValue(ImageProjectProvider provider) {
    switch (_selectedAdjustment) {
      case 'brightness':
        return provider.tempBrightness + 50; // -50 to +50 -> 0 to 100
      case 'contrast':
        return provider.tempContrast + 50; // -50 to +50 -> 0 to 100
      case 'saturation':
        return provider.tempSaturation + 50; // -50 to +50 -> 0 to 100
      case 'temperature':
        return provider.tempTemperature + 50; // -50 to +50 -> 0 to 100
      case 'sharpen':
        return provider.tempSharpen; // 0 to 100 -> 0 to 100
      case 'blur':
        return provider.tempBlur; // 0 to 100 -> 0 to 100
      default:
        return 0;
    }
  }

  void _updateCurrentAdjustment(ImageProjectProvider provider, int value) {
    switch (_selectedAdjustment) {
      case 'brightness':
        provider.updateTempBrightness(value - 50); // 0 to 100 -> -50 to +50
        break;
      case 'contrast':
        provider.updateTempContrast(value - 50); // 0 to 100 -> -50 to +50
        break;
      case 'saturation':
        provider.updateTempSaturation(value - 50); // 0 to 100 -> -50 to +50
        break;
      case 'temperature':
        provider.updateTempTemperature(value - 50); // 0 to 100 -> -50 to +50
        break;
      case 'sharpen':
        provider.updateTempSharpen(value); // 0 to 100 -> 0 to 100
        break;
      case 'blur':
        provider.updateTempBlur(value); // 0 to 100 -> 0 to 100
        break;
    }
  }

  double _getMinValue() {
    switch (_selectedAdjustment) {
      case 'sharpen':
      case 'blur':
        return 0;
      default:
        return 0; // All adjustments now 0-100
    }
  }

  double _getMaxValue() {
    return 100;
  }

  void _handleNavItemTap(EditMode mode) {
    if (mode == EditMode.crop) {
      // Immediately launch image cropper when crop mode is selected
      _launchImageCropper();
    } else {
      setState(() => _currentEditMode = mode);
    }

    if (mode == EditMode.export) {
      setState(() => _currentEditMode = mode);
    }
  }

  Future<void> _launchImageCropper() async {
    final provider = context.read<ImageProjectProvider>();
    if (provider.currentProject == null) return;

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: provider.currentProject!.processedImage,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 95,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: CupertinoColors.black,
            toolbarWidgetColor: CupertinoColors.white,
            backgroundColor: CupertinoColors.black,
            activeControlsWidgetColor: CupertinoColors.systemBlue,
            lockAspectRatio: false,
            hideBottomControls: false,
            showCropGrid: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            aspectRatioPickerButtonHidden: false,
            minimumAspectRatio: 0.2,
          ),
        ],
      );

      if (croppedFile != null) {
        // Update the project with the cropped image
        await provider.updateProcessedImage(croppedFile.path);
        // Switch back to style mode after successful crop
        setState(() => _currentEditMode = EditMode.style);
      }
    } catch (e) {
      // Handle cropping error silently or show a message
      debugPrint('Cropping failed: $e');
    }
  }

  Widget _buildExportControls() {
    return SizedBox(
      height: baseHeight, // e.g., 120
      child: Column(
        children: [
          const Spacer(), // pushes the actual content down

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
                  label: 'Format:',
                  value: _exportFormat,
                  values: const ['JPG', 'PNG'],
                  onSelected: (v) => setState(() => _exportFormat = v),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 30, right: 30, bottom: 8),
                  child: CupertinoButton(
                    padding: const EdgeInsets.only(
                        top: 4, bottom: 12, left: 16, right: 16),
                    onPressed: _isDownloading ? null : _handleImageExport,
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

  Future<void> _handleImageExport() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final capturedBytes = await _captureImage();

      if (capturedBytes != null) {
        await _downloadImage(capturedBytes, _exportFormat);
      } else {
        _showErrorMessage("Download failed");
      }
    } catch (e) {
      _showErrorMessage("Download failed");
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<Uint8List?> _captureImage() async {
    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        return byteData?.buffer.asUint8List();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _downloadImage(Uint8List imageBytes, String format) async {
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

      String fileName = 'sketch_${DateTime.now().millisecondsSinceEpoch}';

      if (format.toLowerCase() == 'png') {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName.png');
        await file.writeAsBytes(imageBytes);

        await ImageGallerySaver.saveFile(file.path);
        _showSuccessMessage('Image saved to gallery');
      } else {
        await ImageGallerySaver.saveImage(
          imageBytes,
          quality: 100,
          name: fileName,
        );
        _showSuccessMessage('Image saved to gallery');
      }
    } catch (e) {
      _showErrorMessage('Failed to save image: $e');
    }
  }

  void _showSuccessMessage(String message) {
    toast(message);
  }

  void _showErrorMessage(String message) {
    toast(message);
  }
}

class CropOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CupertinoColors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw crop handles
    const handleSize = 20.0;
    const margin = 40.0;

    // Corner positions
    const topLeft = Offset(margin, margin);
    final topRight = Offset(size.width - margin, margin);
    final bottomLeft = Offset(margin, size.height - margin);
    final bottomRight = Offset(size.width - margin, size.height - margin);

    // Draw corner handles
    _drawCornerHandle(canvas, paint, topLeft, handleSize, true, true);
    _drawCornerHandle(canvas, paint, topRight, handleSize, false, true);
    _drawCornerHandle(canvas, paint, bottomLeft, handleSize, true, false);
    _drawCornerHandle(canvas, paint, bottomRight, handleSize, false, false);

    // Draw crop frame
    canvas.drawRect(
      Rect.fromLTRB(margin, margin, size.width - margin, size.height - margin),
      paint,
    );
  }

  void _drawCornerHandle(Canvas canvas, Paint paint, Offset position,
      double size, bool isLeft, bool isTop) {
    final handlePaint = Paint()
      ..color = CupertinoColors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw L-shaped handle
    if (isLeft && isTop) {
      canvas.drawLine(
          position, Offset(position.dx + size, position.dy), handlePaint);
      canvas.drawLine(
          position, Offset(position.dx, position.dy + size), handlePaint);
    } else if (!isLeft && isTop) {
      canvas.drawLine(
          position, Offset(position.dx - size, position.dy), handlePaint);
      canvas.drawLine(
          position, Offset(position.dx, position.dy + size), handlePaint);
    } else if (isLeft && !isTop) {
      canvas.drawLine(
          position, Offset(position.dx + size, position.dy), handlePaint);
      canvas.drawLine(
          position, Offset(position.dx, position.dy - size), handlePaint);
    } else {
      canvas.drawLine(
          position, Offset(position.dx - size, position.dy), handlePaint);
      canvas.drawLine(
          position, Offset(position.dx, position.dy - size), handlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
