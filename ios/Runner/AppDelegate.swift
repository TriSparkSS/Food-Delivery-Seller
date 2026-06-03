import UIKit
import Flutter

final class ProfileImagePicker: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate {
  private weak var controller: UIViewController?
  private var result: FlutterResult?
  private let maxImageDimension: CGFloat = 1600
  private let jpegQuality: CGFloat = 0.78

  init(controller: UIViewController?) {
    self.controller = controller
  }

  func pick(source: String, result: @escaping FlutterResult) {
    guard self.result == nil else {
      result(FlutterError(code: "picker_active", message: "Image picker is already open.", details: nil))
      return
    }

    guard let controller else {
      result(FlutterError(code: "controller_missing", message: "Unable to open image picker.", details: nil))
      return
    }

    if source == "file" {
      self.result = result
      let picker = UIDocumentPickerViewController(documentTypes: ["public.image"], in: .import)
      picker.delegate = self
      controller.present(picker, animated: true)
      return
    }

    let sourceType: UIImagePickerController.SourceType = source == "camera" ? .camera : .photoLibrary
    guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
      let message = source == "camera" ? "Camera is unavailable." : "Photo library is unavailable."
      result(FlutterError(code: "picker_unavailable", message: message, details: nil))
      return
    }

    self.result = result
    let picker = UIImagePickerController()
    picker.delegate = self
    picker.sourceType = sourceType
    picker.mediaTypes = ["public.image"]
    controller.present(picker, animated: true)
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
    result?(nil)
    result = nil
  }

  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
  ) {
    picker.dismiss(animated: true)

    if let url = info[.imageURL] as? URL {
      do {
        result?(try writeCompressedImage(from: url))
      } catch {
        result?(FlutterError(code: "compress_failed", message: error.localizedDescription, details: nil))
      }
      result = nil
      return
    }

    guard let image = info[.originalImage] as? UIImage else {
      result?(FlutterError(code: "image_missing", message: "Unable to read selected image.", details: nil))
      result = nil
      return
    }

    do {
      result?(try writeCompressedImage(image))
    } catch {
      result?(FlutterError(code: "compress_failed", message: error.localizedDescription, details: nil))
    }
    result = nil
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    result?(nil)
    result = nil
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let sourceUrl = urls.first else {
      result?(nil)
      result = nil
      return
    }

    let shouldStopAccessing = sourceUrl.startAccessingSecurityScopedResource()
    defer {
      if shouldStopAccessing {
        sourceUrl.stopAccessingSecurityScopedResource()
      }
    }

    do {
      result?(try writeCompressedImage(from: sourceUrl))
    } catch {
      result?(FlutterError(code: "compress_failed", message: error.localizedDescription, details: nil))
    }
    result = nil
  }

  private func writeCompressedImage(from url: URL) throws -> String {
    guard let image = UIImage(contentsOfFile: url.path) else {
      let destination = FileManager.default.temporaryDirectory
        .appendingPathComponent("picked_image_\(Int(Date().timeIntervalSince1970 * 1000)).jpg")
      if FileManager.default.fileExists(atPath: destination.path) {
        try FileManager.default.removeItem(at: destination)
      }
      try FileManager.default.copyItem(at: url, to: destination)
      return destination.path
    }

    return try writeCompressedImage(image)
  }

  private func writeCompressedImage(_ image: UIImage) throws -> String {
    let resizedImage = resized(image)
    guard let data = resizedImage.jpegData(compressionQuality: jpegQuality) else {
      throw NSError(
        domain: "qadam_food_seller",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Unable to compress selected image."]
      )
    }

    let destination = FileManager.default.temporaryDirectory
      .appendingPathComponent("picked_image_\(Int(Date().timeIntervalSince1970 * 1000)).jpg")
    try data.write(to: destination)
    return destination.path
  }

  private func resized(_ image: UIImage) -> UIImage {
    let size = image.size
    let largestSide = max(size.width, size.height)
    guard largestSide > maxImageDimension else { return image }

    let scale = maxImageDimension / largestSide
    let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    return renderer.image { _ in
      image.draw(in: CGRect(origin: .zero, size: targetSize))
    }
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var profileImagePicker: ProfileImagePicker?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let deviceChannel = FlutterMethodChannel(
        name: "qadam_food_seller/device",
        binaryMessenger: controller.binaryMessenger
      )

      deviceChannel.setMethodCallHandler { call, result in
        if call.method == "getDeviceIdentity" {
          result([
            "device_type": "iOS",
            "device_token": UIDevice.current.identifierForVendor?.uuidString ?? "unknown-ios-device"
          ])
        } else {
          result(FlutterMethodNotImplemented)
        }
      }

      let imagePicker = ProfileImagePicker(controller: controller)
      profileImagePicker = imagePicker
      let imageChannel = FlutterMethodChannel(
        name: "qadam_food_seller/profile_image",
        binaryMessenger: controller.binaryMessenger
      )

      imageChannel.setMethodCallHandler { call, result in
        if call.method == "pickProfileImage" {
          imagePicker.pick(source: "file", result: result)
        } else if call.method == "pickImage" {
          let arguments = call.arguments as? [String: Any]
          let source = arguments?["source"] as? String ?? "file"
          imagePicker.pick(source: source, result: result)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
