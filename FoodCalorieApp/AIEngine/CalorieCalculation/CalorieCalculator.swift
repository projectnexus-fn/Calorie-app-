import UIKit
import Foundation
import os.log

class CalorieCalculator {
    private let nutritionDatabase: NutritionDatabase
    private let logger = Logger(subsystem: "FoodCalorieApp", category: "CalorieCalculator")
    
    init() {
        self.nutritionDatabase = NutritionDatabase()
    }
    
    func calculateCalories(for detectedFoods: [DetectedFood], image: UIImage) async throws -> Int {
        guard !detectedFoods.isEmpty else {
            logger.warning("No detected foods provided to calorie calculator")
            throw AIEngineError.noFoodDetected
        }
        
        var totalCalories = 0
        
        for food in detectedFoods {
            // Validate estimated volume
            guard food.estimatedVolume > 0 else {
                logger.error("Invalid estimated volume for food: \(food.name)")
                throw AIEngineError.volumeEstimationFailed
            }
            
            let foodKey = food.name.lowercased()
            if let nutritionData = nutritionDatabase.getNutritionData(for: foodKey) {
                // Calculate mass from estimated volume and density
                let estimatedMass = max(0, food.estimatedVolume * nutritionData.density) // grams
                
                // Calculate calories from mass
                let caloriesDouble = estimatedMass * nutritionData.caloriesPerGram
                let calories = max(0, Int(caloriesDouble.rounded()))
                
                logger.debug("Food: \(food.name), mass: \(estimatedMass) g, calories: \(calories)")
                totalCalories += calories
            } else {
                logger.warning("Nutrition data not found for food: \(food.name)")
                // Use default estimation if food not found in database
                totalCalories += estimateCaloriesForUnknownFood(food)
            }
        }
        
        return max(0, totalCalories)
    }
    
    private func estimateCaloriesForUnknownFood(_ food: DetectedFood) -> Int {
        // Fallback estimation based on average food calorie density
        guard food.estimatedVolume > 0 else {
            logger.warning("Cannot estimate calories for \(food.name): invalid volume")
            return 50 // Minimal fallback calories
        }
        
        // Use confidence to adjust estimation accuracy
        let baseCaloriesPerCm3 = 1.5 // rough average estimate
        let confidenceMultiplier = max(0.5, min(2.0, food.confidence)) // Clamp between 0.5 and 2.0
        let adjustedCaloriesPerCm3 = baseCaloriesPerCm3 * confidenceMultiplier
        
        let estimatedCalories = Int((food.estimatedVolume * adjustedCaloriesPerCm3).rounded())
        
        logger.debug("Unknown food \(food.name): estimated \(estimatedCalories) calories (confidence: \(food.confidence))")
        return max(10, min(1000, estimatedCalories)) // Reasonable bounds
    }
}

class NutritionDatabase {
    private var foodDatabase: [String: FoodNutritionData] = [:]
    private let logger = Logger(subsystem: "FoodCalorieApp", category: "NutritionDatabase")
    
    init() {
        setupDatabase()
        logger.info("NutritionDatabase initialized with \(foodDatabase.count) foods")
    }
    
    func getNutritionData(for foodName: String) -> FoodNutritionData? {
        let normalizedName = foodName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try exact match first
        if let data = foodDatabase[normalizedName] {
            return data
        }
        
        // Try partial matching for similar foods
        for (key, data) in foodDatabase {
            if key.contains(normalizedName) || normalizedName.contains(key) {
                logger.debug("Found partial match: \(key) for \(normalizedName)")
                return data
            }
        }
        
        logger.warning("No nutrition data found for: \(foodName)")
        return nil
    }
    
    private func setupDatabase() {
        // Romanian food database with nutritional information
        foodDatabase = [
            "pizza": FoodNutritionData(
                name: "Pizza",
                caloriesPerGram: 2.66,
                density: 0.6,
                nutritionalInfo: NutritionalInfo(protein: 11, carbohydrates: 33, fat: 10, fiber: 2)
            ),
            "salata": FoodNutritionData(
                name: "Salata",
                caloriesPerGram: 0.2,
                density: 0.9,
                nutritionalInfo: NutritionalInfo(protein: 1, carbohydrates: 4, fat: 0, fiber: 2)
            ),
            "paste": FoodNutritionData(
                name: "Paste",
                caloriesPerGram: 1.31,
                density: 0.7,
                nutritionalInfo: NutritionalInfo(protein: 5, carbohydrates: 25, fat: 1, fiber: 2)
            ),
            "paine": FoodNutritionData(
                name: "Paine",
                caloriesPerGram: 2.65,
                density: 0.3,
                nutritionalInfo: NutritionalInfo(protein: 9, carbohydrates: 49, fat: 3, fiber: 4)
            ),
            "fructe": FoodNutritionData(
                name: "Fructe",
                caloriesPerGram: 0.6,
                density: 0.8,
                nutritionalInfo: NutritionalInfo(protein: 1, carbohydrates: 15, fat: 0, fiber: 2)
            ),
            "legume": FoodNutritionData(
                name: "Legume",
                caloriesPerGram: 0.3,
                density: 0.9,
                nutritionalInfo: NutritionalInfo(protein: 2, carbohydrates: 6, fat: 0, fiber: 3)
            ),
            "carne": FoodNutritionData(
                name: "Carne",
                caloriesPerGram: 2.5,
                density: 1.0,
                nutritionalInfo: NutritionalInfo(protein: 26, carbohydrates: 0, fat: 17, fiber: 0)
            ),
            "peste": FoodNutritionData(
                name: "Peste",
                caloriesPerGram: 2.0,
                density: 1.0,
                nutritionalInfo: NutritionalInfo(protein: 22, carbohydrates: 0, fat: 12, fiber: 0)
            ),
            "orez": FoodNutritionData(
                name: "Orez",
                caloriesPerGram: 1.3,
                density: 0.8,
                nutritionalInfo: NutritionalInfo(protein: 3, carbohydrates: 28, fat: 0, fiber: 0)
            ),
            "cartofi": FoodNutritionData(
                name: "Cartofi",
                caloriesPerGram: 0.77,
                density: 0.8,
                nutritionalInfo: NutritionalInfo(protein: 2, carbohydrates: 17, fat: 0, fiber: 2)
            ),
            "supa": FoodNutritionData(
                name: "Supa",
                caloriesPerGram: 0.4,
                density: 1.0,
                nutritionalInfo: NutritionalInfo(protein: 3, carbohydrates: 8, fat: 1, fiber: 1)
            ),
            "desert": FoodNutritionData(
                name: "Desert",
                caloriesPerGram: 3.5,
                density: 0.5,
                nutritionalInfo: NutritionalInfo(protein: 4, carbohydrates: 45, fat: 15, fiber: 1)
            )
        ]
    }
}