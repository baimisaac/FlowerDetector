import SwiftUI
import AVFoundation
import Vision

struct LiveDetectionView: UIViewControllerRepresentable {
    @Binding var detectionResult: String
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: LiveDetectionView

        init(_ parent: LiveDetectionView) {
            self.parent = parent
        }

        func didTapCloseButton() {
            parent.presentationMode.wrappedValue.dismiss()
        }

        func didDetectFlower(_ result: String) {
            parent.detectionResult = result
        }
    }
}

protocol CameraViewControllerDelegate: AnyObject {
    func didTapCloseButton()
    func didDetectFlower(_ result: String)
}

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    weak var delegate: CameraViewControllerDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Close", for: .normal)
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return button
    }()

    private lazy var resultLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }

        guard let camera = AVCaptureDevice.default(for: .video) else { return }
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }

            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            if captureSession.canAddOutput(output) {
                captureSession.addOutput(output)
            }

            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
            previewLayer?.frame = view.bounds
            if let previewLayer = previewLayer {
                view.layer.addSublayer(previewLayer)
            }

            captureSession.startRunning()
        } catch {
            print("Failed to set up camera: \(error)")
        }
    }

    private func setupUI() {
        view.addSubview(closeButton)
        view.addSubview(resultLabel)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        resultLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            resultLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    @objc private func closeTapped() {
        delegate?.didTapCloseButton()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNCoreMLRequest(model: try! VNCoreMLModel(for: FlowerDetect().model)) { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation] else { return }
            if let topResult = results.first {
                DispatchQueue.main.async {
                    let result = "Detected: \(topResult.identifier) (\(Int(topResult.confidence * 100))% confidence)"
                    self?.resultLabel.text = result
                    self?.delegate?.didDetectFlower(result)
                }
            }
        }

        try? VNImageRequestHandler(ciImage: CIImage(cvPixelBuffer: pixelBuffer)).perform([request])
    }
}

