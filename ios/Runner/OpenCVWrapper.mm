#ifdef NO
#undef NO
#endif

#import <opencv2/opencv.hpp>
#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <AVFoundation/AVFoundation.h>

#import "OpenCVWrapper.h"

using namespace cv;

@implementation OpenCVWrapper

// Helper method to send progress updates to Flutter
+ (void)sendProgressUpdate:(double)progress status:(NSString *)status {
    NSLog(@"🔔 OpenCVWrapper sending progress: %.2f%% - %@", progress * 100, status);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{
            @"progress": @(progress),
            @"status": status
        };
        [[NSNotificationCenter defaultCenter] postNotificationName:@"VideoProcessingProgress" 
                                                            object:nil 
                                                          userInfo:userInfo];
        NSLog(@"🔔 Notification posted with progress: %.2f", progress);
    });
}

+ (UIImage *)convertToGrayScale:(UIImage *)image {
    Mat cvImage;
    UIImageToMat(image, cvImage);
    cvtColor(cvImage, cvImage, COLOR_BGR2GRAY);
    return MatToUIImage(cvImage);
}

+ (UIImage *)convertToSketch:(UIImage *)image {
    Mat src;
    UIImageToMat(image, src);

    if (src.empty()) {
        NSLog(@"Input image is empty");
        return image;
    }

    // Convert to grayscale
    Mat gray;
    cvtColor(src, gray, cv::COLOR_BGR2GRAY);

    // Invert grayscale
    Mat invGray = 255 - gray;

    // Heavy Gaussian blur on inverted image
    Mat blurImg;
    GaussianBlur(invGray, blurImg, cv::Size(101, 101), 0);

    // Invert the blurred image
    Mat invBlur = 255 - blurImg;

    // Create sketch by dividing gray by invBlur, scale=255.0
    Mat sketchImg;
    cv::divide(gray, invBlur, sketchImg, 255.0);

    return MatToUIImage(sketchImg);
}




+ (UIImage *)convertToCartoon:(UIImage *)image {
    Mat src;
    UIImageToMat(image, src);
    if (src.empty()) {
        NSLog(@"Input image is empty");
        return image;
    }

    if (src.channels() == 4) {
        cvtColor(src, src, COLOR_BGRA2BGR);
    }

    Mat color, edges, dst;

    // Use separate Mat for bilateral filter output
    bilateralFilter(src, color, 9, 75, 75);

    Mat gray;
    cvtColor(src, gray, COLOR_BGR2GRAY);

    medianBlur(gray, gray, 7);

    adaptiveThreshold(gray, edges, 255, ADAPTIVE_THRESH_MEAN_C, THRESH_BINARY, 9, 2);

    cvtColor(edges, edges, COLOR_GRAY2BGR);

    bitwise_and(color, edges, dst);

    if (dst.empty()) {
        NSLog(@"Output cartoon image is empty");
        return image;
    }

    return MatToUIImage(dst);
}

+ (UIImage *)convertToCharcoalSketch:(UIImage *)image {
    cv::Mat src;
    UIImageToMat(image, src);

    if (src.empty()) {
        NSLog(@"Input image is empty");
        return image;
    }

    if (src.channels() == 4) {
        cv::cvtColor(src, src, cv::COLOR_BGRA2BGR);
    }

    // Grayscale
    cv::Mat gray;
    cv::cvtColor(src, gray, cv::COLOR_BGR2GRAY);

    // Gaussian Blur
    cv::Mat blur;
    cv::GaussianBlur(gray, blur, cv::Size(5, 5), 2);

    // Sobel gradients
    cv::Mat sobelX, sobelY;
    cv::Sobel(blur, sobelX, CV_64F, 1, 0, 5);
    cv::Sobel(blur, sobelY, CV_64F, 0, 1, 5);

    // Gradient magnitude: sqrt(sobelX^2 + sobelY^2)
    cv::Mat gradMagSq;
    cv::Mat sobelXSq, sobelYSq;
    cv::multiply(sobelX, sobelX, sobelXSq);
    cv::multiply(sobelY, sobelY, sobelYSq);
    gradMagSq = sobelXSq + sobelYSq;

    cv::Mat gradMag;
    cv::sqrt(gradMagSq, gradMag);

    // Clip values to 0-255 and convert to 8U
    cv::Mat gradMag8U;
    gradMag.convertTo(gradMag8U, CV_8U);

    // Invert
    cv::Mat gradMagInv = 255 - gradMag8U;

    // Threshold
    cv::Mat threshImg;
    cv::threshold(gradMagInv, threshImg, 10, 255, cv::THRESH_BINARY);

    return MatToUIImage(threshImg);
}




+ (UIImage *)convertToInkPen:(UIImage *)image {
    Mat src;
    UIImageToMat(image, src);
    
    Mat gray, edges, ink;
    cvtColor(src, gray, COLOR_BGR2GRAY);
    
    // Apply bilateral filter to preserve edges
    Mat filtered;
    bilateralFilter(gray, filtered, 9, 80, 80);
    
    // Use multiple edge detection techniques and combine
    Mat canny, sobel;
    
    // Canny edges
    Canny(filtered, canny, 30, 90);
    
    // Sobel edges for additional detail
    Mat sobelX, sobelY;
    Sobel(filtered, sobelX, CV_64F, 1, 0, 3);
    Sobel(filtered, sobelY, CV_64F, 0, 1, 3);
    magnitude(sobelX, sobelY, sobel);
    sobel.convertTo(sobel, CV_8U);
    threshold(sobel, sobel, 50, 255, THRESH_BINARY);
    
    // Combine both edge maps
    bitwise_or(canny, sobel, edges);
    bitwise_not(edges, ink);
    
    return MatToUIImage(ink);
}



+ (UIImage *)convertToColorSketch:(UIImage *)image {
    Mat src;
    UIImageToMat(image, src);

    if (src.empty()) return image;

    if (src.channels() == 4) {
        cv::cvtColor(src, src, cv::COLOR_BGRA2BGR);
    }

    // Result Mats
    cv::Mat dst_gray, dst_color;

    // Apply color pencil sketch
    cv::pencilSketch(src, dst_gray, dst_color, 60, 0.07, 0.05);

    return MatToUIImage(dst_color);
}


+ (UIImage *)convertToTechPen:(UIImage *)image {
    cv::Mat src;
    UIImageToMat(image, src);
    if (src.empty()) {
        NSLog(@"Input image is empty");
        return image;
    }
    if (src.channels() == 4) {
        cv::cvtColor(src, src, cv::COLOR_BGRA2BGR);
    }

    cv::Mat color, edges, dst;
    cv::bilateralFilter(src, color, 9, 75, 75);

    cv::Mat gray;
    cv::cvtColor(src, gray, cv::COLOR_BGR2GRAY);

    cv::medianBlur(gray, gray, 7);

    cv::adaptiveThreshold(gray, edges, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 9, 2);

    cv::cvtColor(edges, edges, cv::COLOR_GRAY2BGR);

    cv::bitwise_and(color, edges, dst);

    if (dst.empty()) {
        NSLog(@"Output cartoon image is empty");
        return image;
    }

    // Boost red channel by 30%, clamp max to 255
    std::vector<cv::Mat> channels;
    cv::split(dst, channels);
    channels[2] = cv::min(channels[2] * 1.6, 255);
    cv::merge(channels, dst);

    return MatToUIImage(dst);
}



+ (UIImage *)convertToSoftPen:(UIImage *)image {
    Mat src;
    UIImageToMat(image, src);
    
    Mat gray, invGray, blur, soft;
    cvtColor(src, gray, COLOR_BGR2GRAY);
    bitwise_not(gray, invGray);
    GaussianBlur(invGray, blur, cv::Size(25, 25), 0);
    
    divide(gray, 255 - blur, soft, 256);
    
    // Additional softening
    GaussianBlur(soft, soft, cv::Size(3, 3), 0);
    
    return MatToUIImage(soft);
}

+ (UIImage *)convertToNoirSketch:(UIImage *)image {
    Mat src;
    UIImageToMat(image, src);
    
    Mat gray, noir;
    cvtColor(src, gray, COLOR_BGR2GRAY);
    
    // High contrast for noir effect
    gray.convertTo(noir, -1, 2.0, -50);
    
    // Apply threshold for dramatic effect
    threshold(noir, noir, 127, 255, THRESH_BINARY);
    
    return MatToUIImage(noir);
}

+ (UIImage *)convertToCartoon2:(UIImage *)image {
    cv::Mat src;
    UIImageToMat(image, src);
    if (src.empty()) {
        NSLog(@"Input image is empty");
        return image;
    }
    if (src.channels() == 4) {
        cv::cvtColor(src, src, cv::COLOR_BGRA2BGR);
    }

    cv::Mat color, edges, dst;
    cv::bilateralFilter(src, color, 9, 75, 75);

    cv::Mat gray;
    cv::cvtColor(src, gray, cv::COLOR_BGR2GRAY);

    cv::medianBlur(gray, gray, 45);

    cv::adaptiveThreshold(gray, edges, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 9, 2);

    cv::cvtColor(edges, edges, cv::COLOR_GRAY2BGR);

    cv::bitwise_and(color, edges, dst);

    if (dst.empty()) {
        NSLog(@"Output cartoon image is empty");
        return image;
    }

    // Boost red channel by 30%, clamp max to 255
    std::vector<cv::Mat> channels;
    cv::split(dst, channels);
    channels[2] = cv::min(channels[2] * 3, 255);
    channels[1] = cv::min(channels[1] * 3, 255);
    cv::merge(channels, dst);

    return MatToUIImage(dst);
}

