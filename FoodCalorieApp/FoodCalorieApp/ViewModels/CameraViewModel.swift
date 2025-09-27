import SwiftUI
import UIKit
import AIEngine

@MainActor
class CameraViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var showCamera = false
    @Published var isAnalyzing = false
    @Published var analysisResult: AnalysisResult?
    @Published var errorMessage: String?
    @Published var showErrorAlert = false
    
    private let aiEngine = FoodAIEngine()
    
    func analyzeImage() {
        guard let image = capturedImage else {
            showError("Nicio imagine selectată pentru analiză.")
            return
        }
        
        isAnalyzing = true
        analysisResult = nil
        clearError()
        
        Task {
            do {
                let result = try await aiEngine.analyzeFood(image: image)
                await MainActor.run {
                    self.analysisResult = result
                    self.isAnalyzing = false
                }
            } catch let error as AIEngineError {
                await MainActor.run {
                    self.showError(error.localizedDescription, recoverySuggestion: error.recoverySuggestion)
                    self.isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    self.showError("Eroare neașteptată: \(error.localizedDescription)")
                    self.isAnalyzing = false
                }
            }
        }
    }
    
    func handleCameraError(_ error: AIEngineError) {
        showError(error.localizedDescription, recoverySuggestion: error.recoverySuggestion)
    }
    
    func clearError() {
        errorMessage = nil
        showErrorAlert = false
    }
    
    private func showError(_ message: String, recoverySuggestion: String? = nil) {
        var fullMessage = message
        if let suggestion = recoverySuggestion {
            fullMessage += "\n\n\(suggestion)"
        }
        errorMessage = fullMessage
        showErrorAlert = true
    }
}