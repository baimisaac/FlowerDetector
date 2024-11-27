import SwiftUI
import Vision

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var detectionResult: String
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                detectFlower(image: uiImage)
            }

            parent.presentationMode.wrappedValue.dismiss()
        }

        func detectFlower(image: UIImage) {
            guard let ciImage = CIImage(image: image) else {
                parent.detectionResult = "Failed to create CIImage"
                return
            }

            let request = VNCoreMLRequest(model: try! VNCoreMLModel(for: FlowerDetect().model)) { [weak self] request, error in
                guard let results = request.results as? [VNClassificationObservation] else {
                    self?.parent.detectionResult = "Failed to process image"
                    return
                }

                if let topResult = results.first {
                    DispatchQueue.main.async {
                        self?.parent.detectionResult = "Detected: \(topResult.identifier) (\(Int(topResult.confidence * 100))% confidence)"
                    }
                }
            }

            let handler = VNImageRequestHandler(ciImage: ciImage)

            do {
                try handler.perform([request])
            } catch {
                parent.detectionResult = "Failed to perform detection: \(error.localizedDescription)"
            }
        }
    }
}