+ (UIImage *)convertToStoryboard:(UIImage *)image {
    @try {
        Mat src;
        UIImageToMat(image, src);
        
        if (src.empty()) {
            NSLog(@"Input image is empty for storyboard filter");
            return image;
        }
        
        // Ensure proper color space
        if (src.channels() == 4) {
            cvtColor(src, src, COLOR_BGRA2BGR);
        }
        
        Mat gray, edges, storyboard;
        
        // Convert to grayscale
        cvtColor(src, gray, COLOR_BGR2GRAY);
        
        // Apply histogram equalization for better contrast
        equalizeHist(gray, gray);
        
        // Reduce noise while preserving edges
        Mat denoised;
        bilateralFilter(gray, denoised, 9, 80, 80);
        
        // Create edges for storyboard outline effect
        Mat edges1;
        adaptiveThreshold(denoised, edges1, 255, ADAPTIVE_THRESH_MEAN_C, THRESH_BINARY, 9, 10);
        
        // Invert edges so lines are black on white background
        bitwise_not(edges1, edges);
        
        // Create shading zones based on intensity levels
        Mat shading;
        gray.copyTo(shading);
        
        // Create multiple intensity levels for sketch-like shading
        Mat level1, level2, level3;
        threshold(shading, level1, 200, 255, THRESH_BINARY);  // Highlights
        threshold(shading, level2, 120, 180, THRESH_BINARY);  // Mid-tones  
        threshold(shading, level3, 60, 120, THRESH_BINARY);   // Shadows
        
        // Combine shading levels
        Mat shadingZones;
        add(level1, level2, shadingZones);
        add(shadingZones, level3, shadingZones);
        
        // Combine edges with shading using OR operation (not AND)
        bitwise_or(edges, shadingZones, storyboard);
        
        // Convert back to BGR for consistency
        Mat result;
        cvtColor(storyboard, result, COLOR_GRAY2BGR);
        
        return MatToUIImage(result);
        
    } @catch (NSException *exception) {
        NSLog(@"Exception in storyboard filter: %@", exception.reason);
        // Return a simple edge-detected version as fallback
        @try {
            Mat src, gray, edges, result;
            UIImageToMat(image, src);
            cvtColor(src, gray, COLOR_BGR2GRAY);
            Canny(gray, edges, 50, 150);
            bitwise_not(edges, edges); // Invert so lines are black
            cvtColor(edges, result, COLOR_GRAY2BGR);
            return MatToUIImage(result);
        } @catch (NSException *e2) {
            NSLog(@"Even fallback failed: %@", e2.reason);
            return image;
        }
    }
}

+ (UIImage *)convertToChalk:(UIImage *)image {
    Mat src;
    UIImageToMat(image, src);
    
    Mat gray, inverted, chalk;
    cvtColor(src, gray, COLOR_BGR2GRAY);
    
    // Invert for chalk on blackboard effect
    bitwise_not(gray, inverted);
    
    // Add texture-like noise
    Mat noise = Mat::zeros(inverted.size(), CV_8UC1);
    randu(noise, 0, 50);
    add(inverted, noise, chalk);
    
    return MatToUIImage(chalk);
}

+ (UIImage *)convertToFeltPen:(UIImage *)image {
    cv::Mat src;
    UIImageToMat(image, src);
    if (src.empty()) {
        NSLog(@"Input image is empty");
        return image;
    }
    if (src.channels() == 4) {
        cv::cvtColor(src, src, cv::COLOR_BGRA2BGR);
    }

    cv::Mat color, edges, dst;
    cv::bilateralFilter(src, color, 9, 75, 75);

    cv::Mat gray;
    cv::cvtColor(src, gray, cv::COLOR_BGR2GRAY);

    cv::medianBlur(gray, gray, 29);

    cv::adaptiveThreshold(gray, edges, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 9, 2);

    cv::cvtColor(edges, edges, cv::COLOR_GRAY2BGR);

    cv::bitwise_and(color, edges, dst);

    if (dst.empty()) {
        NSLog(@"Output cartoon image is empty");
        return image;
    }

    // Boost red channel by 30%, clamp max to 255
    std::vector<cv::Mat> channels;
    cv::split(dst, channels);
    channels[2] = cv::min(channels[2] * 2.2, 255);
    channels[1] = cv::min(channels[1] * 2, 255);
    cv::merge(channels, dst);

    return MatToUIImage(dst);
}

+ (UIImage *)convertToMonochromeSketch:(UIImage *)image {
    cv::Mat src;
    UIImageToMat(image, src);
    if (src.empty()) {
        NSLog(@"Input image is empty");
        return image;
    }
    if (src.channels() == 4) {
        cv::cvtColor(src, src, cv::COLOR_BGRA2BGR);
    }

    cv::Mat color, edges, dst;
    cv::bilateralFilter(src, color, 9, 75, 75);

    cv::Mat gray;
    cv::cvtColor(src, gray, cv::COLOR_BGR2GRAY);

    cv::medianBlur(gray, gray, 7);

    cv::adaptiveThreshold(gray, edges, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 9, 2);

    cv::cvtColor(edges, edges, cv::COLOR_GRAY2BGR);

    cv::bitwise_and(color, edges, dst);

    if (dst.empty()) {
        NSLog(@"Output cartoon image is empty");
        return image;
    }

    // Boost red channel by 30%, clamp max to 255
    std::vector<cv::Mat> channels;
    cv::split(dst, channels);
    channels[1] = cv::min(channels[1] * 1.6, 255);
    cv::merge(channels, dst);

    return MatToUIImage(dst);
}

+ (UIImage *)convertToSplashSketch:(UIImage *)image {
    cv::Mat src;
    UIImageToMat(image, src);
    if (src.empty()) {
        NSLog(@"Input image is empty");
        return image;
    }
    if (src.channels() == 4) {
        cv::cvtColor(src, src, cv::COLOR_BGRA2BGR);
    }

    cv::Mat color, edges, dst;
    cv::bilateralFilter(src, color, 9, 75, 75);

    cv::Mat gray;
    cv::cvtColor(src, gray, cv::COLOR_BGR2GRAY);

    cv::medianBlur(gray, gray, 7);

    cv::adaptiveThreshold(gray, edges, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 9, 2);

    cv::cvtColor(edges, edges, cv::COLOR_GRAY2BGR);

    cv::bitwise_and(color, edges, dst);

    if (dst.empty()) {
        NSLog(@"Output cartoon image is empty");
        return image;
    }

    // Boost red channel by 30%, clamp max to 255
    std::vector<cv::Mat> channels;
    cv::split(dst, channels);
    channels[0] = cv::min(channels[0] * 1.6, 255);
    cv::merge(channels, dst);

    return MatToUIImage(dst);
}

+ (UIImage *)convertToColoringBook:(UIImage *)image {
    Mat src;
    UIImageToMat(image, src);
    
    Mat gray, edges, coloring;
    cvtColor(src, gray, COLOR_BGR2GRAY);
    
    // Strong edge detection for coloring book outlines
    Canny(gray, edges, 50, 150);
    
    // Dilate edges to make them thicker
    Mat kernel = getStructuringElement(MORPH_RECT, cv::Size(2, 2));
    dilate(edges, edges, kernel);
    
    bitwise_not(edges, coloring);
    
    return MatToUIImage(coloring);
}

+ (UIImage *)convertToWaxSketch:(UIImage *)image {
    Mat src;
    UIImageToMat(image, src);
    
    Mat gray, edges, ink;
    cvtColor(src, gray, COLOR_BGR2GRAY);
    
    // Apply bilateral filter to preserve edges
    Mat filtered;
    bilateralFilter(gray, filtered, 9, 80, 80);
    
    // Use multiple edge detection techniques and combine
    Mat canny, sobel;
    
    // Canny edges
    Canny(filtered, canny, 30, 90);
    
    // Sobel edges for additional detail
    Mat sobelX, sobelY;
    Sobel(filtered, sobelX, CV_64F, 1, 0, 3);
    Sobel(filtered, sobelY, CV_64F, 0, 1, 3);
    magnitude(sobelX, sobelY, sobel);
    sobel.convertTo(sobel, CV_8U);
    threshold(sobel, sobel, 50, 255, THRESH_BINARY);
    
    // Combine both edge maps
    bitwise_or(canny, sobel, edges);
    bitwise_not(edges, ink);
    
    return MatToUIImage(ink);
}

+ (UIImage *)convertToPaperSketch:(UIImage *)image {
    cv::Mat src;
    UIImageToMat(image, src);

    if (src.empty()) {
        NSLog(@"Input image is empty");
        return image;
    }

    // Convert BGRA to BGR if needed
    if (src.channels() == 4) {
        cv::cvtColor(src, src, cv::COLOR_BGRA2BGR);
    }

    // Convert to grayscale
    cv::Mat gray;
    cv::cvtColor(src, gray, cv::COLOR_BGR2GRAY);

    // Median blur to smooth and reduce noise
    cv::Mat blurred;
    cv::medianBlur(gray, blurred, 7);

    // Adaptive threshold to extract sketch-like edges
    cv::Mat edges;
    cv::adaptiveThreshold(
        blurred, edges, 255,
        cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY,
        9, 2
    );

    // Invert edges to make lines black on white
    cv::bitwise_not(edges, edges);

    // Optional: Thicken lines via dilation
    cv::Mat kernel = cv::Mat::ones(2, 2, CV_8U);
    cv::Mat dilated;
    cv::dilate(edges, dilated, kernel, cv::Point(-1, -1), 1);

    return MatToUIImage(dilated);
}


+ (UIImage *)convertToNeonSketch:(UIImage *)image {
    Mat src;
    UIImageToMat(image, src);

    if (src.empty()) return image;

    // Convert BGRA to BGR if needed
    if (src.channels() == 4) {
        cvtColor(src, src, COLOR_BGRA2BGR);
    }

    // Resize down for performance
    Mat small;
    resize(src, small, cv::Size(), 0.5, 0.5, INTER_LINEAR);

    // Ensure correct type (CV_8UC3)
    if (small.type() != CV_8UC3) {
        small.convertTo(small, CV_8UC3);
    }

    // Apply bilateral filter twice for strong smoothing
    Mat bilateral1, bilateral2;
    bilateralFilter(small, bilateral1, 9, 75, 75);
    bilateralFilter(bilateral1, bilateral2, 9, 75, 75);

    // Resize smoothed image back to original size
    Mat smooth;
    resize(bilateral2, smooth, src.size(), 0, 0, INTER_LINEAR);

    // Edge detection with adaptive threshold
    Mat gray, edges;
    cvtColor(src, gray, COLOR_BGR2GRAY);
    medianBlur(gray, gray, 7);
    adaptiveThreshold(gray, edges, 255, ADAPTIVE_THRESH_MEAN_C, THRESH_BINARY, 9, 2);
    bitwise_not(edges, edges);  // Make lines black on white

    // Convert edge mask to 3-channel
    Mat edgesColor;
    cvtColor(edges, edgesColor, COLOR_GRAY2BGR);

    // Blend edges with smoothed image
    Mat smoothFloat, edgesFloat, blended;
    smooth.convertTo(smoothFloat, CV_32F, 1.0 / 255.0);
    edgesColor.convertTo(edgesFloat, CV_32F, 1.0 / 255.0);
    multiply(smoothFloat, edgesFloat, blended);
    
    Mat final;
    blended.convertTo(final, CV_8U, 255.0);

    return MatToUIImage(final);
}

