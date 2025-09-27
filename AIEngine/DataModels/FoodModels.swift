import Foundation
import UIKit

public struct AnalysisResult {
    public let detectedFoods: [String]
    public let estimatedCalories: Int
    public let confidence: Double
    
    public init(detectedFoods: [String], estimatedCalories: Int, confidence: Double) {
        self.detectedFoods = detectedFoods
        self.estimatedCalories = estimatedCalories
        self.confidence = confidence
    }
}

public struct DetectedFood {
    public let name: String
    public let confidence: Double
    public let boundingBox: CGRect
    public let estimatedVolume: Double // in cm³
    
    public init(name: String, confidence: Double, boundingBox: CGRect, estimatedVolume: Double) {
        self.name = name
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.estimatedVolume = estimatedVolume
    }
}

public struct FoodNutritionData {
    public let name: String
    public let caloriesPerGram: Double
    public let density: Double // grams per cm³
    public let nutritionalInfo: NutritionalInfo
    
    public init(name: String, caloriesPerGram: Double, density: Double, nutritionalInfo: NutritionalInfo) {
        self.name = name
        self.caloriesPerGram = caloriesPerGram
        self.density = density
        self.nutritionalInfo = nutritionalInfo
    }
}

public struct NutritionalInfo {
    public let protein: Double // grams per 100g
    public let carbohydrates: Double
    public let fat: Double
    public let fiber: Double
    
    public init(protein: Double, carbohydrates: Double, fat: Double, fiber: Double) {
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.fiber = fiber
    }
}