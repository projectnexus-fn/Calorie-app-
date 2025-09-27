import UIKit
import Vision
import CoreML

public class FoodAIEngine {
    private let imageProcessor: FoodImageProcessor
    private let calorieCalculator: CalorieCalculator
    
    public init() {
        self.imageProcessor = FoodImageProcessor()
        self.calorieCalculator = CalorieCalculator()
    }
    
    public func analyzeFood(image: UIImage) async throws -> AnalysisResult {
        // Step 1: Process image and detect food items
        let detectedFoods = try await imageProcessor.detectFood(in: image)
        
        // Step 2: Estimate portions and calculate calories
        let estimatedCalories = try await calorieCalculator.calculateCalories(
            for: detectedFoods,
            image: image
        )
        
        return AnalysisResult(
            detectedFoods: detectedFoods.map(\.name),
            estimatedCalories: estimatedCalories,
            confidence: calculateOverallConfidence(foods: detectedFoods)
        )
    }
    
    private func calculateOverallConfidence(foods: [DetectedFood]) -> Double {
        guard !foods.isEmpty else { return 0.0 }
        let totalConfidence = foods.reduce(0.0) { $0 + $1.confidence }
        return totalConfidence / Double(foods.count)
    }
}