+ (UIImage *)convertToAnime:(UIImage *)image {
    cv::Mat src;
    UIImageToMat(image, src);

    if (src.empty()) {
        NSLog(@"Input image is empty");
        return image;
    }

    if (src.channels() == 4) {
        cv::cvtColor(src, src, cv::COLOR_BGRA2BGR);
    }

    cv::Mat color, small, data, labels, centers, edges, anime;

    // Apply strong bilateral filter to smooth colors
    cv::bilateralFilter(src, color, 15, 200, 200);

    // Optionally downscale to accelerate K-means
    cv::resize(color, small, cv::Size(), 0.5, 0.5, cv::INTER_LINEAR);

    // Prepare data for K-means
    small.convertTo(data, CV_32F);
    data = data.reshape(1, static_cast<int>(data.total()));

    // Apply K-means for color quantization
    cv::kmeans(data, 6, labels,
               cv::TermCriteria(cv::TermCriteria::EPS + cv::TermCriteria::COUNT, 20, 1.0),
               3, cv::KMEANS_PP_CENTERS, centers);

    // Map centers back to image
    centers = centers.reshape(3, centers.rows);
    data = data.reshape(3, small.rows);

    cv::Vec3f* p = data.ptr<cv::Vec3f>();
    for (size_t i = 0; i < small.rows * small.cols; i++) {
        int center_id = labels.at<int>(static_cast<int>(i));
        p[i] = centers.at<cv::Vec3f>(center_id);
    }

    data.convertTo(small, CV_8U);

    // Upscale back
    cv::resize(small, color, src.size(), 0, 0, cv::INTER_LINEAR);

    // Create edge mask
    cv::Mat gray;
    cv::cvtColor(src, gray, cv::COLOR_BGR2GRAY);
    cv::adaptiveThreshold(gray, edges, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 9, 9);
    cv::cvtColor(edges, edges, cv::COLOR_GRAY2BGR);

    // Combine edges with color-quantized image
    cv::bitwise_and(color, edges, anime);

    return MatToUIImage(anime);
}


+ (UIImage *)convertToComicBook:(UIImage *)image {
    cv::Mat src;
    UIImageToMat(image, src);
    if (src.empty()) {
        NSLog(@"Input image is empty");
        return image;
    }
    if (src.channels() == 4) {
        cv::cvtColor(src, src, cv::COLOR_BGRA2BGR);
    }

    cv::Mat color, edges, dst;
    cv::bilateralFilter(src, color, 9, 75, 75);

    cv::Mat gray;
    cv::cvtColor(src, gray, cv::COLOR_BGR2GRAY);

    cv::medianBlur(gray, gray, 61);

    cv::adaptiveThreshold(gray, edges, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 9, 2);

    cv::cvtColor(edges, edges, cv::COLOR_GRAY2BGR);

    cv::bitwise_and(color, edges, dst);

    if (dst.empty()) {
        NSLog(@"Output cartoon image is empty");
        return image;
    }

    // Boost red channel by 30%, clamp max to 255
    std::vector<cv::Mat> channels;
    cv::split(dst, channels);
    channels[2] = cv::min(channels[2] * 1.6, 255);
    channels[0] = cv::min(channels[0] * 1.45, 255);
    cv::merge(channels, dst);

    return MatToUIImage(dst);
}


// Video processing with frame-by-frame filtering at 15 FPS and proper threading
+ (BOOL)processVideoWithFilter:(NSString *)inputPath outputPath:(NSString *)outputPath filterType:(NSString *)filterType {
    @try {
        NSLog(@"🎬 iOS processVideoWithFilter called");
        NSLog(@"Starting optimized video processing: %@ -> %@ with filter: %@", inputPath, outputPath, filterType);
        
        // Send initial progress
        NSLog(@"📤 Sending initial progress from processVideoWithFilter...");
        [self sendProgressUpdate:0.0 status:@"Preparing video processing..."];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        // SMART FIX: If filtered video already exists, just use it directly to avoid conflicts
        if ([fileManager fileExistsAtPath:outputPath]) {
            NSLog(@"✅ Filtered video already exists, using existing file: %@", outputPath);
            return YES; // File already exists, no need to process again
        }
        
        // Clean up any existing temporary files first
        NSString *tempDirBase = [NSTemporaryDirectory() stringByAppendingPathComponent:@"video_processing"];
        [fileManager removeItemAtPath:tempDirBase error:nil];
        
        // Create fresh temporary directory for processing
        NSString *tempDir = [tempDirBase stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [[NSProcessInfo processInfo] globallyUniqueString]]];
        NSString *processedFramesDir = [tempDir stringByAppendingPathComponent:@"processed_frames"];
        NSString *tempVideoPath = [tempDir stringByAppendingPathComponent:@"temp_video.mp4"];
        [fileManager createDirectoryAtPath:tempDir withIntermediateDirectories:YES attributes:nil error:nil];
        [fileManager createDirectoryAtPath:processedFramesDir withIntermediateDirectories:YES attributes:nil error:nil];
        
        // Step 1: Extract frames using AVFoundation
        NSURL *inputURL = [NSURL fileURLWithPath:inputPath];
        AVAsset *asset = [AVAsset assetWithURL:inputURL];
        AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        imageGenerator.appliesPreferredTrackTransform = YES;
        imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
        imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
        
        // Get video properties
        AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        if (!videoTrack) {
            NSLog(@"Error: No video track found");
            return NO;
        }
        
        // Get proper video dimensions considering transform
        CGSize videoSize = [videoTrack naturalSize];
        CGAffineTransform transform = [videoTrack preferredTransform];
        
        // Apply transform to get the actual display size
        CGRect transformedRect = CGRectApplyAffineTransform(CGRectMake(0, 0, videoSize.width, videoSize.height), transform);
        CGSize displaySize = CGSizeMake(fabs(transformedRect.size.width), fabs(transformedRect.size.height));
        
        CMTime duration = asset.duration;
        Float64 durationSeconds = CMTimeGetSeconds(duration);
        
        // Get original frame rate from video track
        float originalFrameRate = [videoTrack nominalFrameRate];
        if (originalFrameRate <= 0) {
            originalFrameRate = 30.0f; // Default fallback
        }
        
        NSLog(@"Video properties: %.0fx%.0f (display), %.2f seconds, %.1f fps", displaySize.width, displaySize.height, durationSeconds, originalFrameRate);
        
        // Use ultra-low frame rate for maximum speed (3 FPS)
        const float targetFPS = 3.0f; // Reduced to 3 FPS for ultra-maximum speed
        const float frameInterval = 1.0f / targetFPS;
        const int totalOutputFrames = (int)(durationSeconds * targetFPS);
        
        NSLog(@"Processing %d frames at %.1f FPS (1 frame every %.3f seconds) - ultra-low FPS for maximum speed", totalOutputFrames, targetFPS, frameInterval);
        
        // Compression settings for frames - ultra-low resolution for maximum speed
        CGSize compressedSize = displaySize;
        const CGFloat maxDimension = 240.0; // Reduced to ~240p for ultra-maximum speed
        if (displaySize.width > maxDimension || displaySize.height > maxDimension) {
            CGFloat scale = maxDimension / MAX(displaySize.width, displaySize.height);
            compressedSize = CGSizeMake(displaySize.width * scale, displaySize.height * scale);
            // Ensure even dimensions for video encoding
            compressedSize.width = (int)(compressedSize.width / 2) * 2;
            compressedSize.height = (int)(compressedSize.height / 2) * 2;
        }
        NSLog(@"Compressed frame size: %.0fx%.0f", compressedSize.width, compressedSize.height);
        
        // Step 2: Extract and process frames using concurrent queues
        NSMutableArray *processedFramePaths = [NSMutableArray arrayWithCapacity:totalOutputFrames];
        for (int i = 0; i < totalOutputFrames; i++) {
            [processedFramePaths addObject:[NSNull null]];
        }
        
        dispatch_group_t processingGroup = dispatch_group_create();
        dispatch_queue_t processingQueue = dispatch_queue_create("VideoFrameProcessing", DISPATCH_QUEUE_CONCURRENT);
        dispatch_semaphore_t maxConcurrentSemaphore = dispatch_semaphore_create(2); // Reduced concurrent processing for stability
        
        __block int successCount = 0;
        
        for (int frameIndex = 0; frameIndex < totalOutputFrames; frameIndex++) {
            dispatch_group_enter(processingGroup);
            
            dispatch_async(processingQueue, ^{
                dispatch_semaphore_wait(maxConcurrentSemaphore, DISPATCH_TIME_FOREVER);
                
                @autoreleasepool {
                    // Calculate time for this frame at target FPS
                    CMTime frameTime = CMTimeMakeWithSeconds(frameIndex * frameInterval, 600);
                    NSError *error;
                    
                    CGImageRef cgImage = [imageGenerator copyCGImageAtTime:frameTime actualTime:NULL error:&error];
                    if (cgImage) {
                        // Convert CGImage to UIImage
                        UIImage *frameImage = [UIImage imageWithCGImage:cgImage];
                        CGImageRelease(cgImage);
                        
                        // Compress frame while maintaining aspect ratio
                        UIImage *compressedFrame = [self resizeImage:frameImage toSize:compressedSize];
                        
                        // Convert UIImage to OpenCV Mat
                        cv::Mat frameMat;
                        UIImageToMat(compressedFrame, frameMat);
                        
                        // Apply filter using existing methods
                        cv::Mat processedMat = [self applyFilterToMat:frameMat filterType:filterType];
                        
                        if (!processedMat.empty()) {
                            // Convert back to UIImage and save with ultra-low compression for speed
                            UIImage *processedImage = MatToUIImage(processedMat);
                            NSData *imageData = UIImageJPEGRepresentation(processedImage, 0.3); // Reduced to 30% quality for ultra-maximum speed
                            
                            NSString *framePath = [processedFramesDir stringByAppendingPathComponent:[NSString stringWithFormat:@"frame_%06d.jpg", frameIndex]];
                            if ([imageData writeToFile:framePath atomically:YES]) {
                                processedFramePaths[frameIndex] = framePath;
                                @synchronized(self) {
                                    successCount++;
                                    
                                    // Send progress updates
                                    double progress = (double)successCount / totalOutputFrames * 0.8; // 80% for frame processing
                                    int percentage = (int)(progress * 100);
                                    
                                    if (successCount % 3 == 0) { // Log and update progress every 3 frames
                                        NSLog(@"Processed %d/%d frames (%d%%)", successCount, totalOutputFrames, percentage);
                                        [self sendProgressUpdate:progress status:[NSString stringWithFormat:@"Processing frames... %d%%", percentage]];
                                    }
                                }
                            }
                        }
                    }
                }
                
                dispatch_semaphore_signal(maxConcurrentSemaphore);
                dispatch_group_leave(processingGroup);
            });
        }
        
        // Wait for all frame processing to complete
        // Wait for processing with timeout to prevent infinite loading
        dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 300 * NSEC_PER_SEC); // 5 minute timeout
        long result = dispatch_group_wait(processingGroup, timeout);
        
        if (result != 0) {
            NSLog(@"❌ Video processing timed out after 5 minutes");
            return NO;
        }
        
        NSLog(@"Frame processing completed: %d/%d frames successful", successCount, totalOutputFrames);
        
        if (successCount == 0) {
            NSLog(@"Error: No frames were processed successfully");
            [self sendProgressUpdate:0.0 status:@"Video processing failed"];
            return NO;
        }
        
        // Send progress update for video creation phase
        [self sendProgressUpdate:0.8 status:@"Creating video from processed frames..."];
        
        // Step 3: Create video from processed frames at target FPS
        NSURL *tempVideoURL = [NSURL fileURLWithPath:tempVideoPath];
        AVAssetWriter *assetWriter = [[AVAssetWriter alloc] initWithURL:tempVideoURL fileType:AVFileTypeMPEG4 error:nil];
        
        // Video settings with compressed dimensions
        NSDictionary *videoSettings = @{
            AVVideoCodecKey: AVVideoCodecTypeH264,
            AVVideoWidthKey: @((int)compressedSize.width),
            AVVideoHeightKey: @((int)compressedSize.height),
            AVVideoCompressionPropertiesKey: @{
                AVVideoAverageBitRateKey: @(300000), // Ultra-low bitrate for maximum speed
                AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel,
                AVVideoMaxKeyFrameIntervalKey: @(targetFPS * 3) // Keyframe every 3 seconds (less frequent for ultra-low FPS)
            }
        };
        
        AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
        AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
        
        [assetWriter addInput:writerInput];
        [assetWriter startWriting];
        [assetWriter startSessionAtSourceTime:kCMTimeZero];
        
        dispatch_semaphore_t writingSemaphore = dispatch_semaphore_create(0);
        __block BOOL writeSuccess = YES;
        
        [writerInput requestMediaDataWhenReadyOnQueue:dispatch_queue_create("VideoWritingQueue", DISPATCH_QUEUE_SERIAL) usingBlock:^{
            int frameIndex = 0;
            while ([writerInput isReadyForMoreMediaData] && frameIndex < totalOutputFrames && writeSuccess) {
                @autoreleasepool {
                    id framePath = processedFramePaths[frameIndex];
                    if (![framePath isKindOfClass:[NSNull class]]) {
                        UIImage *frameImage = [UIImage imageWithContentsOfFile:(NSString *)framePath];
                        
                        if (frameImage) {
                            CVPixelBufferRef pixelBuffer = [self pixelBufferFromImage:frameImage size:compressedSize];
                            if (pixelBuffer) {
                                // Correct frame timing at target FPS
                                CMTime presentationTime = CMTimeMakeWithSeconds(frameIndex * frameInterval, 600);
                                if (![adaptor appendPixelBuffer:pixelBuffer withPresentationTime:presentationTime]) {
                                    NSLog(@"Error appending frame %d", frameIndex);
                                    writeSuccess = NO;
                                }
                                CVPixelBufferRelease(pixelBuffer);
                            }
                        }
                    }
                    frameIndex++;
                }
            }
            
            [writerInput markAsFinished];
            [assetWriter finishWritingWithCompletionHandler:^{
                writeSuccess = writeSuccess && (assetWriter.status == AVAssetWriterStatusCompleted);
                if (!writeSuccess) {
                    NSLog(@"Asset writer error: %@", assetWriter.error);
                }
                dispatch_semaphore_signal(writingSemaphore);
            }];
        }];
        
        // Wait for video writing with timeout to prevent infinite loading
        dispatch_time_t writeTimeout = dispatch_time(DISPATCH_TIME_NOW, 120 * NSEC_PER_SEC); // 2 minute timeout
        long writeResult = dispatch_semaphore_wait(writingSemaphore, writeTimeout);
        
        if (writeResult != 0) {
            NSLog(@"❌ Video writing timed out after 2 minutes");
            writeSuccess = NO;
        }
        
        if (!writeSuccess) {
            NSLog(@"Error creating video from frames");
            return NO;
        }
        
        // Step 4: Merge processed video with original audio
        writeSuccess = [self mergeVideo:tempVideoPath withAudioFromVideo:inputPath outputPath:outputPath];
        
        // Cleanup - ensure we always clean up temporary files
        NSError *cleanupError;
        if (![fileManager removeItemAtPath:tempDir error:&cleanupError]) {
            NSLog(@"Warning: Failed to clean up temp directory: %@", cleanupError.localizedDescription);
        }
        
        if (writeSuccess) {
            NSLog(@"Video processing completed successfully: YES");
            [self sendProgressUpdate:1.0 status:@"Video processing complete!"];
        } else {
            NSLog(@"Video processing completed successfully: NO");
            [self sendProgressUpdate:0.0 status:@"Video processing failed"];
        }
        return writeSuccess;
        
    } @catch (NSException *exception) {
        NSLog(@"Exception during video processing: %@", exception.reason);
        
        // Cleanup on exception
        NSString *tempDirBase = [NSTemporaryDirectory() stringByAppendingPathComponent:@"video_processing"];
        [[NSFileManager defaultManager] removeItemAtPath:tempDirBase error:nil];
        
        return NO;
    }
}

