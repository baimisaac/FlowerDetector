import SwiftUI

struct ContentView: View {
    @State private var image: UIImage?
    @State private var showingImagePicker = false
    @State private var showingLiveDetection = false
    @State private var detectionResult: String = ""

    var body: some View {
        NavigationView {
            VStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    Text("No image selected")
                }

                Button("Select Image") {
                    showingImagePicker = true
                }
                .padding()

                Button("Live Camera Detection") {
                    showingLiveDetection = true
                }
                .padding()

                Text(detectionResult)
                    .padding()
            }
            .navigationTitle("Flower Detector")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $image, detectionResult: $detectionResult)
            }
            .fullScreenCover(isPresented: $showingLiveDetection) {
                LiveDetectionView(detectionResult: $detectionResult)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

