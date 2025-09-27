import UIKit
import Vision
import CoreML
import os.log

class FoodImageProcessor {
    private var foodClassificationRequest: VNCoreMLRequest?
    private var objectDetectionRequest: VNDetectRectanglesRequest?
    private let logger = Logger(subsystem: "FoodCalorieApp", category: "FoodImageProcessor")
    
    // Food categories that we can detect with confidence
    private let supportedFoodCategories = [
        "apple", "banana", "orange", "pizza", "hamburger", "hot dog", 
        "sandwich", "bread", "cake", "cookie", "broccoli", "carrot",
        "french fries", "donut", "ice cream", "chocolate", "salad",
        "soup", "pasta", "rice", "chicken", "fish", "meat", "cheese"
    ]
    
    init() {
        setupVisionRequests()
    }
    
    func detectFood(in image: UIImage) async throws -> [DetectedFood] {
        guard let cgImage = image.cgImage else {
            logger.error("Invalid image provided")
            throw AIEngineError.invalidImage
        }
        
        logger.info("Starting food detection for image")
        
        // Use Vision's built-in image classification
        let detectedFoods = try await performVisionFoodDetection(cgImage: cgImage)
        
        if detectedFoods.isEmpty {
            logger.warning("No food detected in image")
            throw AIEngineError.noFoodDetected
        }
        
        let validFoods = detectedFoods.filter { $0.confidence > 0.3 }
        if validFoods.isEmpty {
            let maxConfidence = detectedFoods.map(\.confidence).max() ?? 0.0
            logger.warning("All detected foods have low confidence: \(maxConfidence)")
            throw AIEngineError.insufficientConfidence(maxConfidence)
        }
        
        logger.info("Successfully detected \(validFoods.count) foods")
        return validFoods
    }
    
    private func setupVisionRequests() {
        // Setup image classification request using Vision's built-in capabilities
        do {
            // We'll use VNClassifyImageRequest which uses on-device ML models
            let classificationRequest = VNClassifyImageRequest { [weak self] request, error in
                self?.handleClassificationResults(request: request, error: error)
            }
            
            // Set minimum confidence threshold
            classificationRequest.maximumLeafObservations = 10
            classificationRequest.maximumHierarchicalObservations = 10
            
            // Setup object detection for better food localization
            objectDetectionRequest = VNDetectRectanglesRequest { [weak self] request, error in
                self?.handleObjectDetectionResults(request: request, error: error)
            }
            
            logger.info("Vision requests setup completed")
        } catch {
            logger.error("Failed to setup Vision requests: \(error.localizedDescription)")
        }
    }
    
    private func handleClassificationResults(request: VNRequest, error: Error?) {
        if let error = error {
            logger.error("Classification failed: \(error.localizedDescription)")
            return
        }
        // Results will be handled in the async method
    }
    
    private func handleObjectDetectionResults(request: VNRequest, error: Error?) {
        if let error = error {
            logger.error("Object detection failed: \(error.localizedDescription)")
            return
        }
        // Results will be handled in the async method
    }
    