// Helper method to apply filters to OpenCV Mat
+ (cv::Mat)applyFilterToMat:(cv::Mat)mat filterType:(NSString *)filterType {
    NSLog(@"Applying video filter: %@ to frame size: %dx%d", filterType, mat.cols, mat.rows);
    
    if (mat.empty()) {
        NSLog(@"ERROR: Input frame is empty for filter: %@", filterType);
        return mat.clone();
    }
    
    cv::Mat result;
    if ([filterType isEqualToString:@"charcoalSketch"]) {
        result = [self applyCharcoalSketchFilter:mat];
    } else if ([filterType isEqualToString:@"inkPen"]) {
        result = [self applyInkPenFilter:mat];
    } else if ([filterType isEqualToString:@"cartoon"]) {
        result = [self applyCartoonFilter:mat];
    } else if ([filterType isEqualToString:@"softPen"]) {
        result = [self applySoftPenFilter:mat];
    } else if ([filterType isEqualToString:@"noirSketch"]) {
        result = [self applyNoirSketchFilter:mat];
    } else if ([filterType isEqualToString:@"storyboard"]) {
        result = [self applyStoryboardFilter:mat];
    } else if ([filterType isEqualToString:@"chalk"]) {
        result = [self applyChalkFilter:mat];
    } else if ([filterType isEqualToString:@"feltPen"]) {
        result = [self applyFeltPenFilter:mat];
    } else if ([filterType isEqualToString:@"monochromeSketch"]) {
        result = [self applyMonochromeSketchFilter:mat];
    } else if ([filterType isEqualToString:@"splashSketch"]) {
        result = [self applySplashSketchFilter:mat];
    } else if ([filterType isEqualToString:@"coloringBook"]) {
        result = [self applyColoringBookFilter:mat];
    } else if ([filterType isEqualToString:@"paperSketch"]) {
        result = [self applyPaperSketchFilter:mat];
    } else if ([filterType isEqualToString:@"neonSketch"]) {
        result = [self applyNeonSketchFilter:mat];
    } else {
        NSLog(@"WARNING: Unknown filter type: %@, returning original", filterType);
        result = mat.clone();
    }
    
    if (result.empty()) {
        NSLog(@"ERROR: Filter %@ returned empty result, using original", filterType);
        return mat.clone();
    }
    
    NSLog(@"Successfully applied filter: %@, result size: %dx%d", filterType, result.cols, result.rows);
    return result;
}

// Helper method to resize image while maintaining aspect ratio
+ (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)targetSize {
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    
    // If already at target size or smaller, return original
    if (imageWidth <= targetSize.width && imageHeight <= targetSize.height) {
        return image;
    }
    
    // Calculate scale maintaining aspect ratio
    CGFloat widthScale = targetSize.width / imageWidth;
    CGFloat heightScale = targetSize.height / imageHeight;
    CGFloat scale = MIN(widthScale, heightScale);
    
    CGSize scaledSize = CGSizeMake(imageWidth * scale, imageHeight * scale);
    
    UIGraphicsBeginImageContextWithOptions(scaledSize, NO, 1.0);
    [image drawInRect:CGRectMake(0, 0, scaledSize.width, scaledSize.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage ?: image;
}

// Helper method to convert UIImage to CVPixelBuffer with specific size
+ (CVPixelBufferRef)pixelBufferFromImage:(UIImage *)image size:(CGSize)size {
    NSDictionary *options = @{
        (NSString *)kCVPixelBufferCGImageCompatibilityKey: @YES,
        (NSString *)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES
    };
    
    CVPixelBufferRef pixelBuffer;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, (int)size.width, (int)size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef)options, &pixelBuffer);
    
    if (status != kCVReturnSuccess) {
        NSLog(@"Error creating pixel buffer: %d", status);
        return NULL;
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *data = CVPixelBufferGetBaseAddress(pixelBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(data, (int)size.width, (int)size.height, 8, CVPixelBufferGetBytesPerRow(pixelBuffer), colorSpace, kCGImageAlphaNoneSkipFirst);
    
    if (!context) {
        NSLog(@"Error creating CGContext");
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        CVPixelBufferRelease(pixelBuffer);
        CGColorSpaceRelease(colorSpace);
        return NULL;
    }
    
    // Clear the context with black
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    
    // Calculate centered rect for image
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    CGFloat scale = MIN(size.width / imageWidth, size.height / imageHeight);
    CGFloat scaledWidth = imageWidth * scale;
    CGFloat scaledHeight = imageHeight * scale;
    CGFloat x = (size.width - scaledWidth) / 2;
    CGFloat y = (size.height - scaledHeight) / 2;
    
    CGContextDrawImage(context, CGRectMake(x, y, scaledWidth, scaledHeight), image.CGImage);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return pixelBuffer;
}

// Legacy method for backward compatibility
+ (CVPixelBufferRef)pixelBufferFromImage:(UIImage *)image {
    return [self pixelBufferFromImage:image size:image.size];
}

// Helper method to merge video with audio using AVFoundation
+ (BOOL)mergeVideo:(NSString *)videoPath withAudioFromVideo:(NSString *)audioVideoPath outputPath:(NSString *)outputPath {
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    NSURL *audioVideoURL = [NSURL fileURLWithPath:audioVideoPath];
    NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
    
    AVAsset *videoAsset = [AVAsset assetWithURL:videoURL];
    AVAsset *audioVideoAsset = [AVAsset assetWithURL:audioVideoURL];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    // Add video track
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *sourceVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:sourceVideoTrack atTime:kCMTimeZero error:nil];
    
    // Add audio track if available
    NSArray *audioTracks = [audioVideoAsset tracksWithMediaType:AVMediaTypeAudio];
    if (audioTracks.count > 0) {
        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        AVAssetTrack *sourceAudioTrack = audioTracks.firstObject;
        CMTime minDuration = CMTimeMinimum(videoAsset.duration, audioVideoAsset.duration);
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, minDuration) ofTrack:sourceAudioTrack atTime:kCMTimeZero error:nil];
    }
    
    // Export the composition
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block BOOL success = NO;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        success = (exportSession.status == AVAssetExportSessionStatusCompleted);
        if (!success) {
            NSLog(@"Export failed: %@", exportSession.error.localizedDescription);
        }
        dispatch_semaphore_signal(semaphore);
    }];
    
    // Wait for audio merging with timeout 
    dispatch_time_t mergeTimeout = dispatch_time(DISPATCH_TIME_NOW, 60 * NSEC_PER_SEC); // 1 minute timeout
    long mergeResult = dispatch_semaphore_wait(semaphore, mergeTimeout);
    
    if (mergeResult != 0) {
        NSLog(@"❌ Audio merging timed out after 1 minute");
        success = NO;
    }
    
    return success;
}

