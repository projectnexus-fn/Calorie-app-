# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

FoodCalorieApp is an iOS application that allows users to photograph food and estimates calories using a custom AI engine. The app is written in Swift, uses SwiftUI for the UI, and implements a modular architecture with separate AI processing capabilities.

**Language**: Swift 5.9+  
**Platform**: iOS 16+  
**Architecture**: Swift Package Manager with modular library targets

## Key Commands

### Building and Running
```bash
# Open in Xcode (main development environment)
open Package.swift

# Build all targets
swift build

# Run tests for all targets  
swift test

# Run tests for specific target
swift test --filter FoodCalorieAppTests
swift test --filter AIEngineTests
```

### Development Workflow
```bash
# Clean build artifacts
swift package clean

# Update dependencies
swift package update

# Generate Xcode project (if needed)
swift package generate-xcodeproj
```

## Architecture Overview

### Core Module Structure

The project is split into two main Swift Package targets:

1. **FoodCalorieApp** - The main iOS app target containing UI and view logic
2. **AIEngine** - A separate library containing all AI processing, image analysis, and calorie calculation logic

### Key Components

**AIEngine Module** (`AIEngine/`):
- `FoodAIEngine.swift` - Main orchestrator that coordinates image processing and calorie calculation
- `FoodImageProcessor.swift` - Handles computer vision and food detection using Vision/CoreML frameworks
- `CalorieCalculator.swift` - Calculates calories based on detected food volumes and nutritional database
- `FoodModels.swift` - Data models for food detection results, nutritional information, and analysis outputs
- `NutritionDatabase` - Romanian food database with calorie density and nutritional data

**FoodCalorieApp Module** (`FoodCalorieApp/`):
- `ContentView.swift` - Main UI displaying camera capture and analysis results
- `CameraView.swift` - UIImagePickerController wrapper for photo capture
- `CameraViewModel.swift` - MVVM view model managing app state and AI engine interaction

### Data Flow

1. User captures photo via `CameraView` → `CameraViewModel`
2. Image sent to `FoodAIEngine.analyzeFood()`
3. `FoodImageProcessor` detects food items and estimates volumes
4. `CalorieCalculator` looks up nutritional data and calculates calories
5. Results returned to UI via `AnalysisResult` model

### AI Processing Pipeline

The AI engine uses Apple's Vision framework for real food detection:
- **Food Detection**: VNClassifyImageRequest with 20+ supported food categories
- **Confidence Filtering**: Only foods with >30% confidence are processed
- **Volume Estimation**: Confidence-based algorithms using typical food sizes
- **Calorie Calculation**: density × volume × calories/gram with validation
- **Romanian Translation**: English food names mapped to Romanian equivalents
- **Fallback System**: Unknown foods estimated using average calorie density

## Dependencies

External packages managed via Swift Package Manager:
- `swift-collections` - Advanced collection types for AIEngine
- `swift-algorithms` - Algorithm utilities for AIEngine

System frameworks used:
- `SwiftUI` - UI framework
- `UIKit` - Image handling and camera integration
- `Vision` - Computer vision processing (placeholder)
- `CoreML` - Machine learning model integration (placeholder)
- `AVFoundation` - Camera functionality

## Development Notes

### UI Language
The app UI is in Romanian (`"Fotografiaza Mancarea"`, `"Calculeaza Caloriile"`, etc.) as this targets Romanian users.

### Current Implementation Status
- Camera capture: ✅ Functional with permissions handling
- Real AI processing: ✅ Using Vision framework for food detection
- Volume estimation: ✅ Confidence-based volume calculation algorithms
- Nutritional database: ✅ Romanian food database with fuzzy matching
- Error handling: ✅ Comprehensive error system with localized messages
- Logging: ✅ Structured logging for debugging

### Testing Structure
The project defines test targets in Package.swift but test files are not yet implemented:
- `FoodCalorieAppTests` - For UI and view model testing
- `AIEngineTests` - For AI processing logic testing

### Error Handling System

**AIEngineError Types:**
- Camera permissions and availability errors
- Image processing and validation errors  
- ML model confidence and detection errors
- Nutrition data lookup failures
- Volume estimation validation errors
- Localized error messages in Romanian with recovery suggestions

**Logging System:**
- Structured logging using `os.log` with separate subsystems
- Debug, info, warning, and error levels
- Performance and confidence tracking for AI processing

### Key Development Considerations

When working with this codebase:
- **Architecture**: Maintain separation between UI logic (FoodCalorieApp) and AI processing (AIEngine)
- **Real-time Processing**: Vision framework provides on-device food classification
- **Error Resilience**: All operations include comprehensive error handling and user feedback
- **Performance**: Volume estimation uses confidence-based algorithms for efficiency
- **Localization**: All user-facing text is in Romanian with proper diacritics
- **Future Enhancements**: Consider adding meal logging, historical tracking, and custom ML model training