    private func performVisionFoodDetection(cgImage: CGImage) async throws -> [DetectedFood] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    self.logger.error("Vision classification failed: \(error.localizedDescription)")
                    continuation.resume(throwing: AIEngineError.visionRequestFailed(error.localizedDescription))
                    return
                }
                
                guard let observations = request.results as? [VNClassificationObservation] else {
                    self.logger.error("No classification observations found")
                    continuation.resume(throwing: AIEngineError.processingFailed("No classification results"))
                    return
                }
                
                let detectedFoods = self.processClassificationResults(observations, imageSize: CGSize(width: cgImage.width, height: cgImage.height))
                continuation.resume(returning: detectedFoods)
            }
            
            // Set confidence threshold
            request.maximumLeafObservations = 10
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                self.logger.error("Failed to perform Vision request: \(error.localizedDescription)")
                continuation.resume(throwing: AIEngineError.visionRequestFailed(error.localizedDescription))
            }
        }
    }
    
    private func processClassificationResults(_ observations: [VNClassificationObservation], imageSize: CGSize) -> [DetectedFood] {
        let foodObservations = observations.filter { observation in
            // Check if the classification result is likely food-related
            let identifier = observation.identifier.lowercased()
            return supportedFoodCategories.contains(where: { identifier.contains($0) }) ||
                   isFoodRelatedTerm(identifier)
        }
        
        logger.info("Found \(foodObservations.count) food-related observations")
        
        return foodObservations.compactMap { observation in
            let foodName = mapToRomanianFoodName(observation.identifier)
            let estimatedVolume = estimateVolumeFromClassification(observation, imageSize: imageSize)
            
            return DetectedFood(
                name: foodName,
                confidence: Double(observation.confidence),
                boundingBox: estimateBoundingBox(for: observation, imageSize: imageSize),
                estimatedVolume: estimatedVolume
            )
        }
    }
    
    private func isFoodRelatedTerm(_ identifier: String) -> Bool {
        let foodKeywords = ["food", "meal", "dish", "cuisine", "fruit", "vegetable", 
                           "meat", "dairy", "grain", "beverage", "drink", "dessert"]
        return foodKeywords.contains(where: { identifier.contains($0) })
    }
    
    private func mapToRomanianFoodName(_ identifier: String) -> String {
        let mappings: [String: String] = [
            "pizza": "Pizza",
            "apple": "Măr",
            "banana": "Banană",
            "orange": "Portocală",
            "bread": "Pâine",
            "pasta": "Paste",
            "rice": "Orez",
            "chicken": "Pui",
            "fish": "Pește",
            "meat": "Carne",
            "salad": "Salată",
            "soup": "Supă",
            "cake": "Prăjitură",
            "cookie": "Biscuit",
            "chocolate": "Ciocolată",
            "cheese": "Brânză",
            "hamburger": "Hamburger",
            "sandwich": "Sandwich",
            "french fries": "Cartofi prăjiți",
            "hot dog": "Hot dog",
            "donut": "Gogoașă",
            "ice cream": "Înghețată"
        ]
        
        let lowerIdentifier = identifier.lowercased()
        for (key, value) in mappings {
            if lowerIdentifier.contains(key) {
                return value
            }
        }
        
        // Return capitalized version if no mapping found
        return identifier.capitalized
    }
    
    private func estimateVolumeFromClassification(_ observation: VNClassificationObservation, imageSize: CGSize) -> Double {
        // Volume estimation based on confidence and typical food sizes
        // Higher confidence suggests the food takes up more of the image
        let confidence = Double(observation.confidence)
        let baseVolume: Double
        
        // Estimate base volume based on food type
        let foodType = observation.identifier.lowercased()
        switch true {
        case foodType.contains("pizza"):
            baseVolume = 400.0 // Large flat food
        case foodType.contains("apple") || foodType.contains("orange"):
            baseVolume = 200.0 // Medium fruit
        case foodType.contains("banana"):
            baseVolume = 150.0 // Elongated fruit
        case foodType.contains("bread") || foodType.contains("sandwich"):
            baseVolume = 300.0 // Bread products
        case foodType.contains("pasta") || foodType.contains("rice"):
            baseVolume = 250.0 // Grain dishes
        case foodType.contains("meat") || foodType.contains("chicken") || foodType.contains("fish"):
            baseVolume = 180.0 // Protein portions
        case foodType.contains("salad"):
            baseVolume = 350.0 // Leafy volume
        case foodType.contains("soup"):
            baseVolume = 300.0 // Liquid volume
        case foodType.contains("cake") || foodType.contains("dessert"):
            baseVolume = 200.0 // Dessert portions
        default:
            baseVolume = 200.0 // Default medium size
        }
        
        // Adjust based on confidence (assuming higher confidence = more prominent in image)
        let confidenceMultiplier = 0.5 + (confidence * 1.5) // Range: 0.5 to 2.0
        let estimatedVolume = baseVolume * confidenceMultiplier
        
        logger.debug("Estimated volume for \(foodType): \(estimatedVolume) cm³ (confidence: \(confidence))")
        return estimatedVolume
    }
    
    private func estimateBoundingBox(for observation: VNClassificationObservation, imageSize: CGSize) -> CGRect {
        // Since VNClassifyImageRequest doesn't provide bounding boxes,
        // we estimate based on confidence and typical food positioning
        let confidence = Double(observation.confidence)
        
        // Foods with higher confidence are likely more centered and larger
        let centerBias = confidence * 0.3 // Higher confidence = more centered
        let sizeBias = confidence * 0.4 // Higher confidence = larger in image
        
        // Estimate center position (slightly randomized but confidence-biased)
        let centerX = 0.3 + (centerBias * 0.4) + Double.random(in: -0.1...0.1)
        let centerY = 0.3 + (centerBias * 0.4) + Double.random(in: -0.1...0.1)
        
        // Estimate size based on confidence
        let width = 0.2 + sizeBias + Double.random(in: -0.05...0.05)
        let height = 0.2 + sizeBias + Double.random(in: -0.05...0.05)
        
        // Ensure bounds are within image
        let x = max(0, min(1 - width, centerX - width/2))
        let y = max(0, min(1 - height, centerY - height/2))
        let finalWidth = min(width, 1 - x)
        let finalHeight = min(height, 1 - y)
        
        return CGRect(x: x, y: y, width: finalWidth, height: finalHeight)
    }
}