// Helper methods to apply filters to individual frames
+ (cv::Mat)applySketchFilter:(cv::Mat)frame {
    if (frame.empty()) {
        NSLog(@"Input frame is empty");
        return frame.clone();
    }

    // Convert to grayscale
    cv::Mat gray;
    cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);

    // Invert grayscale
    cv::Mat invGray = 255 - gray;

    // Heavy Gaussian blur on inverted image
    cv::Mat blurImg;
    cv::GaussianBlur(invGray, blurImg, cv::Size(101, 101), 0);

    // Invert the blurred image
    cv::Mat invBlur = 255 - blurImg;

    // Create sketch by dividing gray by invBlur, scale=255.0
    cv::Mat sketchImg;
    cv::divide(gray, invBlur, sketchImg, 255.0);

    return sketchImg;
}

+ (cv::Mat)applyCharcoalSketchFilter:(cv::Mat)frame {
    if (frame.empty()) {
        NSLog(@"Input frame is empty");
        return frame.clone();
    }

    if (frame.channels() == 4) {
        cv::cvtColor(frame, frame, cv::COLOR_BGRA2BGR);
    }

    // Grayscale
    cv::Mat gray;
    cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);

    // Gaussian Blur
    cv::Mat blur;
    cv::GaussianBlur(gray, blur, cv::Size(5, 5), 2);

    // Sobel gradients
    cv::Mat sobelX, sobelY;
    cv::Sobel(blur, sobelX, CV_64F, 1, 0, 5);
    cv::Sobel(blur, sobelY, CV_64F, 0, 1, 5);

    // Gradient magnitude: sqrt(sobelX^2 + sobelY^2)
    cv::Mat gradMagSq;
    cv::Mat sobelXSq, sobelYSq;
    cv::multiply(sobelX, sobelX, sobelXSq);
    cv::multiply(sobelY, sobelY, sobelYSq);
    gradMagSq = sobelXSq + sobelYSq;

    cv::Mat gradMag;
    cv::sqrt(gradMagSq, gradMag);

    // Clip values to 0-255 and convert to 8U
    cv::Mat gradMag8U;
    gradMag.convertTo(gradMag8U, CV_8U);

    // Invert
    cv::Mat gradMagInv = 255 - gradMag8U;

    // Threshold
    cv::Mat threshImg;
    cv::threshold(gradMagInv, threshImg, 10, 255, cv::THRESH_BINARY);

    return threshImg;
}

+ (cv::Mat)applyInkPenFilter:(cv::Mat)frame {
    cv::Mat gray, edges, ink;
    cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);
    
    // Apply bilateral filter to preserve edges
    cv::Mat filtered;
    cv::bilateralFilter(gray, filtered, 9, 80, 80);
    
    // Use multiple edge detection techniques and combine
    cv::Mat canny, sobel;
    
    // Canny edges
    cv::Canny(filtered, canny, 30, 90);
    
    // Sobel edges for additional detail
    cv::Mat sobelX, sobelY;
    cv::Sobel(filtered, sobelX, CV_64F, 1, 0, 3);
    cv::Sobel(filtered, sobelY, CV_64F, 0, 1, 3);
    cv::magnitude(sobelX, sobelY, sobel);
    sobel.convertTo(sobel, CV_8U);
    cv::threshold(sobel, sobel, 50, 255, cv::THRESH_BINARY);
    
    // Combine both edge maps
    cv::bitwise_or(canny, sobel, edges);
    cv::bitwise_not(edges, ink);
    
    return ink;
}

+ (cv::Mat)applyColorSketchFilter:(cv::Mat)frame {
    if (frame.empty()) return frame.clone();

    if (frame.channels() == 4) {
        cv::cvtColor(frame, frame, cv::COLOR_BGRA2BGR);
    }

    // Result Mats
    cv::Mat dst_gray, dst_color;

    // Apply color pencil sketch
    cv::pencilSketch(frame, dst_gray, dst_color, 60, 0.07, 0.05);

    return dst_color;
}

+ (cv::Mat)applyCartoonFilter:(cv::Mat)frame {
    if (frame.empty()) {
        NSLog(@"Frame is empty in applyCartoonFilter");
        return frame.clone();
    }
    
    // Ensure proper color space
    cv::Mat src = frame.clone();
    if (src.channels() == 4) {
        cv::cvtColor(src, src, cv::COLOR_BGRA2BGR);
    }
    
    cv::Mat color, gray, edges, cartoon;
    
    // Use separate Mat for bilateral filter output
    cv::bilateralFilter(src, color, 9, 75, 75);
    cv::cvtColor(src, gray, cv::COLOR_BGR2GRAY);
    cv::medianBlur(gray, gray, 7);
    cv::adaptiveThreshold(gray, edges, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 9, 2);
    cv::cvtColor(edges, edges, cv::COLOR_GRAY2BGR);
    cv::bitwise_and(color, edges, cartoon);
    
    return cartoon;
}

+ (cv::Mat)applyTechPenFilter:(cv::Mat)frame {
    if (frame.empty()) {
        NSLog(@"Input frame is empty");
        return frame.clone();
    }
    if (frame.channels() == 4) {
        cv::cvtColor(frame, frame, cv::COLOR_BGRA2BGR);
    }

    cv::Mat color, edges, dst;
    cv::bilateralFilter(frame, color, 9, 75, 75);

    cv::Mat gray;
    cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);

    cv::medianBlur(gray, gray, 7);

    cv::adaptiveThreshold(gray, edges, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 9, 2);

    cv::cvtColor(edges, edges, cv::COLOR_GRAY2BGR);

    cv::bitwise_and(color, edges, dst);

    if (dst.empty()) {
        NSLog(@"Output cartoon image is empty");
        return frame.clone();
    }

    // Boost red channel by 30%, clamp max to 255
    std::vector<cv::Mat> channels;
    cv::split(dst, channels);
    channels[2] = cv::min(channels[2] * 1.6, 255);
    cv::merge(channels, dst);

    return dst;
}

+ (cv::Mat)applySoftPenFilter:(cv::Mat)frame {
    cv::Mat gray, invGray, blur, soft;
    cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);
    cv::bitwise_not(gray, invGray);
    cv::GaussianBlur(invGray, blur, cv::Size(25, 25), 0);
    
    cv::divide(gray, 255 - blur, soft, 256);
    
    // Additional softening
    cv::GaussianBlur(soft, soft, cv::Size(3, 3), 0);
    
    return soft;
}

+ (cv::Mat)applyNoirSketchFilter:(cv::Mat)frame {
    cv::Mat gray, noir;
    cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);
    
    // High contrast for noir effect
    gray.convertTo(noir, -1, 2.0, -50);
    
    // Apply threshold for dramatic effect
    cv::threshold(noir, noir, 127, 255, cv::THRESH_BINARY);
    
    return noir;
}

+ (cv::Mat)applyCartoon2Filter:(cv::Mat)frame {
    if (frame.empty()) {
        NSLog(@"Input frame is empty");
        return frame.clone();
    }
    if (frame.channels() == 4) {
        cv::cvtColor(frame, frame, cv::COLOR_BGRA2BGR);
    }

    cv::Mat color, edges, dst;
    cv::bilateralFilter(frame, color, 9, 75, 75);

    cv::Mat gray;
    cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);

    cv::medianBlur(gray, gray, 45);

    cv::adaptiveThreshold(gray, edges, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 9, 2);

    cv::cvtColor(edges, edges, cv::COLOR_GRAY2BGR);

    cv::bitwise_and(color, edges, dst);

    if (dst.empty()) {
        NSLog(@"Output cartoon image is empty");
        return frame.clone();
    }

    // Boost red channel by 30%, clamp max to 255
    std::vector<cv::Mat> channels;
    cv::split(dst, channels);
    channels[2] = cv::min(channels[2] * 3, 255);
    channels[1] = cv::min(channels[1] * 3, 255);
    cv::merge(channels, dst);

    return dst;
}

+ (cv::Mat)applyStoryboardFilter:(cv::Mat)frame {
    try {
        if (frame.empty()) {
            NSLog(@"Frame is empty in applyStoryboardFilter");
            return frame.clone();
        }
        
        cv::Mat gray, edges, storyboard;
        
        // Convert to grayscale
        cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);
        
        // Apply histogram equalization for better contrast
        cv::equalizeHist(gray, gray);
        
        // Reduce noise while preserving edges
        cv::Mat denoised;
        cv::bilateralFilter(gray, denoised, 9, 80, 80);
        
        // Create edges for storyboard outline effect
        cv::Mat edges1;
        cv::adaptiveThreshold(denoised, edges1, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 9, 10);
        
        // Invert edges so lines are black on white background
        cv::bitwise_not(edges1, edges);
        
        // Create shading zones based on intensity levels
        cv::Mat shading;
        gray.copyTo(shading);
        
        // Create multiple intensity levels for sketch-like shading
        cv::Mat level1, level2, level3;
        cv::threshold(shading, level1, 200, 255, cv::THRESH_BINARY);  // Highlights
        cv::threshold(shading, level2, 120, 180, cv::THRESH_BINARY);  // Mid-tones  
        cv::threshold(shading, level3, 60, 120, cv::THRESH_BINARY);   // Shadows
        
        // Combine shading levels
        cv::Mat shadingZones;
        cv::add(level1, level2, shadingZones);
        cv::add(shadingZones, level3, shadingZones);
        
        // Combine edges with shading using OR operation (not AND)
        cv::bitwise_or(edges, shadingZones, storyboard);
        
        // Convert back to BGR for consistency
        cv::Mat result;
        cv::cvtColor(storyboard, result, cv::COLOR_GRAY2BGR);
        
        return result;
        
    } catch (cv::Exception& e) {
        NSLog(@"OpenCV exception in storyboard filter: %s", e.what());
        // Return a simple edge-detected version as fallback
        try {
            cv::Mat gray, edges, result;
            cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);
            cv::Canny(gray, edges, 50, 150);
            cv::bitwise_not(edges, edges); // Invert so lines are black
            cv::cvtColor(edges, result, cv::COLOR_GRAY2BGR);
            return result;
        } catch (cv::Exception& e2) {
            NSLog(@"Even fallback failed: %s", e2.what());
            return frame.clone();
        }
    }
}

