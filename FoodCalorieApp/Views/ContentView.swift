import SwiftUI

struct ContentView: View {
    @StateObject private var cameraViewModel = CameraViewModel()
    @State private var cameraError: AIEngineError?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Food Calorie Estimator")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                if let capturedImage = cameraViewModel.capturedImage {
                    Image(uiImage: capturedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 300)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                        .overlay(
                            VStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                Text("Nicio imagine capturata")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                }
                
                VStack(spacing: 16) {
                    Button(action: {
                        cameraViewModel.showCamera.toggle()
                    }) {
                        HStack {
                            Image(systemName: "camera")
                            Text("Fotografiaza Mancarea")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    if cameraViewModel.capturedImage != nil {
                        Button(action: {
                            cameraViewModel.analyzeImage()
                        }) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                Text("Calculeaza Caloriile")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(cameraViewModel.isAnalyzing)
                    }
                }
                .padding(.horizontal)
                
                if cameraViewModel.isAnalyzing {
                    ProgressView("Se analizeaza imaginea...")
                        .padding()
                }
                
                if let result = cameraViewModel.analysisResult {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Rezultate Analiză:")
                                .font(.headline)
                            Spacer()
                            Text("Încredere: \(String(format: "%.1f", result.confidence * 100))%")
                                .font(.caption)
                                .foregroundColor(result.confidence > 0.7 ? .green : result.confidence > 0.5 ? .orange : .red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Alimente detectate:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(result.detectedFoods.joined(separator: ", "))
                                .font(.body)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Calorii estimate:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(result.estimatedCalories) kcal")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        
                        if result.confidence < 0.5 {
                            Text("⚠️ Încrederea este scăzută. Consideră o imagine mai clară.")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.top, 4)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $cameraViewModel.showCamera) {
            CameraView(
                capturedImage: $cameraViewModel.capturedImage,
                error: $cameraError
            )
        }
        .onChange(of: cameraError) { error in
            if let error = error {
                cameraViewModel.handleCameraError(error)
                cameraError = nil
            }
        }
        .alert("Eroare", isPresented: $cameraViewModel.showErrorAlert) {
            Button("OK") {
                cameraViewModel.clearError()
            }
        } message: {
            Text(cameraViewModel.errorMessage ?? "Eroare necunoscută")
        }
    }
}