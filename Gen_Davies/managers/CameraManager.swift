import AVFoundation
import UIKit
import Combine


class CameraManager: NSObject, ObservableObject, VideoFrameProvider, AVCaptureVideoDataOutputSampleBufferDelegate {
	@Published var currentFrame: CGImage?
	let session = AVCaptureSession()
	let pixelBufferPublisher = PassthroughSubject<CVPixelBuffer, Never>()
	
	override init() {
		super.init()
		setupCamera()
	}
	
	private func setupCamera() {
		session.sessionPreset = .high
		guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
			  let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
			print("❌ Failed to access the camera")
			return
		}
		if session.canAddInput(videoInput) {
			session.addInput(videoInput)
		}
		let videoOutput = AVCaptureVideoDataOutput()
		videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
		if session.canAddOutput(videoOutput) {
			session.addOutput(videoOutput)
		}
		if let connection = videoOutput.connection(with: .video) {
			if connection.isVideoOrientationSupported {
				connection.videoOrientation = .portrait // Adjust based on your needs
			}
		}
	}

	func startSession() {
		if !session.isRunning {
			DispatchQueue.global(qos: .background).async {
				self.session.startRunning()
				print("✅ Camera session started")
			}
		}
	}

	func stopSession() {
		if session.isRunning {
			session.stopRunning()
			print("🛑 Camera session stopped")
		}
	}

	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
			return
		}
		self.pixelBufferPublisher.send(pixelBuffer)
		DispatchQueue.global(qos: .userInitiated).async {
			guard let image = CameraManager.convert(pixelBuffer: pixelBuffer) else { return }

			DispatchQueue.main.async {
				self.currentFrame = image
			}
		}
	}
	
	private static func convert(pixelBuffer: CVPixelBuffer) -> CGImage? {
		let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
		let context = CIContext()
		return context.createCGImage(ciImage, from: ciImage.extent)
	}

	func startVideoProcessing() {
		startSession()
	}

	func stopVideoProcessing() {
		stopSession()
	}
}