+ (cv::Mat)applyChalkFilter:(cv::Mat)frame {
    cv::Mat gray, inverted, chalk;
    cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);
    
    // Invert for chalk on blackboard effect
    cv::bitwise_not(gray, inverted);
    
    // Add texture-like noise
    cv::Mat noise = cv::Mat::zeros(inverted.size(), CV_8UC1);
    cv::randu(noise, 0, 50);
    cv::add(inverted, noise, chalk);
    
    return chalk;
}

+ (cv::Mat)applyFeltPenFilter:(cv::Mat)frame {
    if (frame.empty()) {
        NSLog(@"Input frame is empty");
        return frame.clone();
    }
    if (frame.channels() == 4) {
        cv::cvtColor(frame, frame, cv::COLOR_BGRA2BGR);
    }

    cv::Mat color, edges, dst;
    cv::bilateralFilter(frame, color, 9, 75, 75);

    cv::Mat gray;
    cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);

    cv::medianBlur(gray, gray, 29);

    cv::adaptiveThreshold(gray, edges, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 9, 2);

    cv::cvtColor(edges, edges, cv::COLOR_GRAY2BGR);

    cv::bitwise_and(color, edges, dst);

    if (dst.empty()) {
        NSLog(@"Output cartoon image is empty");
        return frame.clone();
    }

    // Boost red channel by 30%, clamp max to 255
    std::vector<cv::Mat> channels;
    cv::split(dst, channels);
    channels[2] = cv::min(channels[2] * 2.2, 255);
    channels[1] = cv::min(channels[1] * 2, 255);
    cv::merge(channels, dst);

    return dst;
}

+ (cv::Mat)applyMonochromeSketchFilter:(cv::Mat)frame {
    if (frame.empty()) {
        NSLog(@"Input frame is empty");
        return frame.clone();
    }
    if (frame.channels() == 4) {
        cv::cvtColor(frame, frame, cv::COLOR_BGRA2BGR);
    }

    cv::Mat color, edges, dst;
    cv::bilateralFilter(frame, color, 9, 75, 75);

    cv::Mat gray;
    cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);

    cv::medianBlur(gray, gray, 7);

    cv::adaptiveThreshold(gray, edges, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 9, 2);

    cv::cvtColor(edges, edges, cv::COLOR_GRAY2BGR);

    cv::bitwise_and(color, edges, dst);

    if (dst.empty()) {
        NSLog(@"Output cartoon image is empty");
        return frame.clone();
    }

    // Boost red channel by 30%, clamp max to 255
    std::vector<cv::Mat> channels;
    cv::split(dst, channels);
    channels[1] = cv::min(channels[1] * 1.6, 255);
    cv::merge(channels, dst);

    return dst;
}

+ (cv::Mat)applySplashSketchFilter:(cv::Mat)frame {
    if (frame.empty()) {
        NSLog(@"Input frame is empty");
        return frame.clone();
    }
    if (frame.channels() == 4) {
        cv::cvtColor(frame, frame, cv::COLOR_BGRA2BGR);
    }

    cv::Mat color, edges, dst;
    cv::bilateralFilter(frame, color, 9, 75, 75);

    cv::Mat gray;
    cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);

    cv::medianBlur(gray, gray, 7);

    cv::adaptiveThreshold(gray, edges, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 9, 2);

    cv::cvtColor(edges, edges, cv::COLOR_GRAY2BGR);

    cv::bitwise_and(color, edges, dst);

    if (dst.empty()) {
        NSLog(@"Output cartoon image is empty");
        return frame.clone();
    }

    // Boost red channel by 30%, clamp max to 255
    std::vector<cv::Mat> channels;
    cv::split(dst, channels);
    channels[0] = cv::min(channels[0] * 1.6, 255);
    cv::merge(channels, dst);

    return dst;
}

+ (cv::Mat)applyColoringBookFilter:(cv::Mat)frame {
    cv::Mat gray, edges, coloring;
    cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);
    
    // Strong edge detection for coloring book outlines
    cv::Canny(gray, edges, 50, 150);
    
    // Dilate edges to make them thicker
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(2, 2));
    cv::dilate(edges, edges, kernel);
    
    cv::bitwise_not(edges, coloring);
    
    return coloring;
}

+ (cv::Mat)applyWaxSketchFilter:(cv::Mat)frame {
    cv::Mat gray, edges, ink;
    cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);
    
    // Apply bilateral filter to preserve edges
    cv::Mat filtered;
    cv::bilateralFilter(gray, filtered, 9, 80, 80);
    
    // Use multiple edge detection techniques and combine
    cv::Mat canny, sobel;
    
    // Canny edges
    cv::Canny(filtered, canny, 30, 90);
    
    // Sobel edges for additional detail
    cv::Mat sobelX, sobelY;
    cv::Sobel(filtered, sobelX, CV_64F, 1, 0, 3);
    cv::Sobel(filtered, sobelY, CV_64F, 0, 1, 3);
    cv::magnitude(sobelX, sobelY, sobel);
    sobel.convertTo(sobel, CV_8U);
    cv::threshold(sobel, sobel, 50, 255, cv::THRESH_BINARY);
    
    // Combine both edge maps
    cv::bitwise_or(canny, sobel, edges);
    cv::bitwise_not(edges, ink);
    
    return ink;
}

+ (cv::Mat)applyPaperSketchFilter:(cv::Mat)frame {
    if (frame.empty()) {
        NSLog(@"Input image is empty");
        return frame.clone();
    }

    // Convert BGRA to BGR if needed
    if (frame.channels() == 4) {
        cv::cvtColor(frame, frame, cv::COLOR_BGRA2BGR);
    }

    // Convert to grayscale
    cv::Mat gray;
    cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);

    // Median blur to smooth and reduce noise
    cv::Mat blurred;
    cv::medianBlur(gray, blurred, 7);

    // Adaptive threshold to extract sketch-like edges
    cv::Mat edges;
    cv::adaptiveThreshold(
        blurred, edges, 255,
        cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY,
        9, 2
    );

    // Invert edges to make lines black on white
    cv::bitwise_not(edges, edges);

    // Optional: Thicken lines via dilation
    cv::Mat kernel = cv::Mat::ones(2, 2, CV_8U);
    cv::Mat dilated;
    cv::dilate(edges, dilated, kernel, cv::Point(-1, -1), 1);

    return dilated;
}

+ (cv::Mat)applyNeonSketchFilter:(cv::Mat)frame {
    if (frame.empty()) return frame.clone();

    // Convert BGRA to BGR if needed
    if (frame.channels() == 4) {
        cv::cvtColor(frame, frame, cv::COLOR_BGRA2BGR);
    }

    // Resize down for performance
    cv::Mat small;
    cv::resize(frame, small, cv::Size(), 0.5, 0.5, cv::INTER_LINEAR);

    // Ensure correct type (CV_8UC3)
    if (small.type() != CV_8UC3) {
        small.convertTo(small, CV_8UC3);
    }

    // Apply bilateral filter twice for strong smoothing
    cv::Mat bilateral1, bilateral2;
    cv::bilateralFilter(small, bilateral1, 9, 75, 75);
    cv::bilateralFilter(bilateral1, bilateral2, 9, 75, 75);

    // Resize smoothed image back to original size
    cv::Mat smooth;
    cv::resize(bilateral2, smooth, frame.size(), 0, 0, cv::INTER_LINEAR);

    // Edge detection with adaptive threshold
    cv::Mat gray, edges;
    cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);
    cv::medianBlur(gray, gray, 7);
    cv::adaptiveThreshold(gray, edges, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 9, 2);
    cv::bitwise_not(edges, edges);  // Make lines black on white

    // Convert edge mask to 3-channel
    cv::Mat edgesColor;
    cv::cvtColor(edges, edgesColor, cv::COLOR_GRAY2BGR);

    // Blend edges with smoothed image
    cv::Mat smoothFloat, edgesFloat, blended;
    smooth.convertTo(smoothFloat, CV_32F, 1.0 / 255.0);
    edgesColor.convertTo(edgesFloat, CV_32F, 1.0 / 255.0);
    cv::multiply(smoothFloat, edgesFloat, blended);
    
    cv::Mat final;
    blended.convertTo(final, CV_8U, 255.0);

    return final;
}

+ (cv::Mat)applyAnimeFilter:(cv::Mat)frame {
    if (frame.empty()) {
        NSLog(@"Input frame is empty");
        return frame.clone();
    }

    if (frame.channels() == 4) {
        cv::cvtColor(frame, frame, cv::COLOR_BGRA2BGR);
    }

    cv::Mat color, small, data, labels, centers, edges, anime;

    // Strong bilateral filter to smooth colors
    cv::bilateralFilter(frame, color, 15, 200, 200);

    // === Optional downscale for faster k-means ===
    cv::resize(color, small, cv::Size(), 0.5, 0.5, cv::INTER_LINEAR);

    // Prepare data for k-means
    small.convertTo(data, CV_32F);
    data = data.reshape(1, static_cast<int>(data.total()));

    // K-means clustering
    cv::kmeans(data, 6, labels,
               cv::TermCriteria(cv::TermCriteria::EPS + cv::TermCriteria::COUNT, 20, 1.0),
               3, cv::KMEANS_PP_CENTERS, centers);

    // Map cluster centers back to image
    centers = centers.reshape(3, centers.rows);
    data = data.reshape(3, small.rows);

    cv::Vec3f* p = data.ptr<cv::Vec3f>();
    for (size_t i = 0; i < static_cast<size_t>(small.rows * small.cols); i++) {
        int center_id = labels.at<int>(static_cast<int>(i));
        p[i] = centers.at<cv::Vec3f>(center_id);
    }

    data.convertTo(small, CV_8U);

    // Upscale back to original size
    cv::resize(small, color, frame.size(), 0, 0, cv::INTER_LINEAR);

    // === Edge detection ===
    cv::Mat gray;
    cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);
    cv::adaptiveThreshold(gray, edges, 255, cv::ADAPTIVE_THRESH_MEAN_C,
                          cv::THRESH_BINARY, 9, 9);
    cv::cvtColor(edges, edges, cv::COLOR_GRAY2BGR);

    // === Combine edges with reduced color ===
    cv::bitwise_and(color, edges, anime);

    return anime;
}



