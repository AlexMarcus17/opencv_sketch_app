#import <UIKit/UIKit.h>

@interface OpenCVWrapper : NSObject

+ (UIImage *)convertToGrayScale:(UIImage *)image;
+ (UIImage *)convertToSketch:(UIImage *)image;
+ (UIImage *)convertToCartoon:(UIImage *)image;
+ (UIImage *)convertToCharcoalSketch:(UIImage *)image;
+ (UIImage *)convertToInkPen:(UIImage *)image;
+ (UIImage *)convertToColorSketch:(UIImage *)image;

+ (UIImage *)convertToTechPen:(UIImage *)image;
+ (UIImage *)convertToSoftPen:(UIImage *)image;
+ (UIImage *)convertToNoirSketch:(UIImage *)image;
+ (UIImage *)convertToCartoon2:(UIImage *)image;
+ (UIImage *)convertToStoryboard:(UIImage *)image;
+ (UIImage *)convertToChalk:(UIImage *)image;
+ (UIImage *)convertToFeltPen:(UIImage *)image;
+ (UIImage *)convertToMonochromeSketch:(UIImage *)image;
+ (UIImage *)convertToSplashSketch:(UIImage *)image;
+ (UIImage *)convertToColoringBook:(UIImage *)image;
+ (UIImage *)convertToWaxSketch:(UIImage *)image;
+ (UIImage *)convertToPaperSketch:(UIImage *)image;
+ (UIImage *)convertToNeonSketch:(UIImage *)image;
+ (UIImage *)convertToAnime:(UIImage *)image;
+ (UIImage *)convertToComicBook:(UIImage *)image;

// Video processing
+ (BOOL)processVideoWithFilter:(NSString *)inputPath outputPath:(NSString *)outputPath filterType:(NSString *)filterType;

// New frame-based video processing methods
+ (NSDictionary *)extractFramesFromVideo:(NSString *)inputPath outputDirectory:(NSString *)outputDirectory targetFPS:(float)targetFPS;
+ (BOOL)applyFilterToFrames:(NSArray<NSString *> *)framePaths outputPath:(NSString *)outputPath filterType:(NSString *)filterType frameCount:(int)frameCount duration:(double)duration targetFPS:(float)targetFPS;

// Audio merging
+ (BOOL)mergeAudioWithVideoPath:(NSString *)videoPath audioSourcePath:(NSString *)audioSourcePath outputPath:(NSString *)outputPath;

@end

