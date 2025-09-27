import SwiftUI
import UIKit
import AVFoundation
import AIEngine

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var error: AIEngineError?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIViewController {
        // Check camera availability first
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            DispatchQueue.main.async {
                self.error = .cameraNotAvailable
                self.presentationMode.wrappedValue.dismiss()
            }
            return UIViewController() // Return empty controller
        }
        
        // Check camera permission
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch authStatus {
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.error = .cameraPermissionDenied
                self.presentationMode.wrappedValue.dismiss()
            }
            return UIViewController()
        case .notDetermined:
            // Request permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if !granted {
                        self.error = .cameraPermissionDenied
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        case .authorized:
            break
        @unknown default:
            break
        }
        
        let controller = UIImagePickerController()
        controller.delegate = context.coordinator
        controller.sourceType = .camera
        controller.cameraCaptureMode = .photo
        controller.cameraFlashMode = .auto
        controller.allowsEditing = false
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                // Validate image before setting
                if image.cgImage != nil {
                    parent.capturedImage = image
                    parent.error = nil // Clear any previous errors
                } else {
                    parent.error = .invalidImage
                }
            } else {
                parent.error = .invalidImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}