// + (cv::Mat)applyAnimeFilter:(cv::Mat)frame {
//     if (frame.empty()) {
//         NSLog(@"Input frame is empty");
//         return frame.clone();
//     }

//     if (frame.channels() == 4) {
//         cv::cvtColor(frame, frame, cv::COLOR_BGRA2BGR);
//     }
    
//     cv::Mat color, edges, anime;
    
//     // Use separate Mat for bilateral filter output
//     cv::bilateralFilter(frame, color, 15, 200, 200);
    
//     // Reduce colors further using K-means
//     cv::Mat data;
//     color.convertTo(data, CV_32F);
//     data = data.reshape(1, (int)data.total());
    
//     cv::Mat labels, centers;
//     cv::kmeans(data, 6, labels, cv::TermCriteria(cv::TermCriteria::EPS + cv::TermCriteria::COUNT, 20, 1.0), 3, cv::KMEANS_PP_CENTERS, centers);
    
//     centers = centers.reshape(3, centers.rows);
//     data = data.reshape(3, color.rows);
    
//     cv::Vec3f* p = data.ptr<cv::Vec3f>();
//     for (size_t i = 0; i < data.rows * data.cols; i++) {
//         int center_id = labels.at<int>((int)i);
//         p[i] = centers.at<cv::Vec3f>(center_id);
//     }
    
//     data.convertTo(color, CV_8U);
    
//     // Add clean edges
//     cv::Mat gray;
//     cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);
//     cv::adaptiveThreshold(gray, edges, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 9, 9);
//     cv::cvtColor(edges, edges, cv::COLOR_GRAY2BGR);
    
//     cv::bitwise_and(color, edges, anime);
    
//     return anime;
// }

+ (cv::Mat)applyComicBookFilter:(cv::Mat)frame {
    if (frame.empty()) {
        NSLog(@"Input frame is empty");
        return frame.clone();
    }
    if (frame.channels() == 4) {
        cv::cvtColor(frame, frame, cv::COLOR_BGRA2BGR);
    }

    cv::Mat color, edges, dst;
    cv::bilateralFilter(frame, color, 9, 75, 75);

    cv::Mat gray;
    cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);

    cv::medianBlur(gray, gray, 61);

    cv::adaptiveThreshold(gray, edges, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 9, 2);

    cv::cvtColor(edges, edges, cv::COLOR_GRAY2BGR);

    cv::bitwise_and(color, edges, dst);

    if (dst.empty()) {
        NSLog(@"Output cartoon image is empty");
        return frame.clone();
    }

    // Boost red channel by 30%, clamp max to 255
    std::vector<cv::Mat> channels;
    cv::split(dst, channels);
    channels[2] = cv::min(channels[2] * 1.6, 255);
    channels[0] = cv::min(channels[0] * 1.45, 255);
    cv::merge(channels, dst);

    return dst;
}

// New frame-based video processing methods
+ (NSDictionary *)extractFramesFromVideo:(NSString *)inputPath outputDirectory:(NSString *)outputDirectory targetFPS:(float)targetFPS {
    @try {
        NSLog(@"🎬 Starting frame extraction: %@ -> %@ at %.1f FPS", inputPath, outputDirectory, targetFPS);
        
        // Check if input file exists
        if (![[NSFileManager defaultManager] fileExistsAtPath:inputPath]) {
            NSLog(@"❌ Input video file not found: %@", inputPath);
            return nil;
        }
        
        // Create output directory if it doesn't exist
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:outputDirectory withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"❌ Failed to create output directory: %@", error.localizedDescription);
            return nil;
        }
        
        // Setup AVFoundation for frame extraction
        NSURL *inputURL = [NSURL fileURLWithPath:inputPath];
        AVAsset *asset = [AVAsset assetWithURL:inputURL];
        AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        imageGenerator.appliesPreferredTrackTransform = YES;
        imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
        imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
        
        // Get video properties
        AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        if (!videoTrack) {
            NSLog(@"❌ Error: No video track found");
            return nil;
        }
        
        CMTime duration = asset.duration;
        Float64 durationSeconds = CMTimeGetSeconds(duration);
        float originalFrameRate = [videoTrack nominalFrameRate];
        
        NSLog(@"📊 Video properties: %.2f seconds, original FPS: %.1f", durationSeconds, originalFrameRate);
        
        // Calculate frame extraction parameters
        const float frameInterval = 1.0f / targetFPS;
        const int totalFrames = (int)(durationSeconds * targetFPS);
        
        NSLog(@"🎯 Extracting %d frames at %.1f FPS (1 frame every %.3f seconds)", totalFrames, targetFPS, frameInterval);
        
        // Extract frames
        NSMutableArray *framePaths = [NSMutableArray arrayWithCapacity:totalFrames];
        int successCount = 0;
        
        // Send initial progress for frame extraction
        [self sendProgressUpdate:0.0 status:@"Extracting video frames..."];
        
        for (int frameIndex = 0; frameIndex < totalFrames; frameIndex++) {
            @autoreleasepool {
                // Calculate time for this frame
                CMTime frameTime = CMTimeMakeWithSeconds(frameIndex * frameInterval, 600);
                NSError *extractionError;
                
                CGImageRef cgImage = [imageGenerator copyCGImageAtTime:frameTime actualTime:NULL error:&extractionError];
                if (cgImage) {
                    // Convert to UIImage and save as JPEG
                    UIImage *frameImage = [UIImage imageWithCGImage:cgImage];
                    CGImageRelease(cgImage);
                    
                    NSData *imageData = UIImageJPEGRepresentation(frameImage, 0.9); // 90% quality
                    NSString *framePath = [outputDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"frame_%06d.jpg", frameIndex]];
                    
                    if ([imageData writeToFile:framePath atomically:YES]) {
                        [framePaths addObject:framePath];
                        successCount++;
                        
                        // Send progress updates every 5 frames
                        if (successCount % 5 == 0) {
                            double progress = (double)successCount / totalFrames * 0.3; // Frame extraction is 30% of total
                            int percentage = (int)(progress * 100 * 3.33); // Convert to extraction percentage
                            NSLog(@"📸 Extracted %d/%d frames (%d%%)", successCount, totalFrames, percentage);
                            [self sendProgressUpdate:progress status:[NSString stringWithFormat:@"Extracting frames... %d%%", percentage]];
                        }
                    }
                } else {
                    NSLog(@"⚠️ Failed to extract frame %d: %@", frameIndex, extractionError.localizedDescription);
                }
            }
        }
        
        NSLog(@"✅ Frame extraction completed: %d/%d frames successful", successCount, totalFrames);
        
        // Send completion progress for frame extraction
        [self sendProgressUpdate:0.3 status:@"Frame extraction complete!"];
        
        if (successCount == 0) {
            NSLog(@"❌ No frames were extracted successfully");
            return nil;
        }
        
        // Return extraction results
        return @{
            @"framePaths": framePaths,
            @"frameCount": @(successCount),
            @"duration": @(durationSeconds),
            @"fps": @(originalFrameRate),
            @"targetFPS": @(targetFPS)
        };
        
    } @catch (NSException *exception) {
        NSLog(@"❌ Exception during frame extraction: %@", exception.reason);
        return nil;
    }
}

+ (BOOL)applyFilterToFrames:(NSArray<NSString *> *)framePaths outputPath:(NSString *)outputPath filterType:(NSString *)filterType frameCount:(int)frameCount duration:(double)duration targetFPS:(float)targetFPS {
    @try {
        NSLog(@"🎬 iOS applyFilterToFrames called with %d frames", frameCount);
        NSLog(@"🎯 Filter: %@, Output: %@", filterType, outputPath);
        NSLog(@"⏱️ Duration: %.2fs, Target FPS: %.1f", duration, targetFPS);
        
        // Send initial progress
        NSLog(@"📤 Sending initial progress update...");
        [self sendProgressUpdate:0.0 status:@"Preparing video processing..."];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        // CRITICAL FIX: Check if output video already exists
        if ([fileManager fileExistsAtPath:outputPath]) {
            NSLog(@"✅ Filtered video already exists, using existing file: %@", outputPath);
            return YES; // File already exists, no need to process again
        }
        
        if (framePaths.count == 0) {
            NSLog(@"❌ No frame paths provided");
            return NO;
        }
        
        // Create temporary directory for processed frames
        NSString *tempDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"filtered_frames"];
        NSString *processedFramesDir = [tempDir stringByAppendingPathComponent:@"processed"];
        [fileManager createDirectoryAtPath:tempDir withIntermediateDirectories:YES attributes:nil error:nil];
        [fileManager createDirectoryAtPath:processedFramesDir withIntermediateDirectories:YES attributes:nil error:nil];
        
        // Process each frame with the filter
        NSMutableArray *processedFramePaths = [NSMutableArray arrayWithCapacity:framePaths.count];
        int successCount = 0;
        
        for (int i = 0; i < framePaths.count; i++) {
            @autoreleasepool {
                NSString *inputFramePath = framePaths[i];
                
                // Load frame image
                UIImage *frameImage = [UIImage imageWithContentsOfFile:inputFramePath];
                if (!frameImage) {
                    NSLog(@"⚠️ Failed to load frame %d from: %@", i, inputFramePath);
                    continue;
                }
                
                // Apply filter to frame (fallback to original frame on failure)
                UIImage *filteredImage = [self applyFilterToImage:frameImage filterType:filterType] ?: frameImage;
                
                // Save processed frame (fallback to copying original on failure)
                NSString *outputFramePath = [processedFramesDir stringByAppendingPathComponent:[NSString stringWithFormat:@"filtered_%06d.jpg", i]];
                BOOL saved = NO;
                if (filteredImage) {
                    NSData *imageData = UIImageJPEGRepresentation(filteredImage, 0.9);
                    saved = [imageData writeToFile:outputFramePath atomically:YES];
                }
                if (!saved) {
                    // Fallback: copy original frame file
                    saved = [[NSFileManager defaultManager] copyItemAtPath:inputFramePath toPath:outputFramePath error:nil];
                }
                
                if (saved) {
                    [processedFramePaths addObject:outputFramePath];
                    successCount++;
                    
                    // Send progress updates
                    double progress = (double)successCount / framePaths.count * 0.8; // 80% for frame processing
                    int percentage = (int)(progress * 100);
                    
                    if (successCount % 5 == 0) { // Update every 5 frames
                        NSLog(@"🎨 Processed %d/%d frames (%d%%)", successCount, (int)framePaths.count, percentage);
                        [self sendProgressUpdate:progress status:[NSString stringWithFormat:@"Processing frames... %d%%", percentage]];
                    }
                } else {
                    NSLog(@"⚠️ Failed to save or copy frame %d, using original path", i);
                    [processedFramePaths addObject:inputFramePath];
                }
            }
        }
        
        NSLog(@"✅ Filter application completed: %d/%d frames processed", successCount, (int)framePaths.count);
        
        if (successCount == 0) {
            NSLog(@"❌ No frames were processed successfully");
            return NO;
        }
        
        // Send progress update for video creation
        [self sendProgressUpdate:0.8 status:@"Creating video from processed frames..."];
        
        // Create video from processed frames
        BOOL videoCreated = [self createVideoFromFrames:processedFramePaths outputPath:outputPath duration:duration targetFPS:targetFPS];
        
        // Cleanup temporary files
        [fileManager removeItemAtPath:tempDir error:nil];
        
        if (videoCreated) {
            NSLog(@"✅ Video creation completed successfully: %@", outputPath);
            [self sendProgressUpdate:1.0 status:@"Video processing complete!"];
        } else {
            NSLog(@"❌ Video creation failed");
            [self sendProgressUpdate:0.0 status:@"Video processing failed"];
        }
        
        return videoCreated;
        
    } @catch (NSException *exception) {
        NSLog(@"❌ Exception during filter application: %@", exception.reason);
        return NO;
    }
}

