🖋️ Flutter OpenCV Pencil Sketch App

A powerful Flutter app that transforms photos and videos into realistic pencil sketches using OpenCV.
Built with native integrations through Platform Channels, combining the speed of C, Kotlin, and Swift for high-performance image and video processing.

✨ Features

🎨 Pencil Sketch Filters

Multiple predefined OpenCV algorithms for realistic pencil sketch effects

Adjustable intensity and blending modes

Support for grayscale and color pencil styles

🧠 Native OpenCV Integration

High-performance implementations via Platform Channels

Uses C (OpenCV C++ bindings) for image processing

Kotlin (Android) and Swift (iOS) handle platform communication and threading

🖼️ Photo Mode

Apply real-time or static filters to images from gallery or camera

🎥 Video Mode (iOS)

Extracts frames asynchronously

Applies pencil sketch filters to each frame using native threads

Reconstructs processed frames back into a video with sound sync

Smooth UI updates while processing

⚙️ Customizable Parameters

Pencil density, edge thickness, shading, contrast, and tone

Filter presets (Soft, Realistic, Charcoal, Comic, etc.)

🛠️ Tech Stack
Layer	Technology
Frontend	Flutter (Dart)
Native Bridge	Platform Channels
Android	Kotlin + OpenCV
iOS	Swift + OpenCV (Objective-C bridge)
Core Image Processing	C / C++ (OpenCV filters)