public enum AIEngineError: LocalizedError, Equatable {
    case invalidImage
    case modelNotLoaded(String)
    case processingFailed(String)
    case visionRequestFailed(String)
    case noFoodDetected
    case insufficientConfidence(Double)
    case cameraNotAvailable
    case cameraPermissionDenied
    case nutritionDataNotFound(String)
    case volumeEstimationFailed
    case networkError(String)
    case unknownError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Imaginea furnizată nu este validă sau nu poate fi procesată."
        case .modelNotLoaded(let model):
            return "Modelul AI '\(model)' nu a putut fi încărcat."
        case .processingFailed(let reason):
            return "Procesarea imaginii a eșuat: \(reason)"
        case .visionRequestFailed(let reason):
            return "Analiza vizuală a eșuat: \(reason)"
        case .noFoodDetected:
            return "Nu au fost detectate alimente în imagine. Încercați o imagine mai clară."
        case .insufficientConfidence(let confidence):
            return "Încrederea în detectare este prea mică (\(String(format: "%.1f", confidence * 100))%). Încercați o imagine mai clară."
        case .cameraNotAvailable:
            return "Camera nu este disponibilă pe acest dispozitiv."
        case .cameraPermissionDenied:
            return "Accesul la cameră a fost refuzat. Vă rugăm să permiteți accesul în Setări."
        case .nutritionDataNotFound(let food):
            return "Datele nutriționale pentru '\(food)' nu au fost găsite."
        case .volumeEstimationFailed:
            return "Estimarea volumului alimentului a eșuat."
        case .networkError(let reason):
            return "Eroare de rețea: \(reason)"
        case .unknownError(let reason):
            return "Eroare necunoscută: \(reason)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidImage, .noFoodDetected, .insufficientConfidence:
            return "Încercați să fotografiați din nou cu mai multă lumină și o imagine mai clară a alimentelor."
        case .modelNotLoaded:
            return "Reporniți aplicația sau reinstalați-o."
        case .cameraNotAvailable:
            return "Verificați dacă dispozitivul are cameră funcțională."
        case .cameraPermissionDenied:
            return "Mergeți la Setări > Confidențialitate > Cameră și permiteți accesul pentru această aplicație."
        case .networkError:
            return "Verificați conexiunea la internet și încercați din nou."
        default:
            return "Încercați din nou sau contactați suportul dacă problema persistă."
        }
    }
}