// Helper method to apply filter to a single image
+ (UIImage *)applyFilterToImage:(UIImage *)image filterType:(NSString *)filterType {
    if ([filterType isEqualToString:@"charcoalSketch"]) {
        return [self convertToCharcoalSketch:image];
    } else if ([filterType isEqualToString:@"inkPen"]) {
        return [self convertToInkPen:image];
    } else if ([filterType isEqualToString:@"cartoon"]) {
        return [self convertToCartoon:image];
    } else if ([filterType isEqualToString:@"softPen"]) {
        return [self convertToSoftPen:image];
    } else if ([filterType isEqualToString:@"noirSketch"]) {
        return [self convertToNoirSketch:image];
    } else if ([filterType isEqualToString:@"storyboard"]) {
        return [self convertToStoryboard:image];
    } else if ([filterType isEqualToString:@"chalk"]) {
        return [self convertToChalk:image];
    } else if ([filterType isEqualToString:@"feltPen"]) {
        return [self convertToFeltPen:image];
    } else if ([filterType isEqualToString:@"monochromeSketch"]) {
        return [self convertToMonochromeSketch:image];
    } else if ([filterType isEqualToString:@"splashSketch"]) {
        return [self convertToSplashSketch:image];
    } else if ([filterType isEqualToString:@"coloringBook"]) {
        return [self convertToColoringBook:image];
    } else if ([filterType isEqualToString:@"paperSketch"]) {
        return [self convertToPaperSketch:image];
    } else if ([filterType isEqualToString:@"neonSketch"]) {
        return [self convertToNeonSketch:image];
    } else {
        NSLog(@"⚠️ Unknown filter type: %@, returning original image", filterType);
        return image;
    }
}

// Helper method to create video from processed frames
+ (BOOL)createVideoFromFrames:(NSArray<NSString *> *)framePaths outputPath:(NSString *)outputPath duration:(double)duration targetFPS:(float)targetFPS {
    @try {
        NSLog(@"🎬 Creating video from %d frames at %.1f FPS", (int)framePaths.count, targetFPS);
        
        if (framePaths.count == 0) {
            NSLog(@"❌ No frames to create video from");
            return NO;
        }
        
        // Get frame size from first frame
        UIImage *firstFrame = [UIImage imageWithContentsOfFile:framePaths[0]];
        if (!firstFrame) {
            NSLog(@"❌ Failed to load first frame");
            return NO;
        }
        
        CGSize frameSize = firstFrame.size;
        NSLog(@"📐 Frame size: %.0fx%.0f", frameSize.width, frameSize.height);
        
        // Setup video writer
        NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
        AVAssetWriter *assetWriter = [[AVAssetWriter alloc] initWithURL:outputURL fileType:AVFileTypeMPEG4 error:nil];
        
        NSDictionary *videoSettings = @{
            AVVideoCodecKey: AVVideoCodecTypeH264,
            AVVideoWidthKey: @((int)frameSize.width),
            AVVideoHeightKey: @((int)frameSize.height),
            AVVideoCompressionPropertiesKey: @{
                AVVideoAverageBitRateKey: @(1500000),
                AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel,
                AVVideoMaxKeyFrameIntervalKey: @(targetFPS * 2)
            }
        };
        
        AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
        AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
        
        [assetWriter addInput:writerInput];
        [assetWriter startWriting];
        [assetWriter startSessionAtSourceTime:kCMTimeZero];
        
        // Write frames
        dispatch_semaphore_t writingSemaphore = dispatch_semaphore_create(0);
        __block BOOL writeSuccess = YES;
        __block int frameIndex = 0; // Maintain state across block executions
        const float frameInterval = 1.0f / targetFPS;

        dispatch_queue_t writingQueue = dispatch_queue_create("VideoWritingQueue", DISPATCH_QUEUE_SERIAL);

        [writerInput requestMediaDataWhenReadyOnQueue:writingQueue usingBlock:^{
            while ([writerInput isReadyForMoreMediaData] && frameIndex < framePaths.count && writeSuccess) {
                @autoreleasepool {
                    NSString *framePath = framePaths[frameIndex];
                    UIImage *frameImage = [UIImage imageWithContentsOfFile:framePath];
                    
                    if (frameImage) {
                        CVPixelBufferRef pixelBuffer = [self pixelBufferFromImage:frameImage size:frameSize];
                        if (pixelBuffer) {
                            CMTime presentationTime = CMTimeMakeWithSeconds(frameIndex * frameInterval, 600);
                            if (![adaptor appendPixelBuffer:pixelBuffer withPresentationTime:presentationTime]) {
                                NSLog(@"❌ Error appending frame %d", frameIndex);
                                writeSuccess = NO;
                            }
                            CVPixelBufferRelease(pixelBuffer);
                        }
                    }
                    frameIndex++;
                }
            }
            
            // If all frames appended, finish writing
            if (frameIndex >= framePaths.count) {
                [writerInput markAsFinished];
                [assetWriter finishWritingWithCompletionHandler:^{
                    writeSuccess = writeSuccess && (assetWriter.status == AVAssetWriterStatusCompleted);
                    if (!writeSuccess) {
                        NSLog(@"❌ Asset writer error: %@", assetWriter.error);
                    }
                    dispatch_semaphore_signal(writingSemaphore);
                }];
            }
        }];

        // Wait for video writing with timeout to prevent infinite loading
        dispatch_time_t writeTimeout = dispatch_time(DISPATCH_TIME_NOW, 120 * NSEC_PER_SEC); // 2 minute timeout
        long writeResult = dispatch_semaphore_wait(writingSemaphore, writeTimeout);
        
        if (writeResult != 0) {
            NSLog(@"❌ Video writing timed out after 2 minutes");
            writeSuccess = NO;
        }
        
        return writeSuccess;
        
    } @catch (NSException *exception) {
        NSLog(@"❌ Exception during video creation: %@", exception.reason);
        return NO;
    }
}

// Audio merging implementation
+ (BOOL)mergeAudioWithVideoPath:(NSString *)videoPath audioSourcePath:(NSString *)audioSourcePath outputPath:(NSString *)outputPath {
    @try {
        NSLog(@"🎵 iOS merging audio from %@ with video %@", audioSourcePath, videoPath);
        
        NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
        NSURL *audioSourceURL = [NSURL fileURLWithPath:audioSourcePath];
        NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
        
        // Check if input files exist
        if (![[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
            NSLog(@"❌ Video file not found: %@", videoPath);
            return NO;
        }
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:audioSourcePath]) {
            NSLog(@"❌ Audio source file not found: %@", audioSourcePath);
            return NO;
        }
        
        // Create output directory if needed
        NSString *outputDir = [outputPath stringByDeletingLastPathComponent];
        [[NSFileManager defaultManager] createDirectoryAtPath:outputDir withIntermediateDirectories:YES attributes:nil error:nil];
        
        // Create assets
        AVAsset *videoAsset = [AVAsset assetWithURL:videoURL];
        AVAsset *audioAsset = [AVAsset assetWithURL:audioSourceURL];
        
        // Get tracks
        AVAssetTrack *videoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        AVAssetTrack *audioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        
        if (!videoTrack) {
            NSLog(@"❌ No video track found in video file");
            return NO;
        }
        
        if (!audioTrack) {
            NSLog(@"⚠️ No audio track found in source file, copying video only");
            // Just copy the video file if no audio track
            return [[NSFileManager defaultManager] copyItemAtPath:videoPath toPath:outputPath error:nil];
        }
        
        // Create composition
        AVMutableComposition *composition = [AVMutableComposition composition];
        
        // Add video track
        AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:videoTrack atTime:kCMTimeZero error:nil];
        
        // Add audio track
        AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        CMTime audioDuration = CMTimeMinimum(audioAsset.duration, videoAsset.duration);
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioDuration) ofTrack:audioTrack atTime:kCMTimeZero error:nil];
        
        // Remove output file if it exists
        [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
        
        // Export composition
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
        exportSession.outputURL = outputURL;
        exportSession.outputFileType = AVFileTypeMPEG4;
        exportSession.shouldOptimizeForNetworkUse = YES;
        
        dispatch_semaphore_t exportSemaphore = dispatch_semaphore_create(0);
        __block BOOL exportSuccess = NO;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            exportSuccess = (exportSession.status == AVAssetExportSessionStatusCompleted);
            if (!exportSuccess) {
                NSLog(@"❌ Audio merging export failed: %@", exportSession.error);
            } else {
                NSLog(@"✅ Audio merging completed successfully");
            }
            dispatch_semaphore_signal(exportSemaphore);
        }];
        
        // Wait for export with timeout
        dispatch_time_t exportTimeout = dispatch_time(DISPATCH_TIME_NOW, 60 * NSEC_PER_SEC); // 1 minute timeout
        long exportResult = dispatch_semaphore_wait(exportSemaphore, exportTimeout);
        
        if (exportResult != 0) {
            NSLog(@"❌ Audio merging timed out after 1 minute");
            exportSuccess = NO;
        }
        
        return exportSuccess;
        
    } @catch (NSException *exception) {
        NSLog(@"❌ Exception during audio merging: %@", exception.reason);
        // Fallback: copy video file without audio merging
        return [[NSFileManager defaultManager] copyItemAtPath:videoPath toPath:outputPath error:nil];
    }
}

@end
