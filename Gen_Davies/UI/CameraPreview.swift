import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
	let session: AVCaptureSession

	func makeUIView(context: Context) -> UIView {
		let view = UIView(frame: UIScreen.main.bounds)
		let previewLayer = AVCaptureVideoPreviewLayer(session: session)
		previewLayer.videoGravity = .resizeAspectFill // ✅ Adjust aspect ratio
		previewLayer.frame = view.bounds
		view.layer.addSublayer(previewLayer)
		return view
	}

	func updateUIView(_ uiView: UIView, context: Context) {
		DispatchQueue.main.async {
			if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
				previewLayer.session = session
				previewLayer.frame = uiView.bounds
				previewLayer.videoGravity = .resizeAspect
				if let connection = previewLayer.connection {
					connection.videoRotationAngle = UIDevice.current.userInterfaceIdiom == .pad ? 180 : .zero
					//connection.videoOrientation = UIDevice.current.userInterfaceIdiom == .pad ? .landscapeRight : .portrait
				}
			}
		}
	}
}
